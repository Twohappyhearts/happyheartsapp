-- Broadcast inbox. A broadcast from the dashboard (Users > Broadcast Message) now reaches
-- any active account and lands in that person's inbox instead of the care-team chat:
--   patients        -> Inbox in the app (menu)
--   Careteam, Admin -> Inbox in the dashboard (top bar + sidebar)
-- Older broadcasts that went to the chat stay where they are.
--
-- Storage is "fan-out on read": a broadcast is stored once, with its audience.
--   * A whole group (every active patient / Careteam / Admin account) is stored as a role
--     in audience_roles; it reaches the accounts in that role that existed when it was sent.
--   * People picked one by one (a group only partly selected) get one row each in
--     broadcast_targets.
--   * Read state is one cursor per person (inbox_reads.last_read_at): everything sent
--     after it is unread. Opening the inbox moves the cursor to the newest message shown.
-- So "all patients" is one row whatever the number of patients, and reading writes one row.

CREATE TABLE IF NOT EXISTS public.broadcasts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id       UUID REFERENCES auth.users (id) ON DELETE SET NULL,
    content         TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 5000),
    audience_roles  TEXT[] NOT NULL DEFAULT '{}'
                    CHECK (audience_roles <@ ARRAY['patient', 'staff', 'admin']::TEXT[]),
    recipient_count INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.broadcasts IS
    'Broadcast messages (dashboard: Users > Broadcast Message), stored once. Whole groups are in audience_roles, single people in broadcast_targets. Written only by staff_broadcast().';
CREATE INDEX IF NOT EXISTS broadcasts_created_idx ON public.broadcasts (created_at DESC);

CREATE TABLE IF NOT EXISTS public.broadcast_targets (
    broadcast_id UUID NOT NULL REFERENCES public.broadcasts (id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    PRIMARY KEY (broadcast_id, user_id)
);
COMMENT ON TABLE public.broadcast_targets IS
    'Recipients picked one by one (outside a whole-group audience). No read state here.';
CREATE INDEX IF NOT EXISTS broadcast_targets_user_idx ON public.broadcast_targets (user_id);

CREATE TABLE IF NOT EXISTS public.inbox_reads (
    user_id      UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    last_read_at TIMESTAMPTZ NOT NULL
);
COMMENT ON TABLE public.inbox_reads IS
    'One read cursor per person: broadcasts sent after last_read_at are unread.';

ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inbox_reads ENABLE ROW LEVEL SECURITY;

-- Is this broadcast addressed to the caller? (RLS and Realtime use it.)
CREATE OR REPLACE FUNCTION public.broadcast_is_for_me(p_id UUID, p_roles TEXT[], p_created TIMESTAMPTZ)
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
                 AND ar.role = ANY (p_roles)
                 AND ar.created_at <= p_created
           )
        OR EXISTS (
               SELECT 1 FROM public.broadcast_targets t
               WHERE t.broadcast_id = p_id AND t.user_id = auth.uid()
           );
$$;

-- Reads only; every write goes through the functions below.
DROP POLICY IF EXISTS broadcasts_select_mine ON public.broadcasts;
CREATE POLICY broadcasts_select_mine ON public.broadcasts
    FOR SELECT TO authenticated USING (public.broadcast_is_for_me(id, audience_roles, created_at));

DROP POLICY IF EXISTS broadcast_targets_select_own ON public.broadcast_targets;
CREATE POLICY broadcast_targets_select_own ON public.broadcast_targets
    FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS inbox_reads_select_own ON public.inbox_reads;
CREATE POLICY inbox_reads_select_own ON public.inbox_reads
    FOR SELECT TO authenticated USING (user_id = auth.uid());

REVOKE INSERT, UPDATE, DELETE, TRUNCATE
    ON public.broadcasts, public.broadcast_targets, public.inbox_reads FROM anon, authenticated;
REVOKE ALL ON public.broadcasts, public.broadcast_targets, public.inbox_reads FROM anon;

-- Live inbox: clients listen for new broadcasts; Realtime only sends each person the
-- ones the policy above lets them read.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'broadcasts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcasts;
    END IF;
END $$;

-- Same signature as before, so the dashboard call is unchanged. Recipients may be any
-- active account. A role whose active accounts are all selected is stored as a group;
-- the rest are stored one by one.
CREATE OR REPLACE FUNCTION public.staff_broadcast(p_user_ids UUID[], p_content TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_body  TEXT := btrim(coalesce(p_content, ''));
    v_ids   UUID[];
    v_roles TEXT[];
    v_id    UUID;
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'staff only' USING ERRCODE = '42501';
    END IF;
    IF char_length(v_body) < 1 OR char_length(v_body) > 5000 THEN
        RAISE EXCEPTION 'message must be 1-5000 characters' USING ERRCODE = '22023';
    END IF;
    IF coalesce(array_length(p_user_ids, 1), 0) > 100000 THEN
        RAISE EXCEPTION 'too many recipients' USING ERRCODE = '22023';
    END IF;

    SELECT coalesce(array_agg(DISTINCT ar.user_id), '{}')
    INTO v_ids
    FROM public.account_roles ar
    WHERE ar.user_id = ANY (coalesce(p_user_ids, '{}')) AND ar.is_active = true;

    IF cardinality(v_ids) = 0 THEN
        RETURN 0;
    END IF;

    -- Roles where every active account was selected.
    SELECT coalesce(array_agg(r.role), '{}')
    INTO v_roles
    FROM (SELECT DISTINCT ar.role FROM public.account_roles ar WHERE ar.user_id = ANY (v_ids)) r
    WHERE NOT EXISTS (
        SELECT 1 FROM public.account_roles ar
        WHERE ar.role = r.role AND ar.is_active = true AND NOT (ar.user_id = ANY (v_ids))
    );

    INSERT INTO public.broadcasts (sender_id, content, audience_roles, recipient_count)
    VALUES (auth.uid(), v_body, v_roles, cardinality(v_ids))
    RETURNING id INTO v_id;

    INSERT INTO public.broadcast_targets (broadcast_id, user_id)
    SELECT v_id, ar.user_id
    FROM public.account_roles ar
    WHERE ar.user_id = ANY (v_ids) AND NOT (ar.role = ANY (v_roles));

    RETURN cardinality(v_ids);
END;
$$;

-- The caller's inbox, newest first. unread: sent after their read cursor. sender_name is
-- the sender's Display ID (else full name); patients can't read staff profiles.
CREATE OR REPLACE FUNCTION public.inbox_list(p_limit INTEGER DEFAULT 50, p_before TIMESTAMPTZ DEFAULT NULL)
RETURNS TABLE (id UUID, content TEXT, created_at TIMESTAMPTZ, unread BOOLEAN, sender_name TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT b.id, b.content, b.created_at,
           b.created_at > coalesce(rd.last_read_at, '-infinity'::TIMESTAMPTZ),
           coalesce(nullif(btrim(p.display_id), ''), nullif(btrim(p.full_name), ''))
    FROM public.broadcasts b
    LEFT JOIN public.inbox_reads rd ON rd.user_id = auth.uid()
    LEFT JOIN public.profiles p ON p.id = b.sender_id
    WHERE public.broadcast_is_for_me(b.id, b.audience_roles, b.created_at)
      AND (p_before IS NULL OR b.created_at < p_before)
    ORDER BY b.created_at DESC
    LIMIT least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

CREATE OR REPLACE FUNCTION public.inbox_unread_count()
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT count(*)::INT
    FROM public.broadcasts b
    WHERE b.created_at > coalesce(
              (SELECT rd.last_read_at FROM public.inbox_reads rd WHERE rd.user_id = auth.uid()),
              '-infinity'::TIMESTAMPTZ)
      AND public.broadcast_is_for_me(b.id, b.audience_roles, b.created_at);
$$;

-- Moves the caller's read cursor forward to p_until (the newest message they were shown;
-- default now). It never moves back.
CREATE OR REPLACE FUNCTION public.inbox_mark_read(p_until TIMESTAMPTZ DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'sign in required' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.inbox_reads (user_id, last_read_at)
    VALUES (auth.uid(), least(coalesce(p_until, now()), now()))
    ON CONFLICT (user_id) DO UPDATE
        SET last_read_at = greatest(public.inbox_reads.last_read_at, EXCLUDED.last_read_at);
END;
$$;

REVOKE ALL ON FUNCTION public.broadcast_is_for_me(UUID, TEXT[], TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.inbox_list(INTEGER, TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.inbox_unread_count() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.inbox_mark_read(TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.staff_broadcast(UUID[], TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.broadcast_is_for_me(UUID, TEXT[], TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inbox_list(INTEGER, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inbox_unread_count() TO authenticated;
GRANT EXECUTE ON FUNCTION public.inbox_mark_read(TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.staff_broadcast(UUID[], TEXT) TO authenticated;
