-- ============================================================================
-- Surveys (dashboard Prompt 5 + app Prompt 9 / Assessments tab)
--
-- * survey_links gains the display fields the app's Assessments cards use:
--   description, category (section), frequency, duration, sort_order.
-- * survey_completions: when a REDCap survey ends, REDCap redirects to
--   https://io.happyhearts.app/survey-complete?code=<CODE>; the app intercepts
--   that URL and records a completion with record_survey_completion(). Only
--   the fact + time are stored here — the answers stay in REDCap.
-- ============================================================================

ALTER TABLE public.survey_links
    ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT ''
        CHECK (char_length(description) <= 1000),
    ADD COLUMN IF NOT EXISTS category TEXT
        CHECK (category IS NULL OR char_length(category) BETWEEN 1 AND 60),
    ADD COLUMN IF NOT EXISTS frequency TEXT
        CHECK (frequency IS NULL OR char_length(frequency) BETWEEN 1 AND 40),
    ADD COLUMN IF NOT EXISTS duration TEXT
        CHECK (duration IS NULL OR char_length(duration) BETWEEN 1 AND 40),
    ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0
        CHECK (sort_order BETWEEN 0 AND 10000);

UPDATE public.survey_links SET sort_order = 1 WHERE code = 'INTAKE' AND sort_order = 0;
UPDATE public.survey_links SET sort_order = 2 WHERE code = 'FOLLOWUP' AND sort_order = 0;

-- Completions ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.survey_completions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    survey_id    UUID REFERENCES public.survey_links(id) ON DELETE SET NULL,
    survey_code  TEXT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_survey_completions_user
    ON public.survey_completions (user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_survey_completions_survey
    ON public.survey_completions (survey_id, completed_at DESC);

ALTER TABLE public.survey_completions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.survey_completions FROM anon, authenticated;
GRANT SELECT ON public.survey_completions TO authenticated;

CREATE POLICY "survey_completions_select_own" ON public.survey_completions
    FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "survey_completions_select_staff" ON public.survey_completions
    FOR SELECT TO authenticated USING (public.is_active_staff());

-- Writes only through this function (no direct INSERT grant).
CREATE OR REPLACE FUNCTION public.record_survey_completion(p_code TEXT)
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

    SELECT * INTO v_survey FROM public.survey_links s
    WHERE s.code = upper(btrim(coalesce(p_code, '')));
    IF v_survey.id IS NULL THEN
        RAISE EXCEPTION 'unknown survey code' USING ERRCODE = 'P0002';
    END IF;

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
REVOKE ALL ON FUNCTION public.record_survey_completion(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_survey_completion(TEXT) TO authenticated;
