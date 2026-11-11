-- 1. Websites the AI assistant may search (dashboard: Trusted Websites).
CREATE TABLE public.agent_web_domains (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    domain      text NOT NULL UNIQUE
                CHECK (char_length(domain) <= 253
                       AND domain ~ '^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}$'),
    label       text NOT NULL DEFAULT '' CHECK (char_length(label) <= 120),
    is_active   boolean NOT NULL DEFAULT true,
    created_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.agent_web_domains IS
    'Websites the AI assistant''s web search is limited to (subdomains included). Staff-managed.';

CREATE TRIGGER trg_agent_web_domains_touch BEFORE UPDATE ON public.agent_web_domains
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.agent_web_domains ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.agent_web_domains FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.agent_web_domains TO authenticated;

CREATE POLICY agent_web_domains_select_staff ON public.agent_web_domains
    FOR SELECT TO authenticated USING (public.is_active_staff());
CREATE POLICY agent_web_domains_insert_staff ON public.agent_web_domains
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
CREATE POLICY agent_web_domains_update_staff ON public.agent_web_domains
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
CREATE POLICY agent_web_domains_delete_staff ON public.agent_web_domains
    FOR DELETE TO authenticated USING (public.is_active_staff());

INSERT INTO public.agent_web_domains (domain, label, created_by) VALUES
    ('acog.org', 'American College of Obstetricians and Gynecologists', NULL),
    ('marchofdimes.org', 'March of Dimes', NULL),
    ('sleepfoundation.org', 'Sleep Foundation', NULL),
    ('preeclampsia.org', 'Preeclampsia Foundation', NULL),
    ('pubmed.ncbi.nlm.nih.gov', 'PubMed (research study)', NULL);

-- 2. Extra reference links of a lesson, added by staff: [{ "title": "...", "url": "https://..." }].
CREATE FUNCTION public.valid_reference_links(j jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT CASE
        WHEN jsonb_typeof(j) <> 'array' THEN false
        WHEN jsonb_array_length(j) > 30 THEN false
        ELSE NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(j) e
            WHERE jsonb_typeof(e) <> 'object'
               OR coalesce(e->>'url', '') !~* '^https://[^[:space:]]+$'
               OR char_length(e->>'url') > 2000
               OR char_length(coalesce(e->>'title', '')) > 200
        )
    END;
$$;

ALTER TABLE public.content_items
    ADD COLUMN reference_links jsonb NOT NULL DEFAULT '[]'::jsonb
    CONSTRAINT content_items_reference_links_check CHECK (public.valid_reference_links(reference_links));
COMMENT ON COLUMN public.content_items.reference_links IS
    'Links staff added to the lesson''s References block: [{title, url}], https only, at most 30.';

-- 3. Who accepted the AI assistant notice (shown the first time the patient opens the AI chat).
CREATE TABLE public.agent_consents (
    user_id    uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    version    integer NOT NULL CHECK (version >= 1),
    agreed_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.agent_consents IS
    'Acceptance of the AI assistant notice. Written only by the server (/api/agent/consent); version = notice version accepted.';

ALTER TABLE public.agent_consents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.agent_consents FROM anon, authenticated;
GRANT SELECT ON public.agent_consents TO authenticated;

CREATE POLICY agent_consents_select_own ON public.agent_consents
    FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY agent_consents_select_staff ON public.agent_consents
    FOR SELECT TO authenticated USING (public.is_active_staff());
