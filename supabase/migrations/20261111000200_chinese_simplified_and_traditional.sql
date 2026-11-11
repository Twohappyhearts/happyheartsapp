-- Chinese in both scripts (2026-11-11): 'zh' becomes 'zh-Hans' (Simplified) and 'zh-Hant'
-- (Traditional), so the app supports 8 languages. No stored value used 'zh' yet.

CREATE OR REPLACE FUNCTION public.valid_language_code(code text) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT code IN ('en', 'es', 'vi', 'ko', 'zh-Hans', 'zh-Hant', 'fa', 'ar');
$$;

-- A JSON array of 1–8 distinct language codes, e.g. ["en","es"].
CREATE OR REPLACE FUNCTION public.valid_language_list(j jsonb) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
    SELECT CASE
        WHEN jsonb_typeof(j) <> 'array' THEN false
        WHEN jsonb_array_length(j) NOT BETWEEN 1 AND 8 THEN false
        ELSE NOT EXISTS (
            SELECT 1 FROM jsonb_array_elements(j) e
            WHERE jsonb_typeof(e) <> 'string'
               OR NOT public.valid_language_code(e #>> '{}')
        )
        AND (SELECT count(DISTINCT e #>> '{}') FROM jsonb_array_elements(j) e) = jsonb_array_length(j)
    END;
$$;

COMMENT ON COLUMN public.profiles.preferred_language IS
    'App language the patient picked (en, es, vi, ko, zh-Hans, zh-Hant, fa, ar). NULL = the phone''s language.';
