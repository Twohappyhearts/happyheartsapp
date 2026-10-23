-- ai_identities: also remember the Botpress conversation id.
-- Verified against Botpress Webchat v5: restoring only userId + userToken makes
-- the webchat open a NEW empty conversation; restoring the conversationId too
-- reloads the previous history from Botpress' cloud.

ALTER TABLE public.ai_identities
    ADD COLUMN IF NOT EXISTS botpress_conversation_id TEXT
    CHECK (botpress_conversation_id IS NULL
           OR char_length(btrim(botpress_conversation_id)) BETWEEN 1 AND 200);

-- Not a secret (useless without the user key or a Botpress admin token);
-- staff may read it for future dashboard viewing.
GRANT SELECT (botpress_conversation_id) ON public.ai_identities TO authenticated;

-- Return / argument shapes change, so the old versions are replaced.
DROP FUNCTION IF EXISTS public.get_my_ai_identity();
DROP FUNCTION IF EXISTS public.save_my_ai_identity(TEXT, TEXT);

CREATE FUNCTION public.get_my_ai_identity()
RETURNS TABLE (
    botpress_user_id TEXT,
    botpress_user_key TEXT,
    botpress_conversation_id TEXT,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT a.botpress_user_id, a.botpress_user_key, a.botpress_conversation_id, a.updated_at
    FROM public.ai_identities a
    WHERE a.user_id = auth.uid();
$$;

CREATE FUNCTION public.save_my_ai_identity(
    p_botpress_user_id TEXT,
    p_botpress_user_key TEXT,
    p_botpress_conversation_id TEXT DEFAULT NULL
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

    INSERT INTO public.ai_identities AS a
        (user_id, botpress_user_id, botpress_user_key, botpress_conversation_id)
    VALUES (v_uid, btrim(p_botpress_user_id), p_botpress_user_key,
            nullif(btrim(coalesce(p_botpress_conversation_id, '')), ''))
    ON CONFLICT (user_id) DO UPDATE
        SET botpress_user_id = EXCLUDED.botpress_user_id,
            botpress_user_key = EXCLUDED.botpress_user_key,
            -- Same Botpress user: keep the known conversation unless a new one
            -- is reported. Different Botpress user: the old conversation
            -- belongs to someone else, so never carry it over.
            botpress_conversation_id = CASE
                WHEN a.botpress_user_id = EXCLUDED.botpress_user_id
                    THEN coalesce(EXCLUDED.botpress_conversation_id, a.botpress_conversation_id)
                ELSE EXCLUDED.botpress_conversation_id
            END,
            updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_ai_identity() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.save_my_ai_identity(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_ai_identity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_my_ai_identity(TEXT, TEXT, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
