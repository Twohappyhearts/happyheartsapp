-- Where a REDCap link appears in the app:
--   'resource' → the Resources tab (bottom navigation; formerly "Assessments")
--   'survey'   → Survey, in the side menu
-- Existing links stay where they were (the Resources tab).
ALTER TABLE public.survey_links
    ADD COLUMN IF NOT EXISTS placement TEXT NOT NULL DEFAULT 'resource';

ALTER TABLE public.survey_links
    DROP CONSTRAINT IF EXISTS survey_links_placement_check;
ALTER TABLE public.survey_links
    ADD CONSTRAINT survey_links_placement_check CHECK (placement IN ('resource', 'survey'));

COMMENT ON COLUMN public.survey_links.placement IS
    'Where the app lists this link: resource = Resources tab, survey = Survey (side menu)';

CREATE INDEX IF NOT EXISTS idx_survey_links_placement
    ON public.survey_links (placement, sort_order);
