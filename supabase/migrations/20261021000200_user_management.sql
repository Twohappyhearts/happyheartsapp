-- ============================================================================
-- User Management (dashboard Prompt 6)
--
-- * Staff create accounts from the dashboard (Next.js server route, secret
--   key). The chosen username / role / display ID travel in auth
--   app_metadata, which only the service role can set — patients signing up in
--   the app cannot pick a role or a username this way.
-- * New staff-created accounts must change their temporary password at first
--   sign-in (account_roles.must_change_password).
-- * Staff list every account with activity counts (staff_list_users) and can
--   broadcast a chat message to many patients (staff_broadcast).
-- * Accounts are never hard-deleted from the dashboard (research data is
--   kept); disabling = account_roles.is_active=false + auth ban (server route).
-- ============================================================================

-- 1. First-login password change flag ----------------------------------------
ALTER TABLE public.account_roles
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;

-- 2. New-account trigger: honour staff-chosen username / role / display ID ----
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_full_name TEXT;
    v_username  TEXT := btrim(coalesce(NEW.raw_app_meta_data->>'username', ''));
    v_role      TEXT := coalesce(NEW.raw_app_meta_data->>'account_role', 'patient');
    v_display   TEXT := nullif(btrim(coalesce(NEW.raw_app_meta_data->>'display_id', '')), '');
    v_must      BOOLEAN := coalesce((NEW.raw_app_meta_data->>'must_change_password')::boolean, false);
BEGIN
    v_full_name := btrim(coalesce(NEW.raw_user_meta_data->>'full_name', ''));

    IF v_role NOT IN ('patient', 'staff', 'admin') THEN
        v_role := 'patient';
    END IF;

    IF v_username <> '' THEN
        -- Staff-assigned username (only settable with the service role).
        IF v_username !~ '^[A-Za-z0-9]{3,20}$' THEN
            RAISE EXCEPTION 'username must be 3-20 letters or digits' USING ERRCODE = '22023';
        END IF;
        IF EXISTS (SELECT 1 FROM public.profiles p WHERE lower(p.username) = lower(v_username)) THEN
            RAISE EXCEPTION 'username already taken' USING ERRCODE = '23505';
        END IF;
    ELSE
        -- Self-registration in the app: generated from the name / email.
        v_username := public.generate_unique_username(
            CASE WHEN v_full_name <> '' THEN v_full_name
                 ELSE split_part(coalesce(NEW.email, ''), '@', 1) END
        );
    END IF;

    INSERT INTO public.profiles (id, full_name, username, display_id)
    VALUES (NEW.id, v_full_name, v_username, left(v_display, 50))
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.account_roles (user_id, role, is_active, must_change_password)
    VALUES (NEW.id, v_role, true, v_must)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

-- 3. Clear the flag after the user set their own password ---------------------
CREATE OR REPLACE FUNCTION public.complete_password_change()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE public.account_roles
    SET must_change_password = false
    WHERE user_id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.complete_password_change() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_password_change() TO authenticated;

-- 4. Account list for the Users page ------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_list_users()
RETURNS TABLE (
    user_id              UUID,
    username             TEXT,
    full_name            TEXT,
    display_id           TEXT,
    email                TEXT,
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
        pr.id, pr.username, pr.full_name, pr.display_id, u.email::text,
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
REVOKE ALL ON FUNCTION public.staff_list_users() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_list_users() TO authenticated;

-- 5. Broadcast: one chat message to many patients ------------------------------
-- Each message goes into that patient's care-team conversation (created if
-- missing). Non-patients and disabled accounts are skipped. The existing chat
-- trigger stamps sender = the calling staff member.
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_content_length_check;
ALTER TABLE public.chat_messages ADD CONSTRAINT chat_messages_content_length_check
    CHECK (char_length(btrim(content)) BETWEEN 1 AND 5000) NOT VALID;

CREATE OR REPLACE FUNCTION public.staff_broadcast(p_user_ids UUID[], p_content TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_body TEXT := btrim(coalesce(p_content, ''));
    v_pid  UUID;
    v_conv UUID;
    v_sent INTEGER := 0;
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'staff only' USING ERRCODE = '42501';
    END IF;
    IF char_length(v_body) < 1 OR char_length(v_body) > 5000 THEN
        RAISE EXCEPTION 'message must be 1-5000 characters' USING ERRCODE = '22023';
    END IF;
    IF coalesce(array_length(p_user_ids, 1), 0) > 1000 THEN
        RAISE EXCEPTION 'too many recipients' USING ERRCODE = '22023';
    END IF;

    FOR v_pid IN
        SELECT DISTINCT ar.user_id
        FROM public.account_roles ar
        WHERE ar.user_id = ANY (coalesce(p_user_ids, '{}'))
          AND ar.role = 'patient'
          AND ar.is_active = true
    LOOP
        INSERT INTO public.conversations (patient_id) VALUES (v_pid)
        ON CONFLICT (patient_id) DO NOTHING;
        SELECT c.id INTO v_conv FROM public.conversations c WHERE c.patient_id = v_pid;
        INSERT INTO public.chat_messages (conversation_id, content) VALUES (v_conv, v_body);
        v_sent := v_sent + 1;
    END LOOP;

    RETURN v_sent;
END;
$$;
REVOKE ALL ON FUNCTION public.staff_broadcast(UUID[], TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_broadcast(UUID[], TEXT) TO authenticated;
