-- ============================================================================
-- Survey sections managed on the dashboard, and survey codes no longer typed
-- by staff.
--
-- * survey_categories: the sections the app groups survey links under
--   (Resources tab / Holistic Assessments). survey_links.category references
--   survey_categories(name): renaming a section renames it on every link
--   (ON UPDATE CASCADE); deleting one leaves its links without a section.
-- * survey_links.code is generated on insert and can no longer change.
-- * record_survey_completion_by_id(): every REDCap survey redirects to the same
--   https://io.happyhearts.app/survey-complete; the app records the survey it
--   opened. record_survey_completion(code) stays for older app builds.
-- ============================================================================

-- 1. Sections -----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.survey_categories (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL UNIQUE CHECK (char_length(name) BETWEEN 1 AND 60),
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order BETWEEN 0 AND 10000),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS survey_categories_name_ci
    ON public.survey_categories (lower(name));

CREATE OR REPLACE FUNCTION public.survey_categories_before_write()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_by := auth.uid();
        NEW.created_at := now();
        IF coalesce(NEW.sort_order, 0) = 0 THEN
            SELECT least(coalesce(max(c.sort_order), 0) + 1, 10000)
              INTO NEW.sort_order
              FROM public.survey_categories c;
        END IF;
    ELSE
        NEW.created_by := OLD.created_by;
        NEW.created_at := OLD.created_at;
    END IF;
    NEW.name := regexp_replace(btrim(coalesce(NEW.name, '')), '\s+', ' ', 'g');
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_survey_categories_before_write ON public.survey_categories;
CREATE TRIGGER trg_survey_categories_before_write
    BEFORE INSERT OR UPDATE ON public.survey_categories
    FOR EACH ROW EXECUTE FUNCTION public.survey_categories_before_write();

ALTER TABLE public.survey_categories ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.survey_categories FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.survey_categories TO authenticated;

DROP POLICY IF EXISTS survey_categories_select ON public.survey_categories;
CREATE POLICY survey_categories_select ON public.survey_categories
    FOR SELECT TO authenticated
    USING (public.is_active_staff() OR public.is_active_patient());
DROP POLICY IF EXISTS survey_categories_insert_staff ON public.survey_categories;
CREATE POLICY survey_categories_insert_staff ON public.survey_categories
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS survey_categories_update_staff ON public.survey_categories;
CREATE POLICY survey_categories_update_staff ON public.survey_categories
    FOR UPDATE TO authenticated
    USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
DROP POLICY IF EXISTS survey_categories_delete_staff ON public.survey_categories;
CREATE POLICY survey_categories_delete_staff ON public.survey_categories
    FOR DELETE TO authenticated USING (public.is_active_staff());

-- Sets the order of all sections in one statement (ids in display order).
CREATE OR REPLACE FUNCTION public.reorder_survey_categories(p_ids UUID[])
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'only staff can reorder sections' USING ERRCODE = '42501';
    END IF;
    UPDATE public.survey_categories c
       SET sort_order = x.ord::int
      FROM unnest(p_ids) WITH ORDINALITY AS x(id, ord)
     WHERE c.id = x.id
       AND c.sort_order IS DISTINCT FROM x.ord::int;
END;
$$;
REVOKE ALL ON FUNCTION public.reorder_survey_categories(UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reorder_survey_categories(UUID[]) TO authenticated;

-- Seed: the two sections from the app design, then any other value in use.
UPDATE public.survey_links
   SET category = NULLIF(btrim(category), '')
 WHERE category IS DISTINCT FROM NULLIF(btrim(category), '');

INSERT INTO public.survey_categories (name, sort_order) VALUES
    ('Emotional Assessment', 1),
    ('Basic Needs Assessment', 2)
ON CONFLICT DO NOTHING;

INSERT INTO public.survey_categories (name, sort_order)
SELECT DISTINCT l.category, 100
  FROM public.survey_links l
 WHERE l.category IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM public.survey_categories c WHERE c.name = l.category)
ON CONFLICT DO NOTHING;

-- 2. survey_links: section reference, generated code ---------------------------
CREATE INDEX IF NOT EXISTS idx_survey_links_category ON public.survey_links (category);

ALTER TABLE public.survey_links DROP CONSTRAINT IF EXISTS survey_links_category_fkey;
ALTER TABLE public.survey_links
    ADD CONSTRAINT survey_links_category_fkey
    FOREIGN KEY (category) REFERENCES public.survey_categories(name)
    ON UPDATE CASCADE ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.survey_links_before_write()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_by := auth.uid();
        NEW.created_at := now();
        IF NEW.code IS NULL OR btrim(NEW.code) = '' THEN
            NEW.code := 'S_' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
        END IF;
    ELSE
        IF NEW.created_at IS DISTINCT FROM OLD.created_at
           OR NEW.created_by IS DISTINCT FROM OLD.created_by THEN
            RAISE EXCEPTION 'creation fields cannot be changed';
        END IF;
        IF upper(btrim(NEW.code)) IS DISTINCT FROM OLD.code THEN
            RAISE EXCEPTION 'survey codes cannot be changed';
        END IF;
    END IF;
    NEW.title := btrim(NEW.title);
    NEW.code := upper(btrim(NEW.code));
    NEW.url := btrim(NEW.url);
    NEW.category := NULLIF(btrim(NEW.category), '');
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- 3. Completion by survey id ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_survey_completion_by_id(p_survey_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid    UUID := auth.uid();
    v_survey public.survey_links;
    v_id     UUID;
BEGIN
    IF v_uid IS NULL OR NOT public.is_active_patient() THEN
        RAISE EXCEPTION 'only active patients can record survey completions' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_survey FROM public.survey_links s WHERE s.id = p_survey_id;
    IF v_survey.id IS NULL THEN
        RAISE EXCEPTION 'unknown survey' USING ERRCODE = 'P0002';
    END IF;

    -- One completion per patient and survey at a time (double taps, reloads).
    PERFORM pg_advisory_xact_lock(hashtextextended(v_uid::text || ':' || v_survey.id::text, 0));

    -- A reload of the thank-you redirect must not count twice.
    SELECT c.id INTO v_id FROM public.survey_completions c
    WHERE c.user_id = v_uid AND c.survey_id = v_survey.id
      AND c.completed_at > now() - interval '10 minutes'
    ORDER BY c.completed_at DESC LIMIT 1;
    IF v_id IS NOT NULL THEN
        RETURN v_id;
    END IF;

    INSERT INTO public.survey_completions (user_id, survey_id, survey_code)
    VALUES (v_uid, v_survey.id, v_survey.code)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.record_survey_completion_by_id(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_survey_completion_by_id(UUID) TO authenticated;
