-- Applies the conversation model to the live database.
-- Idempotent: safe to run even if parts already exist. Non-destructive: the legacy
-- user_id column is kept (nullable) and existing messages are migrated.

-- 1. conversations ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_message_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_patient_unique
    ON public.conversations (patient_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at
    ON public.conversations (last_message_at DESC NULLS LAST);

-- 2. Evolve chat_messages ------------------------------------------------------
ALTER TABLE public.chat_messages
    ADD COLUMN IF NOT EXISTS conversation_id UUID,
    ADD COLUMN IF NOT EXISTS sender_id UUID;

ALTER TABLE public.chat_messages ALTER COLUMN user_id DROP NOT NULL;

UPDATE public.chat_messages SET created_at = now() WHERE created_at IS NULL;
ALTER TABLE public.chat_messages
    ALTER COLUMN created_at SET DEFAULT now(),
    ALTER COLUMN created_at SET NOT NULL;

-- 3. Report invalid legacy data (never silently deleted) ----------------------
DO $$
DECLARE
    v_bad_roles INT;
    v_no_profile INT;
BEGIN
    SELECT count(*) INTO v_bad_roles
    FROM public.chat_messages WHERE sender_role NOT IN ('user', 'team');
    SELECT count(*) INTO v_no_profile
    FROM public.chat_messages m
    WHERE m.user_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = m.user_id);

    IF v_bad_roles > 0 THEN
        RAISE NOTICE 'LEGACY DATA: % chat_messages rows have an unknown sender_role and were NOT migrated.', v_bad_roles;
    END IF;
    IF v_no_profile > 0 THEN
        RAISE NOTICE 'LEGACY DATA: % chat_messages rows reference a user_id with no profile and were NOT migrated.', v_no_profile;
    END IF;
END $$;

-- 4. Migrate legacy chat history -----------------------------------------------
INSERT INTO public.conversations (patient_id, last_message_at)
SELECT m.user_id, max(m.created_at)
FROM public.chat_messages m
JOIN public.profiles p ON p.id = m.user_id
WHERE m.conversation_id IS NULL
  AND m.sender_role IN ('user', 'team')
GROUP BY m.user_id
ON CONFLICT (patient_id) DO NOTHING;

UPDATE public.chat_messages m
SET conversation_id = c.id
FROM public.conversations c
WHERE m.conversation_id IS NULL
  AND m.user_id = c.patient_id
  AND m.sender_role IN ('user', 'team');

UPDATE public.chat_messages
SET sender_id = user_id
WHERE sender_id IS NULL
  AND sender_role = 'user'
  AND conversation_id IS NOT NULL;

-- 5. Constraints ---------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_messages_conversation_id_fkey') THEN
        ALTER TABLE public.chat_messages
            ADD CONSTRAINT chat_messages_conversation_id_fkey
            FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_messages_sender_id_fkey') THEN
        ALTER TABLE public.chat_messages
            ADD CONSTRAINT chat_messages_sender_id_fkey
            FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_messages_sender_role_check') THEN
        ALTER TABLE public.chat_messages
            ADD CONSTRAINT chat_messages_sender_role_check
            CHECK (sender_role IN ('user', 'team')) NOT VALID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_messages_content_length_check') THEN
        ALTER TABLE public.chat_messages
            ADD CONSTRAINT chat_messages_content_length_check
            CHECK (char_length(btrim(content)) BETWEEN 1 AND 4000) NOT VALID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_messages_conversation_required_check') THEN
        ALTER TABLE public.chat_messages
            ADD CONSTRAINT chat_messages_conversation_required_check
            CHECK (conversation_id IS NOT NULL) NOT VALID;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_created
    ON public.chat_messages (conversation_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id
    ON public.chat_messages (sender_id);

-- 6. Functions -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_chat_message_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_role TEXT;
    v_active BOOLEAN;
    v_patient UUID;
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        IF v_uid IS NOT NULL AND pg_trigger_depth() <= 1 THEN
            RAISE EXCEPTION 'chat messages cannot be edited or deleted';
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;

    IF v_uid IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT ar.role, ar.is_active INTO v_role, v_active
    FROM public.account_roles ar WHERE ar.user_id = v_uid;

    IF v_role IS NULL OR v_active IS NOT TRUE THEN
        RAISE EXCEPTION 'account is not active';
    END IF;

    SELECT c.patient_id INTO v_patient
    FROM public.conversations c WHERE c.id = NEW.conversation_id;
    IF v_patient IS NULL THEN
        RAISE EXCEPTION 'conversation not found';
    END IF;

    IF v_role = 'patient' THEN
        IF v_patient <> v_uid THEN
            RAISE EXCEPTION 'patients may only write to their own conversation';
        END IF;
        NEW.sender_role := 'user';
    ELSIF v_role IN ('staff', 'admin') THEN
        NEW.sender_role := 'team';
    ELSE
        RAISE EXCEPTION 'unsupported role';
    END IF;

    NEW.sender_id := v_uid;
    NEW.user_id := v_patient;
    NEW.created_at := now();
    NEW.content := btrim(NEW.content);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.bump_conversation_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = greatest(coalesce(last_message_at, NEW.created_at), NEW.created_at),
        updated_at = now()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_my_conversation()
RETURNS public.conversations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_conv public.conversations;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
    END IF;
    IF NOT public.is_active_patient() THEN
        RAISE EXCEPTION 'only active patients own a conversation' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid) THEN
        RAISE EXCEPTION 'profile missing' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.conversations (patient_id)
    VALUES (v_uid)
    ON CONFLICT (patient_id) DO NOTHING;

    SELECT * INTO v_conv FROM public.conversations WHERE patient_id = v_uid;
    RETURN v_conv;
END;
$$;

-- 7. Triggers ------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_chat_messages_enforce ON public.chat_messages;
CREATE TRIGGER trg_chat_messages_enforce
    BEFORE INSERT OR UPDATE OR DELETE ON public.chat_messages
    FOR EACH ROW EXECUTE FUNCTION public.enforce_chat_message_write();

DROP TRIGGER IF EXISTS trg_chat_messages_bump ON public.chat_messages;
CREATE TRIGGER trg_chat_messages_bump
    AFTER INSERT ON public.chat_messages
    FOR EACH ROW EXECUTE FUNCTION public.bump_conversation_activity();

DROP TRIGGER IF EXISTS trg_conversations_touch ON public.conversations;
CREATE TRIGGER trg_conversations_touch
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 8. Function privileges ---------------------------------------------------------
REVOKE ALL ON FUNCTION public.get_or_create_my_conversation() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_my_conversation() TO authenticated;
REVOKE ALL ON FUNCTION public.enforce_chat_message_write() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.bump_conversation_activity() FROM PUBLIC, anon, authenticated;
