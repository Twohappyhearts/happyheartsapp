-- Migration 1 of 3: profiles + account_roles + signup provisioning + backfill.
-- Non-destructive and idempotent. Auth credentials stay in Supabase-managed auth.users.

-- 1. Tables ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    username TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Case-insensitive unique username
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower
    ON public.profiles (lower(username));

CREATE TABLE IF NOT EXISTS public.account_roles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'patient',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'account_roles_role_check'
    ) THEN
        ALTER TABLE public.account_roles
            ADD CONSTRAINT account_roles_role_check
            CHECK (role IN ('patient', 'staff', 'admin'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_account_roles_role_active
    ON public.account_roles (role, is_active);

-- 2. Functions ---------------------------------------------------------------

-- Collision-safe username generator. Stable once stored (never regenerated).
CREATE OR REPLACE FUNCTION public.generate_unique_username(base_hint TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    base TEXT;
    candidate TEXT;
    attempts INT := 0;
BEGIN
    base := lower(regexp_replace(coalesce(base_hint, ''), '[^a-zA-Z0-9]+', '_', 'g'));
    base := trim(both '_' from base);
    IF base IS NULL OR length(base) < 3 THEN
        base := 'patient';
    END IF;
    base := left(base, 20);

    candidate := base;
    WHILE EXISTS (SELECT 1 FROM public.profiles p WHERE lower(p.username) = candidate) LOOP
        attempts := attempts + 1;
        candidate := base || '_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 4 + least(attempts, 6));
        EXIT WHEN attempts > 20;
    END LOOP;
    RETURN candidate;
END;
$$;

-- Provision profile + patient role when an auth account is created.
-- Role is ALWAYS patient here: client-supplied metadata is never trusted for role.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_full_name TEXT;
BEGIN
    v_full_name := btrim(coalesce(NEW.raw_user_meta_data->>'full_name', ''));

    INSERT INTO public.profiles (id, full_name, username)
    VALUES (
        NEW.id,
        v_full_name,
        public.generate_unique_username(
            CASE WHEN v_full_name <> '' THEN v_full_name ELSE split_part(coalesce(NEW.email, ''), '@', 1) END
        )
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.account_roles (user_id, role, is_active)
    VALUES (NEW.id, 'patient', true)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Trusted role helpers (SECURITY DEFINER, read account_roles only, so no RLS recursion
-- as long as account_roles policies never call them).
CREATE OR REPLACE FUNCTION public.is_active_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.account_roles ar
        WHERE ar.user_id = auth.uid()
          AND ar.is_active = true
          AND ar.role IN ('staff', 'admin')
    );
$$;

CREATE OR REPLACE FUNCTION public.is_active_patient()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.account_roles ar
        WHERE ar.user_id = auth.uid()
          AND ar.is_active = true
          AND ar.role = 'patient'
    );
$$;

-- Generic updated_at maintenance
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- Prevent clients from changing immutable profile fields.
CREATE OR REPLACE FUNCTION public.protect_profile_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id THEN
        RAISE EXCEPTION 'profiles.id is immutable';
    END IF;
    IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'profiles.created_at is immutable';
    END IF;
    IF NEW.username IS DISTINCT FROM OLD.username THEN
        RAISE EXCEPTION 'profiles.username is stable and cannot be changed by clients';
    END IF;
    RETURN NEW;
END;
$$;

-- 3. Triggers ----------------------------------------------------------------
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

DROP TRIGGER IF EXISTS trg_profiles_touch ON public.profiles;
CREATE TRIGGER trg_profiles_touch
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_protect ON public.profiles;
CREATE TRIGGER trg_profiles_protect
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_columns();

DROP TRIGGER IF EXISTS trg_account_roles_touch ON public.account_roles;
CREATE TRIGGER trg_account_roles_touch
    BEFORE UPDATE ON public.account_roles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 4. Backfill existing auth accounts (never overwrites existing rows) ---------
-- Existing accounts become patients. Staff/admin must be provisioned manually.
-- full_name is recovered from auth metadata when present; otherwise left empty
-- (not recoverable) and the app prompts/falls back to the username.
INSERT INTO public.profiles (id, full_name, username)
SELECT
    u.id,
    btrim(coalesce(u.raw_user_meta_data->>'full_name', '')),
    public.generate_unique_username(
        CASE
            WHEN btrim(coalesce(u.raw_user_meta_data->>'full_name', '')) <> ''
                THEN btrim(u.raw_user_meta_data->>'full_name')
            ELSE split_part(coalesce(u.email, ''), '@', 1)
        END
    )
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);

INSERT INTO public.account_roles (user_id, role, is_active)
SELECT u.id, 'patient', true
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.account_roles ar WHERE ar.user_id = u.id);

-- 5. RLS + grants ------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_roles ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.profiles FROM anon, authenticated;
REVOKE ALL ON public.account_roles FROM anon, authenticated;

GRANT SELECT ON public.profiles TO authenticated;
-- Column-level UPDATE: only full_name is client-editable.
GRANT UPDATE (full_name) ON public.profiles TO authenticated;
GRANT SELECT ON public.account_roles TO authenticated;
-- No INSERT/DELETE for clients on either table; no UPDATE at all on account_roles.

-- Profiles: a user reads/updates only their own row. Staff may read patient profiles
-- (needed by future staff tooling); patients cannot list others.
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_select_staff" ON public.profiles;
CREATE POLICY "profiles_select_staff" ON public.profiles
    FOR SELECT TO authenticated
    USING (public.is_active_staff());

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- account_roles: a user can read only their own role row. Never writable via API.
DROP POLICY IF EXISTS "account_roles_select_own" ON public.account_roles;
CREATE POLICY "account_roles_select_own" ON public.account_roles
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Helper functions: callable by signed-in users only.
REVOKE ALL ON FUNCTION public.is_active_staff() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_active_patient() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_active_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_active_patient() TO authenticated;
REVOKE ALL ON FUNCTION public.generate_unique_username(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;
