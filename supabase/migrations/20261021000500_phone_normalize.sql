-- Phone numbers are stored normalized: optional leading "+" then digits only
-- (e.g. "(949) 555-0100" -> "9495550100", "+1 949 555 0100" -> "+19495550100").
-- The UIs format them for display. This keeps the format check simple and
-- makes numbers comparable / searchable.
CREATE OR REPLACE FUNCTION public.normalize_phone(p TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = public, pg_temp
AS $$
    SELECT CASE
        WHEN p IS NULL OR btrim(p) = '' THEN NULL
        WHEN btrim(p) !~ '^\+?[0-9 ().-]+$' THEN NULL
        ELSE (CASE WHEN btrim(p) LIKE '+%' THEN '+' ELSE '' END)
             || regexp_replace(p, '[^0-9]', '', 'g')
    END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_full_name TEXT := btrim(coalesce(NEW.raw_user_meta_data->>'full_name', ''));
    v_username  TEXT := btrim(coalesce(
                            nullif(NEW.raw_app_meta_data->>'username', ''),
                            NEW.raw_user_meta_data->>'username',
                            ''));
    v_phone     TEXT := public.normalize_phone(NEW.raw_user_meta_data->>'phone_number');
    v_role      TEXT := coalesce(NEW.raw_app_meta_data->>'account_role', 'patient');
    v_display   TEXT := nullif(btrim(coalesce(NEW.raw_app_meta_data->>'display_id', '')), '');
    v_must      BOOLEAN := coalesce((NEW.raw_app_meta_data->>'must_change_password')::boolean, false);
BEGIN
    IF v_role NOT IN ('patient', 'staff', 'admin') THEN
        v_role := 'patient';
    END IF;

    IF v_username <> '' THEN
        IF v_username !~ '^[A-Za-z0-9]{3,20}$' THEN
            RAISE EXCEPTION 'username must be 3-20 letters or digits' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM public.profiles p WHERE lower(p.username) = lower(v_username)) THEN
            RAISE EXCEPTION 'username already taken' USING ERRCODE = '23505';
        END IF;
    ELSE
        v_username := public.generate_unique_username(
            CASE WHEN v_full_name <> '' THEN v_full_name
                 ELSE split_part(coalesce(NEW.email, ''), '@', 1) END
        );
    END IF;

    -- A malformed phone number never blocks sign-up; staff can fix it later.
    IF v_phone IS NOT NULL AND v_phone !~ '^\+?[0-9]{7,15}$' THEN
        v_phone := NULL;
    END IF;

    INSERT INTO public.profiles (id, full_name, username, display_id, phone)
    VALUES (NEW.id, v_full_name, v_username, left(v_display, 50), v_phone)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.account_roles (user_id, role, is_active, must_change_password)
    VALUES (NEW.id, v_role, true, v_must)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;
