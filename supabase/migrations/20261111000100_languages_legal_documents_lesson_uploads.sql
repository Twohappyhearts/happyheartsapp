-- Languages, legal documents and lesson uploads (2026-11-11).
--
-- Additive only: dashboard and app builds from before this change keep working.
-- Run this before deploying the dashboard / app code that uses it.
--
-- Supported languages (Orange County's Medi-Cal threshold languages plus English):
--   en English, es Spanish, vi Vietnamese, ko Korean, zh Chinese, fa Farsi, ar Arabic.

-- 0. Helpers ---------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_active_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.account_roles ar
        WHERE ar.user_id = auth.uid()
          AND ar.is_active = true
          AND ar.role = 'admin'
    );
$$;
REVOKE ALL ON FUNCTION public.is_active_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_active_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.valid_language_code(code text) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT code IN ('en', 'es', 'vi', 'ko', 'zh', 'fa', 'ar');
$$;

-- A JSON array of 1–7 distinct language codes, e.g. ["en","es"].
CREATE OR REPLACE FUNCTION public.valid_language_list(j jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT CASE
        WHEN jsonb_typeof(j) <> 'array' THEN false
        WHEN jsonb_array_length(j) NOT BETWEEN 1 AND 7 THEN false
        ELSE NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(j) e
            WHERE jsonb_typeof(e) <> 'string'
               OR NOT public.valid_language_code(e #>> '{}')
        )
        AND (SELECT count(DISTINCT e #>> '{}') FROM jsonb_array_elements(j) e) = jsonb_array_length(j)
    END;
$$;

-- 1. App settings (key → JSON value). Every signed-in user can read; staff can change.
--    message_languages: languages the research team accepts in messages from patients
--    (the app shows a notice when a patient writes in another language).
CREATE TABLE public.app_settings (
    key         text PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_]{0,62}$'),
    value       jsonb NOT NULL,
    updated_by  uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT app_settings_message_languages_check
        CHECK (key <> 'message_languages' OR public.valid_language_list(value))
);
COMMENT ON TABLE public.app_settings IS
    'Settings the research team controls from the dashboard (Settings page). Readable by any signed-in user.';

CREATE TRIGGER trg_app_settings_touch BEFORE UPDATE ON public.app_settings
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.app_settings FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.app_settings TO authenticated;

CREATE POLICY app_settings_select_all ON public.app_settings
    FOR SELECT TO authenticated USING (true);
CREATE POLICY app_settings_insert_staff ON public.app_settings
    FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
CREATE POLICY app_settings_update_staff ON public.app_settings
    FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());

INSERT INTO public.app_settings (key, value, updated_by)
VALUES ('message_languages', '["en", "es"]'::jsonb, NULL)
ON CONFLICT (key) DO NOTHING;

-- 2. The patient's chosen app language (set by the app; NULL = follow the phone).
ALTER TABLE public.profiles
    ADD COLUMN preferred_language text
    CONSTRAINT profiles_preferred_language_check
        CHECK (preferred_language IS NULL OR public.valid_language_code(preferred_language));
COMMENT ON COLUMN public.profiles.preferred_language IS
    'App language the patient picked (en, es, vi, ko, zh, fa, ar). NULL = the phone''s language.';
GRANT UPDATE (preferred_language) ON public.profiles TO authenticated;  -- row limited by profiles_update_own

-- 3. Terms of Use and Privacy Policy (PDF files uploaded by an admin on the dashboard).
--    The newest version of each kind is the current one. Uploading a new Terms of Use asks
--    every patient to accept the AI notice again (agent_consents.terms_version).
CREATE TABLE public.legal_documents (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kind          text NOT NULL CHECK (kind IN ('terms', 'privacy')),
    version       integer NOT NULL CHECK (version >= 1),
    file_name     text NOT NULL CHECK (char_length(btrim(file_name)) BETWEEN 1 AND 255),
    storage_path  text NOT NULL UNIQUE CHECK (char_length(storage_path) <= 500),
    size_bytes    bigint CHECK (size_bytes IS NULL OR size_bytes >= 0),
    uploaded_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
    created_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (kind, version)
);
COMMENT ON TABLE public.legal_documents IS
    'Versions of the Terms of Use and Privacy Policy (bucket "legal"). Written only by the dashboard server.';

ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.legal_documents FROM anon, authenticated;
GRANT SELECT ON public.legal_documents TO anon, authenticated;
CREATE POLICY legal_documents_select_all ON public.legal_documents
    FOR SELECT TO anon, authenticated USING (true);

-- Public bucket: the documents are meant to be read by anyone using the app.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('legal', 'legal', true, 10485760, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 4. Which Terms of Use version the patient saw when accepting the AI notice
--    (0 = none uploaded yet; the dashboard showed the built-in sample).
ALTER TABLE public.agent_consents
    ADD COLUMN terms_version integer NOT NULL DEFAULT 0 CHECK (terms_version >= 0);
COMMENT ON COLUMN public.agent_consents.terms_version IS
    'legal_documents.version of the Terms of Use current when the patient accepted (0 = none uploaded).';

-- 5. Lesson materials uploaded from the dashboard (images and PDF documents).
--    [{ "name": "...", "url": "https://...", "kind": "image" | "pdf", "size_bytes": 12345 }]
CREATE OR REPLACE FUNCTION public.valid_lesson_attachments(j jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT CASE
        WHEN jsonb_typeof(j) <> 'array' THEN false
        WHEN jsonb_array_length(j) > 20 THEN false
        ELSE NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(j) e
            WHERE jsonb_typeof(e) <> 'object'
               OR coalesce(e->>'url', '') !~* '^https://[^[:space:]]+$'
               OR char_length(e->>'url') > 2000
               OR char_length(btrim(coalesce(e->>'name', ''))) NOT BETWEEN 1 AND 200
               OR coalesce(e->>'kind', '') NOT IN ('image', 'pdf')
               OR (e ? 'size_bytes' AND jsonb_typeof(e->'size_bytes') <> 'number')
        )
    END;
$$;

ALTER TABLE public.content_items
    ADD COLUMN attachments jsonb NOT NULL DEFAULT '[]'::jsonb
    CONSTRAINT content_items_attachments_check CHECK (public.valid_lesson_attachments(attachments));
COMMENT ON COLUMN public.content_items.attachments IS
    'Files staff uploaded for the lesson (bucket "lesson-materials"): [{name, url, kind: image|pdf, size_bytes}], at most 20.';

-- Public bucket: lesson content is not personal data and the app loads it directly.
-- Uploads go through the dashboard server (service role), so no storage policies are needed.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('lesson-materials', 'lesson-materials', true, 52428800,
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 6. Websites from the sponsor's Nov 9 source list (already added by hand on the live
--    dashboard on Nov 11; this keeps new installs the same). Existing rows are left alone.
INSERT INTO public.agent_web_domains (domain, label, created_by) VALUES
    ('cdc.gov', 'CDC', NULL),
    ('minorityhealth.hhs.gov', 'Office of Minority Health', NULL),
    ('millionhearts.hhs.gov', 'Million Hearts', NULL),
    ('cdph.ca.gov', 'California Department of Public Health', NULL),
    ('heart.org', 'American Heart Association', NULL),
    ('goredforwomen.org', 'Go Red for Women', NULL),
    ('diabetes.org', 'American Diabetes Association', NULL),
    ('postpartum.net', 'Postpartum Support International', NULL),
    ('ssihi.uci.edu', 'UCI Susan Samueli Integrative Health Institute', NULL),
    ('academicpeds.org', 'Academic Pediatric Association', NULL),
    ('awhonn.org', 'AWHONN', NULL),
    ('womenshealth.gov', 'Office on Women''s Health', NULL)
ON CONFLICT (domain) DO NOTHING;
