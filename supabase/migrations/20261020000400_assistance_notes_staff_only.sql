-- Staff notes on assistance requests are internal. They lived in
-- assistance_requests.notes, which patients can SELECT for their own rows.
-- Column privileges can't separate patients from staff (both are the
-- `authenticated` role), so notes move to a staff-only table.
-- assistance_requests had 0 rows when this was written; any notes are copied.

-- 1. Staff-only notes table ---------------------------------------------------
CREATE TABLE IF NOT EXISTS public.assistance_request_notes (
    request_id UUID PRIMARY KEY REFERENCES public.assistance_requests(id) ON DELETE CASCADE,
    notes TEXT NOT NULL DEFAULT '' CHECK (char_length(notes) <= 5000),
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.assistance_request_notes_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.request_id IS DISTINCT FROM OLD.request_id THEN
        RAISE EXCEPTION 'request_id cannot be changed';
    END IF;
    NEW.updated_by := auth.uid();
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.assistance_request_notes_before_write() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_assistance_request_notes_before_write ON public.assistance_request_notes;
CREATE TRIGGER trg_assistance_request_notes_before_write
    BEFORE INSERT OR UPDATE ON public.assistance_request_notes
    FOR EACH ROW EXECUTE FUNCTION public.assistance_request_notes_before_write();

ALTER TABLE public.assistance_request_notes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.assistance_request_notes FROM anon, authenticated;
GRANT SELECT ON public.assistance_request_notes TO authenticated;
GRANT INSERT (request_id, notes) ON public.assistance_request_notes TO authenticated;
GRANT UPDATE (notes) ON public.assistance_request_notes TO authenticated;

DROP POLICY IF EXISTS "assistance_notes_select_staff" ON public.assistance_request_notes;
CREATE POLICY "assistance_notes_select_staff" ON public.assistance_request_notes
    FOR SELECT TO authenticated USING (public.is_active_staff());
DROP POLICY IF EXISTS "assistance_notes_insert_staff" ON public.assistance_request_notes;
CREATE POLICY "assistance_notes_insert_staff" ON public.assistance_request_notes
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS "assistance_notes_update_staff" ON public.assistance_request_notes;
CREATE POLICY "assistance_notes_update_staff" ON public.assistance_request_notes
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());

-- 2. Copy any existing notes, then remove the patient-readable column ---------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 'assistance_requests'
                 AND column_name = 'notes') THEN
        INSERT INTO public.assistance_request_notes (request_id, notes)
        SELECT id, notes FROM public.assistance_requests WHERE notes <> ''
        ON CONFLICT (request_id) DO NOTHING;
    END IF;
END $$;

-- The write trigger referenced NEW.notes: replace it before dropping the column.
CREATE OR REPLACE FUNCTION public.assistance_requests_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF v_uid IS NOT NULL THEN
            -- Client insert: identity, status and timestamps are server-assigned.
            NEW.patient_id := v_uid;
        END IF;
        NEW.message := btrim(NEW.message);
        NEW.status := 'NEW';
        NEW.acknowledged_at := NULL; NEW.acknowledged_by := NULL;
        NEW.resolved_at := NULL;     NEW.resolved_by := NULL;
        NEW.created_at := now();
        NEW.updated_at := now();
        RETURN NEW;
    END IF;

    -- UPDATE (staff): only status is granted; record who/when.
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        IF NEW.status = 'NEW' THEN
            NEW.acknowledged_at := NULL; NEW.acknowledged_by := NULL;
            NEW.resolved_at := NULL;     NEW.resolved_by := NULL;
        ELSIF NEW.status = 'ACK' THEN
            NEW.acknowledged_at := coalesce(OLD.acknowledged_at, now());
            NEW.acknowledged_by := coalesce(OLD.acknowledged_by, v_uid);
            NEW.resolved_at := NULL; NEW.resolved_by := NULL;
        ELSIF NEW.status = 'RESOLVED' THEN
            NEW.resolved_at := now();
            NEW.resolved_by := v_uid;
        END IF;
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

REVOKE UPDATE ON public.assistance_requests FROM authenticated;
GRANT UPDATE (status) ON public.assistance_requests TO authenticated;
ALTER TABLE public.assistance_requests DROP COLUMN IF EXISTS notes;

-- 3. Light abuse guard: at most 20 requests per patient per hour --------------
CREATE OR REPLACE FUNCTION public.assistance_requests_rate_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NOT NULL AND (
        SELECT count(*) FROM public.assistance_requests
        WHERE patient_id = NEW.patient_id
          AND created_at > now() - interval '1 hour'
    ) >= 20 THEN
        RAISE EXCEPTION 'too many requests, please wait a little'
            USING ERRCODE = 'P0001', HINT = 'rate_limited';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.assistance_requests_rate_limit() FROM PUBLIC, anon, authenticated;

-- Runs after the before_write trigger (alphabetical order), so patient_id is set.
DROP TRIGGER IF EXISTS trg_assistance_requests_rate_limit ON public.assistance_requests;
CREATE TRIGGER trg_assistance_requests_rate_limit
    BEFORE INSERT ON public.assistance_requests
    FOR EACH ROW EXECUTE FUNCTION public.assistance_requests_rate_limit();

NOTIFY pgrst, 'reload schema';
