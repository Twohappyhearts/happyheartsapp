-- Dashboard core tables: content, survey links, assistance requests (alerts),
-- tracking events, profiles.display_id.
-- Idempotent and additive. Role model unchanged: DB role 'staff' is shown as
-- "Careteam" in the dashboard UI; staff/admin are checked with is_active_staff().

-- ============================================================================
-- 0. profiles.display_id ("friendly name for display", Users page)
-- ============================================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_id TEXT;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_display_id_length_check') THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_display_id_length_check
            CHECK (display_id IS NULL OR char_length(display_id) <= 50);
    END IF;
END $$;
-- Not client-editable: staff edit it through the dashboard's server route.

-- ============================================================================
-- 1. content_items: educational sessions + community resources
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind TEXT NOT NULL CHECK (kind IN ('session', 'resource')),
    title TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
    description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 2000),
    -- Media is added by link only. Domain checks (YouTube / SoundCloud /
    -- Cloudinary) live in the dashboard form so teams can relax them later;
    -- the database only guarantees https links (no javascript:/data: URLs).
    video_url TEXT CHECK (video_url IS NULL OR video_url ~* '^https://'),
    audio_url TEXT CHECK (audio_url IS NULL OR audio_url ~* '^https://'),
    thumbnail_url TEXT CHECK (thumbnail_url IS NULL OR thumbnail_url ~* '^https://'),
    infographic_url TEXT CHECK (infographic_url IS NULL OR infographic_url ~* '^https://'),
    quiz_url TEXT CHECK (quiz_url IS NULL OR quiz_url ~* '^https://'),
    -- Rich text (HTML) from the dashboard editor. Sanitize when rendering.
    script_html TEXT NOT NULL DEFAULT '' CHECK (char_length(script_html) <= 200000),
    video_duration TEXT CHECK (video_duration IS NULL OR video_duration ~ '^[0-9]{1,3}:[0-5][0-9]$'),
    audio_duration TEXT CHECK (audio_duration IS NULL OR audio_duration ~ '^[0-9]{1,3}:[0-5][0-9]$'),
    -- Auto-generated, immutable: session1, session2, ... / resource1, ...
    group_id TEXT NOT NULL UNIQUE,
    group_number INT NOT NULL,
    group_name TEXT NOT NULL DEFAULT '' CHECK (char_length(group_name) <= 100),
    tags TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_content_items_kind_order
    ON public.content_items (kind, group_number);
CREATE INDEX IF NOT EXISTS idx_content_items_active
    ON public.content_items (kind, is_active);

CREATE OR REPLACE FUNCTION public.content_items_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_prefix TEXT;
    v_next INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_prefix := CASE NEW.kind WHEN 'session' THEN 'session' ELSE 'resource' END;
        -- Serialize numbering per kind so concurrent inserts never collide.
        PERFORM pg_advisory_xact_lock(hashtext('content_items_group:' || NEW.kind));
        SELECT coalesce(max(group_number), 0) + 1 INTO v_next
        FROM public.content_items WHERE kind = NEW.kind;

        NEW.group_number := v_next;
        NEW.group_id := v_prefix || v_next;
        IF btrim(coalesce(NEW.group_name, '')) = '' THEN
            NEW.group_name := CASE NEW.kind
                WHEN 'session' THEN 'Session ' || v_next
                ELSE 'Community Resources' END;
        END IF;
        NEW.created_by := auth.uid();
        NEW.updated_by := auth.uid();
        NEW.created_at := now();
        NEW.updated_at := now();
    ELSE
        IF NEW.kind IS DISTINCT FROM OLD.kind
           OR NEW.group_id IS DISTINCT FROM OLD.group_id
           OR NEW.group_number IS DISTINCT FROM OLD.group_number
           OR NEW.created_at IS DISTINCT FROM OLD.created_at
           OR NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'kind, group_id and creation fields cannot be changed';
        END IF;
        NEW.updated_by := auth.uid();
        NEW.updated_at := now();
    END IF;
    NEW.title := btrim(NEW.title);
    NEW.tags := coalesce(
        (SELECT array_agg(DISTINCT t) FROM (
            SELECT lower(btrim(x)) AS t FROM unnest(NEW.tags) x WHERE btrim(x) <> ''
        ) s),
        '{}'
    );
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.content_items_before_write() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_content_items_before_write ON public.content_items;
CREATE TRIGGER trg_content_items_before_write
    BEFORE INSERT OR UPDATE ON public.content_items
    FOR EACH ROW EXECUTE FUNCTION public.content_items_before_write();

ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.content_items FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.content_items TO authenticated;

DROP POLICY IF EXISTS "content_select_staff" ON public.content_items;
CREATE POLICY "content_select_staff" ON public.content_items
    FOR SELECT TO authenticated USING (public.is_active_staff());
DROP POLICY IF EXISTS "content_select_active_patient" ON public.content_items;
CREATE POLICY "content_select_active_patient" ON public.content_items
    FOR SELECT TO authenticated USING (is_active AND public.is_active_patient());
DROP POLICY IF EXISTS "content_insert_staff" ON public.content_items;
CREATE POLICY "content_insert_staff" ON public.content_items
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS "content_update_staff" ON public.content_items;
CREATE POLICY "content_update_staff" ON public.content_items
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS "content_delete_staff" ON public.content_items;
CREATE POLICY "content_delete_staff" ON public.content_items
    FOR DELETE TO authenticated USING (public.is_active_staff());

-- ============================================================================
-- 2. survey_links: REDCap public survey links
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.survey_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
    code TEXT NOT NULL UNIQUE CHECK (code ~ '^[A-Z][A-Z0-9_]{0,49}$'),
    url TEXT NOT NULL CHECK (url ~* '^https://'),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.survey_links_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_by := auth.uid();
        NEW.created_at := now();
    ELSIF NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.created_by IS DISTINCT FROM OLD.created_by THEN
        RAISE EXCEPTION 'creation fields cannot be changed';
    END IF;
    NEW.title := btrim(NEW.title);
    NEW.code := upper(btrim(NEW.code));
    NEW.url := btrim(NEW.url);
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.survey_links_before_write() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_survey_links_before_write ON public.survey_links;
CREATE TRIGGER trg_survey_links_before_write
    BEFORE INSERT OR UPDATE ON public.survey_links
    FOR EACH ROW EXECUTE FUNCTION public.survey_links_before_write();

ALTER TABLE public.survey_links ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.survey_links FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.survey_links TO authenticated;

DROP POLICY IF EXISTS "survey_select_staff" ON public.survey_links;
CREATE POLICY "survey_select_staff" ON public.survey_links
    FOR SELECT TO authenticated USING (public.is_active_staff());
DROP POLICY IF EXISTS "survey_select_active_patient" ON public.survey_links;
CREATE POLICY "survey_select_active_patient" ON public.survey_links
    FOR SELECT TO authenticated USING (is_active AND public.is_active_patient());
DROP POLICY IF EXISTS "survey_insert_staff" ON public.survey_links;
CREATE POLICY "survey_insert_staff" ON public.survey_links
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS "survey_update_staff" ON public.survey_links;
CREATE POLICY "survey_update_staff" ON public.survey_links
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS "survey_delete_staff" ON public.survey_links;
CREATE POLICY "survey_delete_staff" ON public.survey_links
    FOR DELETE TO authenticated USING (public.is_active_staff());

-- ============================================================================
-- 3. assistance_requests: "I need assistance" -> dashboard Alerts
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.assistance_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL CHECK (char_length(btrim(message)) BETWEEN 1 AND 2000),
    status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'ACK', 'RESOLVED')),
    notes TEXT NOT NULL DEFAULT '' CHECK (char_length(notes) <= 5000),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assistance_status_created
    ON public.assistance_requests (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_assistance_patient
    ON public.assistance_requests (patient_id, created_at DESC);

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
        NEW.notes := '';
        NEW.acknowledged_at := NULL; NEW.acknowledged_by := NULL;
        NEW.resolved_at := NULL;     NEW.resolved_by := NULL;
        NEW.created_at := now();
        NEW.updated_at := now();
        RETURN NEW;
    END IF;

    -- UPDATE (staff): only status/notes are granted; record who/when.
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
REVOKE ALL ON FUNCTION public.assistance_requests_before_write() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_assistance_requests_before_write ON public.assistance_requests;
CREATE TRIGGER trg_assistance_requests_before_write
    BEFORE INSERT OR UPDATE ON public.assistance_requests
    FOR EACH ROW EXECUTE FUNCTION public.assistance_requests_before_write();

ALTER TABLE public.assistance_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.assistance_requests FROM anon, authenticated;
GRANT SELECT ON public.assistance_requests TO authenticated;
GRANT INSERT (id, message) ON public.assistance_requests TO authenticated;
GRANT UPDATE (status, notes) ON public.assistance_requests TO authenticated;
-- No DELETE: requests are part of the care record.

DROP POLICY IF EXISTS "assistance_select_own_patient" ON public.assistance_requests;
CREATE POLICY "assistance_select_own_patient" ON public.assistance_requests
    FOR SELECT TO authenticated USING (patient_id = auth.uid() AND public.is_active_patient());
DROP POLICY IF EXISTS "assistance_select_staff" ON public.assistance_requests;
CREATE POLICY "assistance_select_staff" ON public.assistance_requests
    FOR SELECT TO authenticated USING (public.is_active_staff());
DROP POLICY IF EXISTS "assistance_insert_patient" ON public.assistance_requests;
CREATE POLICY "assistance_insert_patient" ON public.assistance_requests
    FOR INSERT TO authenticated WITH CHECK (patient_id = auth.uid() AND public.is_active_patient());
DROP POLICY IF EXISTS "assistance_update_staff" ON public.assistance_requests;
CREATE POLICY "assistance_update_staff" ON public.assistance_requests
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());

-- ============================================================================
-- 4. tracking_events: mobile app engagement -> Analytics / Recent Activity
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tracking_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content_id UUID REFERENCES public.content_items(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'session_opened',     -- value = seconds spent on the session page
        'video_play',         -- value = NULL (timestamp is occurred_at)
        'audio_play',         -- value = NULL
        'infographic_opened', -- value = seconds the full-screen image stayed open
        'script_read',        -- value = seconds spent reading
        'quiz_completed',     -- value = 1 (finished) or 0
        'session_completed'   -- value = NULL (Completed button tapped)
    )),
    value NUMERIC CHECK (value IS NULL OR (value >= 0 AND value <= 86400)),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (pg_column_size(metadata) <= 4096),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tracking_content_type
    ON public.tracking_events (content_id, event_type);
CREATE INDEX IF NOT EXISTS idx_tracking_user_time
    ON public.tracking_events (user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_tracking_time
    ON public.tracking_events (occurred_at DESC);

CREATE OR REPLACE FUNCTION public.tracking_events_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NOT NULL THEN
        NEW.user_id := auth.uid();
    END IF;
    -- Allow offline batching, but never trust absurd client clocks.
    IF NEW.occurred_at IS NULL
       OR NEW.occurred_at > now() + interval '5 minutes'
       OR NEW.occurred_at < now() - interval '30 days' THEN
        NEW.occurred_at := now();
    END IF;
    NEW.created_at := now();
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.tracking_events_before_insert() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_tracking_events_before_insert ON public.tracking_events;
CREATE TRIGGER trg_tracking_events_before_insert
    BEFORE INSERT ON public.tracking_events
    FOR EACH ROW EXECUTE FUNCTION public.tracking_events_before_insert();

ALTER TABLE public.tracking_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.tracking_events FROM anon, authenticated;
GRANT SELECT ON public.tracking_events TO authenticated;
GRANT INSERT (id, content_id, event_type, value, metadata, occurred_at) ON public.tracking_events TO authenticated;
-- Append-only: no UPDATE / DELETE for clients.

DROP POLICY IF EXISTS "tracking_select_own_patient" ON public.tracking_events;
CREATE POLICY "tracking_select_own_patient" ON public.tracking_events
    FOR SELECT TO authenticated USING (user_id = auth.uid() AND public.is_active_patient());
DROP POLICY IF EXISTS "tracking_select_staff" ON public.tracking_events;
CREATE POLICY "tracking_select_staff" ON public.tracking_events
    FOR SELECT TO authenticated USING (public.is_active_staff());
DROP POLICY IF EXISTS "tracking_insert_patient" ON public.tracking_events;
CREATE POLICY "tracking_insert_patient" ON public.tracking_events
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND public.is_active_patient());

-- ============================================================================
-- 5. Shared updated_at upkeep where not handled above
-- ============================================================================
-- (content_items / survey_links / assistance_requests set updated_at in their
--  own triggers.)

-- ============================================================================
-- 6. Realtime: live alert badge + Alerts page
-- ============================================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
       AND NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
              AND tablename = 'assistance_requests') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.assistance_requests;
    END IF;
END $$;

-- ============================================================================
-- 7. Seed data from the build prompts (only if missing)
-- ============================================================================
INSERT INTO public.survey_links (title, code, url, is_active) VALUES
    ('Intake Survey',    'INTAKE',   'https://ci-redcap.hs.uci.edu/surveys/?s=3JAA7JRPHFEC4WY3', true),
    ('Follow-Up Survey', 'FOLLOWUP', 'https://ci-redcap.hs.uci.edu/surveys/?s=RC4XD9NPP9J7XKFL', true)
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.content_items (kind, title, description, is_active, group_name)
SELECT 'resource', v.title, v.description, true, 'Community Resources'
FROM (VALUES
    (1, '211 Community Resources',        'Dial 211 or visit 211.org for local community resources'),
    (2, 'California Food Bank Directory', 'Find your local food bank'),
    (3, 'Crisis Text Line',               'Text HOME to 741741 for free, 24/7 crisis support'),
    (4, 'National Hunger Hotline',        'Call 1-866-3-HUNGRY (1-866-348-6479) for food assistance'),
    (5, 'SAMHSA National Helpline',       'Mental health and substance abuse support: 1-800-662-HELP (4357)')
) AS v(ord, title, description)
WHERE NOT EXISTS (
    SELECT 1 FROM public.content_items c WHERE c.kind = 'resource' AND c.title = v.title
)
ORDER BY v.ord;

NOTIFY pgrst, 'reload schema';
