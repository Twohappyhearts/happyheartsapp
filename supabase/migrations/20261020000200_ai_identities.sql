-- ai_identities: each HappyHearts account's Botpress (AI assistant) identity.
-- Works for any signed-in role (patient, staff, admin), keyed by auth user id.
--
--   botpress_user_id  - Botpress' id for this user. Not a secret. Staff may read
--                       it (future: dashboard reads AI conversations server-side
--                       with a Botpress token + this id).
--   botpress_user_key - Botpress user key (JWT). A credential: whoever holds it
--                       can read and send messages as this user. Only the owner
--                       can read/write it, and only through the RPCs below.
--
-- Column privileges are per DB role, and every signed-in user is `authenticated`,
-- so the key column is not granted to anyone; the owner uses SECURITY DEFINER
-- functions that are hard-wired to auth.uid().

CREATE TABLE IF NOT EXISTS public.ai_identities (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    botpress_user_id TEXT NOT NULL CHECK (char_length(btrim(botpress_user_id)) BETWEEN 1 AND 200),
    botpress_user_key TEXT NOT NULL CHECK (char_length(botpress_user_key) BETWEEN 1 AND 4096),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_identities_botpress_user
    ON public.ai_identities (botpress_user_id);

ALTER TABLE public.ai_identities ENABLE ROW LEVEL SECURITY;

-- No table-wide privileges; read access to non-secret columns only.
REVOKE ALL ON public.ai_identities FROM anon, authenticated;
GRANT SELECT (user_id, botpress_user_id, created_at, updated_at)
    ON public.ai_identities TO authenticated;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'ai_identities' AND policyname = 'ai_identities_select_own') THEN
        CREATE POLICY "ai_identities_select_own" ON public.ai_identities
            FOR SELECT TO authenticated USING (user_id = auth.uid());
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'ai_identities' AND policyname = 'ai_identities_select_staff') THEN
        CREATE POLICY "ai_identities_select_staff" ON public.ai_identities
            FOR SELECT TO authenticated USING (public.is_active_staff());
    END IF;
END $$;

-- Owner: read own identity, including the key. Returns no row if none saved yet.
CREATE OR REPLACE FUNCTION public.get_my_ai_identity()
RETURNS TABLE (botpress_user_id TEXT, botpress_user_key TEXT, updated_at TIMESTAMPTZ)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT a.botpress_user_id, a.botpress_user_key, a.updated_at
    FROM public.ai_identities a
    WHERE a.user_id = auth.uid();
$$;

-- Owner: save / replace own identity (first use, or after Botpress issued a new one).
CREATE OR REPLACE FUNCTION public.save_my_ai_identity(
    p_botpress_user_id TEXT,
    p_botpress_user_key TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.account_roles ar
                   WHERE ar.user_id = v_uid AND ar.is_active) THEN
        RAISE EXCEPTION 'account is not active' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.ai_identities AS a (user_id, botpress_user_id, botpress_user_key)
    VALUES (v_uid, btrim(p_botpress_user_id), p_botpress_user_key)
    ON CONFLICT (user_id) DO UPDATE
        SET botpress_user_id = EXCLUDED.botpress_user_id,
            botpress_user_key = EXCLUDED.botpress_user_key,
            updated_at = now();
END;
$$;

-- Owner: forget own identity (e.g. "start a new AI conversation" / reset).
CREATE OR REPLACE FUNCTION public.delete_my_ai_identity()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    DELETE FROM public.ai_identities WHERE user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_ai_identity() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.save_my_ai_identity(TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_my_ai_identity() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_ai_identity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_my_ai_identity(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_ai_identity() TO authenticated;

NOTIFY pgrst, 'reload schema';
