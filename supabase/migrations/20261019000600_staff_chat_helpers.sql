-- Staff chat helpers for the web dashboard.
-- Idempotent and additive: no table changes, no policy changes.
--
-- Why RPCs: staff can SELECT profiles/conversations via RLS, but cannot read other
-- users' account_roles (so they can't tell patients from staff), and conversations
-- are only created by get_or_create_my_conversation() (patient-only). These two
-- SECURITY DEFINER functions give active staff exactly those two capabilities.

-- 1. List active patients (with their conversation id, if any) -----------------
CREATE OR REPLACE FUNCTION public.staff_list_patients()
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    username TEXT,
    conversation_id UUID,
    last_message_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'staff only' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT p.id, p.full_name, p.username, c.id, c.last_message_at
    FROM public.profiles p
    JOIN public.account_roles ar ON ar.user_id = p.id
    LEFT JOIN public.conversations c ON c.patient_id = p.id
    WHERE ar.role = 'patient' AND ar.is_active = true
    ORDER BY c.last_message_at DESC NULLS LAST, lower(coalesce(nullif(p.full_name, ''), p.username));
END;
$$;

-- 2. Staff opens (or creates) the single conversation for a patient -------------
CREATE OR REPLACE FUNCTION public.staff_get_or_create_conversation(p_patient_id UUID)
RETURNS public.conversations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_conv public.conversations;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
    END IF;
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'staff only' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.account_roles ar
        JOIN public.profiles p ON p.id = ar.user_id
        WHERE ar.user_id = p_patient_id AND ar.role = 'patient' AND ar.is_active = true
    ) THEN
        RAISE EXCEPTION 'not an active patient' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.conversations (patient_id)
    VALUES (p_patient_id)
    ON CONFLICT (patient_id) DO NOTHING;

    SELECT * INTO v_conv FROM public.conversations WHERE patient_id = p_patient_id;
    RETURN v_conv;
END;
$$;

-- 3. Privileges -------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.staff_list_patients() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_list_patients() TO authenticated;
REVOKE ALL ON FUNCTION public.staff_get_or_create_conversation(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_get_or_create_conversation(UUID) TO authenticated;

-- Ask PostgREST to pick up the new functions immediately.
NOTIFY pgrst, 'reload schema';
