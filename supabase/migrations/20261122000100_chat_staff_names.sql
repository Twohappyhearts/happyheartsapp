-- Care Team chat: patients can see WHO on the team replied.
--
-- Patients cannot read other people's profiles (RLS: profiles_select_own), so the app asks
-- this function for the names of the team members who wrote in the caller's own
-- conversation. A name is the member's Display ID (set on the dashboard's Users page,
-- "Friendly name for display"), else their full name. Members with neither are left out:
-- the app then shows "Research Team" as before.
--
-- Only names are returned (no email, phone or username), and only for team members who
-- actually wrote in a conversation the caller may access (can_access_conversation: the
-- patient's own conversation, or any conversation for active staff).

CREATE OR REPLACE FUNCTION public.chat_staff_names(p_conversation_id UUID)
RETURNS TABLE (sender_id UUID, name TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT s.sender_id, s.name
    FROM (
        SELECT DISTINCT
            m.sender_id,
            coalesce(nullif(btrim(p.display_id), ''), nullif(btrim(p.full_name), '')) AS name
        FROM public.chat_messages m
        JOIN public.profiles p ON p.id = m.sender_id
        WHERE m.conversation_id = p_conversation_id
          AND m.sender_role = 'team'
          AND public.can_access_conversation(p_conversation_id)
    ) s
    WHERE s.name IS NOT NULL;
$$;

COMMENT ON FUNCTION public.chat_staff_names(UUID) IS
    'Names (Display ID, else full name) of the team members who wrote in a conversation the caller can access; for the patient app''s Care Team chat.';

REVOKE ALL ON FUNCTION public.chat_staff_names(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.chat_staff_names(UUID) TO authenticated;
