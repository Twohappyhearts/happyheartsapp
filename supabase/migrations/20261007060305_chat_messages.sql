-- Chat messages table for direct messaging between users and research team

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_role TEXT NOT NULL DEFAULT 'user', -- 'user' or 'team'
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can read their own messages
DROP POLICY IF EXISTS "users_read_own_chat_messages" ON public.chat_messages;
CREATE POLICY "users_read_own_chat_messages"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own messages
DROP POLICY IF EXISTS "users_insert_own_chat_messages" ON public.chat_messages;
CREATE POLICY "users_insert_own_chat_messages"
ON public.chat_messages
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can delete their own messages
DROP POLICY IF EXISTS "users_delete_own_chat_messages" ON public.chat_messages;
CREATE POLICY "users_delete_own_chat_messages"
ON public.chat_messages
FOR DELETE
TO authenticated
USING (user_id = auth.uid());
