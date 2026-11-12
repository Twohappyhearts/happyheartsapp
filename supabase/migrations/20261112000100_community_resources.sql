-- Community resource directory (2026-11-12).
--
-- Staff keep a directory of local and national programs (food, diapers, mental health, …) on the
-- dashboard's Content > Community Resources tab. The dashboard server reads each resource's
-- website, has the AI write a short summary of it, and publishes the whole directory as one
-- generated knowledge-base document, so the AI assistant can answer questions about local services.
--
-- Additive only: the old rows of content_items with kind = 'resource' stay where they are (the
-- dashboard no longer lists them). Run this before deploying the dashboard code that uses it.

-- 1. The directory ------------------------------------------------------------------------------

CREATE TABLE public.community_resources (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Filled in by staff. Required: name and category.
    name              text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 200),
    category          text NOT NULL CHECK (category IN (
                          'emergency_211', 'food_diapers', 'mental_health', 'pregnancy_postpartum',
                          'parenting', 'child_health', 'breastfeeding', 'domestic_violence', 'housing',
                          'financial', 'technology', 'wellness', 'doula', 'childbirth_classes',
                          'child_care', 'other')),
    description       text CHECK (description IS NULL OR char_length(description) <= 2000),
    phone             text CHECK (phone IS NULL OR char_length(phone) <= 300),
    text_number       text CHECK (text_number IS NULL OR char_length(text_number) <= 300),
    website           text CHECK (website IS NULL OR (char_length(website) <= 2000
                                                      AND website ~* '^https?://[^[:space:]/?#]+[^[:space:]]*$')),
    address           text CHECK (address IS NULL OR char_length(address) <= 1000),
    -- Free text, e.g. "Orange County", "Los Angeles County", "California", "National".
    area_served       text CHECK (area_served IS NULL OR char_length(area_served) <= 300),
    -- NULL = not known.
    is_free           boolean,
    -- Free text, e.g. whether a referral is needed or it is income-based.
    eligibility       text CHECK (eligibility IS NULL OR char_length(eligibility) <= 2000),
    last_verified_on  date,
    is_active         boolean NOT NULL DEFAULT true,
    -- Where the entry came from, e.g. "Healthy Sleep community resources list (Sept 2024)".
    source            text CHECK (source IS NULL OR char_length(source) <= 200),

    -- Written by the dashboard server ("Update from websites"), never by staff directly.
    ai_summary        text CHECK (ai_summary IS NULL OR char_length(ai_summary) <= 2000),
    ai_fetched_at     timestamptz,
    ai_status         text NOT NULL DEFAULT 'pending'
                      CHECK (ai_status IN ('ok', 'failed', 'no_website', 'pending')),
    ai_error          text CHECK (ai_error IS NULL OR char_length(ai_error) <= 1000),
    -- The website value the summary was written from (a different website = needs a new summary).
    ai_source_url     text CHECK (ai_source_url IS NULL OR char_length(ai_source_url) <= 2000),
    -- Model and token use of the last summary:
    -- {runId, model, inputTokens, cachedInputTokens, outputTokens, reasoningTokens, toolCalls, at}.
    ai_usage          jsonb,

    created_by        uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
    updated_by        uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.community_resources IS
    'Community resource directory (dashboard: Content > Community Resources). Staff-managed; the ai_* columns are written by the dashboard server. Published to the AI knowledge base as one generated document (knowledge_documents.source_type = ''resources'').';

-- Same name twice in one category is a duplicate (the import script matches on this too).
CREATE UNIQUE INDEX community_resources_category_name_key
    ON public.community_resources (category, lower(btrim(name)));

-- Touch trigger. Unlike touch_updated_at(), updated_at / updated_by change only when a staff field
-- changes (the server writing an AI summary is not an edit). A new or changed website drops the
-- summary written from the old one.
CREATE FUNCTION public.community_resources_before_write() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
    not_staff_fields constant text[] := ARRAY[
        'ai_summary', 'ai_fetched_at', 'ai_status', 'ai_error', 'ai_source_url', 'ai_usage',
        'created_by', 'created_at', 'updated_by', 'updated_at'];
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.website IS NULL THEN
            NEW.ai_status := 'no_website';
        ELSIF NEW.ai_status = 'no_website' THEN
            NEW.ai_status := 'pending';
        END IF;
        RETURN NEW;
    END IF;

    IF NEW.website IS DISTINCT FROM OLD.website THEN
        NEW.ai_summary := NULL;
        NEW.ai_error := NULL;
        NEW.ai_status := CASE WHEN NEW.website IS NULL THEN 'no_website' ELSE 'pending' END;
    END IF;

    IF (to_jsonb(NEW) - not_staff_fields) IS DISTINCT FROM (to_jsonb(OLD) - not_staff_fields) THEN
        NEW.updated_at := now();
        NEW.updated_by := coalesce(auth.uid(), NEW.updated_by);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_community_resources_before_write
    BEFORE INSERT OR UPDATE ON public.community_resources
    FOR EACH ROW EXECUTE FUNCTION public.community_resources_before_write();

-- Active staff read and write (same rules as agent_web_domains). Staff may write only their own
-- fields; the ai_* columns and the system columns are left to the server (service role) and the trigger.
ALTER TABLE public.community_resources ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.community_resources FROM anon, authenticated;
GRANT SELECT, DELETE ON public.community_resources TO authenticated;
GRANT INSERT (name, category, description, phone, text_number, website, address, area_served,
              is_free, eligibility, last_verified_on, is_active, source)
    ON public.community_resources TO authenticated;
GRANT UPDATE (name, category, description, phone, text_number, website, address, area_served,
              is_free, eligibility, last_verified_on, is_active, source)
    ON public.community_resources TO authenticated;

CREATE POLICY community_resources_select_staff ON public.community_resources
    FOR SELECT TO authenticated USING (public.is_active_staff());
CREATE POLICY community_resources_insert_staff ON public.community_resources
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
CREATE POLICY community_resources_update_staff ON public.community_resources
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
CREATE POLICY community_resources_delete_staff ON public.community_resources
    FOR DELETE TO authenticated USING (public.is_active_staff());

-- 2. Background runs ("Update from websites", "Publish to knowledge base") -----------------------
-- One row per run, written by the dashboard server; the page polls it for progress. usage holds
-- the run's token totals: {inputTokens, cachedInputTokens, outputTokens, reasoningTokens,
-- toolCalls, modelCalls, models: {model id: calls}}.

CREATE TABLE public.community_resource_runs (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kind          text NOT NULL CHECK (kind IN ('fetch', 'publish')),
    status        text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'done', 'failed')),
    total         integer NOT NULL DEFAULT 0 CHECK (total >= 0),
    processed     integer NOT NULL DEFAULT 0 CHECK (processed >= 0),
    ok_count      integer NOT NULL DEFAULT 0 CHECK (ok_count >= 0),
    failed_count  integer NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
    usage         jsonb NOT NULL DEFAULT '{}'::jsonb,
    result        jsonb NOT NULL DEFAULT '{}'::jsonb,
    error         text CHECK (error IS NULL OR char_length(error) <= 1000),
    started_by    uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    started_at    timestamptz NOT NULL DEFAULT now(),
    -- Updated while the run works; a running row with an old heartbeat is a run that died.
    heartbeat_at  timestamptz NOT NULL DEFAULT now(),
    finished_at   timestamptz
);
COMMENT ON TABLE public.community_resource_runs IS
    'Runs of the community resource jobs (website summaries, publishing). Written only by the dashboard server.';

-- At most one run at a time (fetch or publish).
CREATE UNIQUE INDEX community_resource_runs_one_running
    ON public.community_resource_runs (status) WHERE status = 'running';
CREATE INDEX community_resource_runs_started ON public.community_resource_runs (kind, started_at DESC);

ALTER TABLE public.community_resource_runs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.community_resource_runs FROM anon, authenticated;
GRANT SELECT ON public.community_resource_runs TO authenticated;

CREATE POLICY community_resource_runs_select_staff ON public.community_resource_runs
    FOR SELECT TO authenticated USING (public.is_active_staff());

-- 3. Knowledge base -----------------------------------------------------------------------------
-- The generated directory document is marked source_type = 'resources' (the AI's search takes up
-- to 8 passages from it instead of 2) and lives in its own knowledge base.

ALTER TABLE public.knowledge_documents DROP CONSTRAINT IF EXISTS knowledge_documents_source_type_check;
ALTER TABLE public.knowledge_documents
    ADD CONSTRAINT knowledge_documents_source_type_check
    CHECK (source_type IN ('upload', 'lesson', 'resources'));

INSERT INTO public.knowledge_bases (name, slug, description)
VALUES (
    'Community Resources (generated)',
    'community_resources',
    'Generated from the community resource directory (Content > Community Resources). Publishing there replaces its document.'
)
ON CONFLICT DO NOTHING;
