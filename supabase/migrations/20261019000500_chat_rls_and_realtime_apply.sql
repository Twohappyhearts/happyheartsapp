-- Applies RLS policies, grants, obsolete policy cleanup and Realtime.
-- Idempotent and safe to run after 20261019000400.

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_read_own_chat_messages" ON public.chat_messages;
DROP POLICY IF EXISTS "users_insert_own_chat_messages" ON public.chat_messages;
DROP POLICY IF EXISTS "users_delete_own_chat_messages" ON public.chat_messages;

REVOKE ALL ON public.conversations FROM anon, authenticated;
REVOKE ALL ON public.chat_messages FROM anon, authenticated;

GRANT SELECT ON public.conversations TO authenticated;
GRANT SELECT ON public.chat_messages TO authenticated;
GRANT INSERT (id, conversation_id, content) ON public.chat_messages TO authenticated;

CREATE OR REPLACE FUNCTION public.can_access_conversation(p_conversation_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.account_roles ar
        WHERE ar.user_id = auth.uid()
          AND ar.is_active = true
          AND (
              ar.role IN ('staff', 'admin')
              OR (
                  ar.role = 'patient'
                  AND EXISTS (
                      SELECT 1 FROM public.conversations c
                      WHERE c.id = p_conversation_id AND c.patient_id = auth.uid()
                  )
              )
          )
    );
$$;

REVOKE ALL ON FUNCTION public.can_access_conversation(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_conversation(UUID) TO authenticated;

DROP POLICY IF EXISTS "conversations_select_own_patient" ON public.conversations;
CREATE POLICY "conversations_select_own_patient" ON public.conversations
    FOR SELECT TO authenticated
    USING (patient_id = auth.uid() AND public.is_active_patient());

DROP POLICY IF EXISTS "conversations_select_staff" ON public.conversations;
CREATE POLICY "conversations_select_staff" ON public.conversations
    FOR SELECT TO authenticated
    USING (public.is_active_staff());

DROP POLICY IF EXISTS "chat_messages_select_accessible" ON public.chat_messages;
CREATE POLICY "chat_messages_select_accessible" ON public.chat_messages
    FOR SELECT TO authenticated
    USING (public.can_access_conversation(conversation_id));

DROP POLICY IF EXISTS "chat_messages_insert_accessible" ON public.chat_messages;
CREATE POLICY "chat_messages_insert_accessible" ON public.chat_messages
    FOR INSERT TO authenticated
    WITH CHECK (public.can_access_conversation(conversation_id));

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
              AND schemaname = 'public' AND tablename = 'chat_messages'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
        END IF;
    ELSE
        RAISE NOTICE 'supabase_realtime publication not found; enable Realtime for public.chat_messages in the dashboard.';
    END IF;
END $$;
