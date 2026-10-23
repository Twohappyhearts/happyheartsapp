-- ============================================================================
-- Staff-created accounts: apply username / role / display ID after creation.
--
-- GoTrue inserts auth.users first and writes app_metadata in a later UPDATE,
-- so handle_new_auth_user cannot see the staff-chosen username. The dashboard
-- server route therefore calls admin_provision_account (service role only)
-- right after auth.admin.createUser().
-- ============================================================================

-- Usernames stay immutable for clients; only server-side roles may set them.
CREATE OR REPLACE FUNCTION public.protect_profile_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id THEN
        RAISE EXCEPTION 'profiles.id is immutable';
    END IF;
    IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'profiles.created_at is immutable';
    END IF;
    IF NEW.username IS DISTINCT FROM OLD.username
       AND current_user NOT IN ('postgres', 'service_role', 'supabase_admin') THEN
        RAISE EXCEPTION 'profiles.username is stable and cannot be changed by clients';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_provision_account(
    p_user_id    UUID,
    p_username   TEXT,
    p_role       TEXT,
    p_display_id TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_username TEXT := btrim(coalesce(p_username, ''));
BEGIN
    IF v_username !~ '^[A-Za-z0-9]{3,20}$' THEN
        RAISE EXCEPTION 'username must be 3-20 letters or digits' USING ERRCODE = '22023';
    END IF;
    IF p_role NOT IN ('patient', 'staff', 'admin') THEN
        RAISE EXCEPTION 'invalid role' USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE lower(p.username) = lower(v_username) AND p.id <> p_user_id
    ) THEN
        RAISE EXCEPTION 'username already taken' USING ERRCODE = '23505';
    END IF;

    UPDATE public.profiles
    SET username = v_username,
        display_id = nullif(left(btrim(coalesce(p_display_id, '')), 50), '')
    WHERE id = p_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'profile not found' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public.account_roles (user_id, role, is_active, must_change_password)
    VALUES (p_user_id, p_role, true, true)
    ON CONFLICT (user_id) DO UPDATE
    SET role = EXCLUDED.role, is_active = true, must_change_password = true;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_provision_account(UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_provision_account(UUID, TEXT, TEXT, TEXT) TO service_role;
