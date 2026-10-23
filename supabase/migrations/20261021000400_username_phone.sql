-- ============================================================================
-- Self-chosen usernames + phone numbers
--
-- * App sign-up now asks for a username (the same one used in REDCap — it is
--   the REDCap participant_code) and a phone number. Both arrive in
--   raw_user_meta_data at insert time and are applied by handle_new_auth_user.
-- * username_available(): lets the sign-up form check a username before
--   submitting (returns only true/false).
-- * Staff see / edit phone numbers on the dashboard Users page.
-- ============================================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_phone_format_check
    CHECK (phone IS NULL OR (char_length(phone) <= 30 AND phone ~ '^\+?[0-9][0-9 ().-]{5,28}$'));

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_full_name TEXT := btrim(coalesce(NEW.raw_user_meta_data->>'full_name', ''));
    -- Staff-assigned (service role) wins over what the person typed.
    v_username  TEXT := btrim(coalesce(
                            nullif(NEW.raw_app_meta_data->>'username', ''),
                            NEW.raw_user_meta_data->>'username',
                            ''));
    v_phone     TEXT := nullif(btrim(coalesce(NEW.raw_user_meta_data->>'phone_number', '')), '');
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
        -- Older app versions without a username field.
        v_username := public.generate_unique_username(
            CASE WHEN v_full_name <> '' THEN v_full_name
                 ELSE split_part(coalesce(NEW.email, ''), '@', 1) END
        );
    END IF;

    -- A malformed phone number never blocks sign-up; staff can fix it later.
    IF v_phone IS NOT NULL
       AND NOT (char_length(v_phone) <= 30 AND v_phone ~ '^\+?[0-9][0-9 ().-]{5,28}$') THEN
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

-- Sign-up form helper (callable before signing in). Only answers yes/no.
CREATE OR REPLACE FUNCTION public.username_available(p_username TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT btrim(coalesce(p_username, '')) ~ '^[A-Za-z0-9]{3,20}$'
       AND NOT EXISTS (
           SELECT 1 FROM public.profiles p
           WHERE lower(p.username) = lower(btrim(p_username))
       );
$$;
REVOKE ALL ON FUNCTION public.username_available(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.username_available(TEXT) TO anon, authenticated;

-- Users page list with phone numbers. New name instead of changing the return
-- type of staff_list_users (that would need a DROP); the old function is no
-- longer used by the dashboard and can be dropped later.
CREATE OR REPLACE FUNCTION public.staff_list_accounts()
RETURNS TABLE (
    user_id              UUID,
    username             TEXT,
    full_name            TEXT,
    display_id           TEXT,
    email                TEXT,
    phone                TEXT,
    role                 TEXT,
    is_active            BOOLEAN,
    must_change_password BOOLEAN,
    created_at           TIMESTAMPTZ,
    last_sign_in_at      TIMESTAMPTZ,
    last_active_at       TIMESTAMPTZ,
    lessons_opened       INTEGER,
    lessons_completed    INTEGER,
    alerts_sent          INTEGER,
    open_alerts          INTEGER
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
    WITH lp AS (
        SELECT p.user_id AS uid,
               count(*)::int AS opened,
               (count(*) FILTER (WHERE p.status = 'completed'))::int AS done,
               max(p.last_activity_at) AS last_at
        FROM public.lesson_progress p
        GROUP BY p.user_id
    ),
    al AS (
        SELECT a.patient_id AS uid,
               count(*)::int AS sent,
               (count(*) FILTER (WHERE a.status IN ('NEW', 'ACK')))::int AS open_n,
               max(a.created_at) AS last_at
        FROM public.assistance_requests a
        GROUP BY a.patient_id
    ),
    cm AS (
        SELECT m.sender_id AS uid, max(m.created_at) AS last_at
        FROM public.chat_messages m
        WHERE m.sender_id IS NOT NULL
        GROUP BY m.sender_id
    )
    SELECT
        pr.id, pr.username, pr.full_name, pr.display_id, u.email::text, pr.phone,
        ar.role, ar.is_active, ar.must_change_password,
        pr.created_at, u.last_sign_in_at,
        nullif(greatest(
            coalesce(lp.last_at, '-infinity'::timestamptz),
            coalesce(al.last_at, '-infinity'::timestamptz),
            coalesce(cm.last_at, '-infinity'::timestamptz),
            coalesce(u.last_sign_in_at, '-infinity'::timestamptz)
        ), '-infinity'::timestamptz),
        coalesce(lp.opened, 0), coalesce(lp.done, 0),
        coalesce(al.sent, 0), coalesce(al.open_n, 0)
    FROM public.profiles pr
    JOIN public.account_roles ar ON ar.user_id = pr.id
    LEFT JOIN auth.users u ON u.id = pr.id
    LEFT JOIN lp ON lp.uid = pr.id
    LEFT JOIN al ON al.uid = pr.id
    LEFT JOIN cm ON cm.uid = pr.id
    ORDER BY pr.created_at DESC;
END;
$$;
REVOKE ALL ON FUNCTION public.staff_list_accounts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_list_accounts() TO authenticated;
