-- ============================================================================
-- Analytics: visit-scoped tracking events, derived views, staff stats RPCs.
--
-- Raw data stays in ONE append-only event log (tracking_events). Every event the
-- app sends belongs to a "visit" (visit_id = one stay on a lesson page; resuming
-- within 30 minutes continues the same visit). Everything the dashboard shows is
-- derived from that log by the views / functions below — nothing is stored twice.
--
-- Event types (value column):
--   session_opened      NULL   lesson page opened (once per visit)
--   session_closed      secs   one foreground segment on the page (visit = sum)
--   video_play          NULL   play pressed
--   video_watch         secs   one continuous playing segment
--   audio_play          NULL   play pressed
--   audio_listen        secs   one continuous playing segment
--   infographic_opened  secs   full-screen infographic open time
--   script_read         secs   time the lesson notes were >=50% on screen
--   quiz_started        NULL   "Start quiz" tapped
--   quiz_completed      1      "I finished the quiz" tapped (self-report)
--   session_completed   NULL   "Mark as completed" tapped
-- ============================================================================

-- 1. visit_id ----------------------------------------------------------------
ALTER TABLE public.tracking_events ADD COLUMN IF NOT EXISTS visit_id UUID;

CREATE INDEX IF NOT EXISTS idx_tracking_visit
    ON public.tracking_events (visit_id) WHERE visit_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tracking_user_content
    ON public.tracking_events (user_id, content_id, event_type);

-- 2. extended event types ----------------------------------------------------
ALTER TABLE public.tracking_events DROP CONSTRAINT IF EXISTS tracking_events_event_type_check;
ALTER TABLE public.tracking_events ADD CONSTRAINT tracking_events_event_type_check
    CHECK (event_type IN (
        'session_opened', 'session_closed',
        'video_play', 'video_watch',
        'audio_play', 'audio_listen',
        'infographic_opened', 'script_read',
        'quiz_started', 'quiz_completed',
        'session_completed'
    ));

-- Patients may now also send visit_id (user_id is always forced to auth.uid()).
GRANT INSERT (id, content_id, visit_id, event_type, value, metadata, occurred_at)
    ON public.tracking_events TO authenticated;

-- 3. helper: "MM:SS" -> seconds -------------------------------------------------
CREATE OR REPLACE FUNCTION public.mmss_to_seconds(p text)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
SET search_path = public, pg_temp
AS $$
    SELECT CASE
        WHEN p ~ '^\d{1,3}:\d{2}$'
        THEN split_part(p, ':', 1)::int * 60 + split_part(p, ':', 2)::int
    END;
$$;

-- 4. lesson_visits: one row per visit (a saved query, not a table) -----------
-- security_invoker = true -> the caller's RLS applies: patients see only their
-- own visits, staff see everyone's.
CREATE OR REPLACE VIEW public.lesson_visits
WITH (security_invoker = true) AS
SELECT
    te.visit_id,
    te.user_id,
    te.content_id,
    min(te.occurred_at)                                                    AS started_at,
    max(te.occurred_at)                                                    AS last_event_at,
    -- Sum of foreground segments. If the app was killed before the last segment
    -- was sent, fall back to first->last event span (capped at 4h).
    CASE
        WHEN count(*) FILTER (WHERE te.event_type = 'session_closed') > 0
        THEN round(sum(te.value) FILTER (WHERE te.event_type = 'session_closed'))::int
        ELSE least(extract(epoch FROM max(te.occurred_at) - min(te.occurred_at)), 14400)::int
    END                                                                    AS time_on_page_s,
    count(*) FILTER (WHERE te.event_type = 'video_play')::int              AS video_plays,
    round(coalesce(sum(te.value) FILTER (WHERE te.event_type = 'video_watch'), 0))::int  AS video_s,
    count(*) FILTER (WHERE te.event_type = 'audio_play')::int              AS audio_plays,
    round(coalesce(sum(te.value) FILTER (WHERE te.event_type = 'audio_listen'), 0))::int AS audio_s,
    count(*) FILTER (WHERE te.event_type = 'infographic_opened')::int      AS infographic_opens,
    round(coalesce(sum(te.value) FILTER (WHERE te.event_type = 'infographic_opened'), 0))::int AS infographic_s,
    round(coalesce(sum(te.value) FILTER (WHERE te.event_type = 'script_read'), 0))::int  AS script_s,
    count(*) FILTER (WHERE te.event_type = 'quiz_started')::int            AS quiz_starts,
    bool_or(te.event_type = 'quiz_completed')                              AS quiz_completed,
    bool_or(te.event_type = 'session_completed')                           AS completed,
    min(te.occurred_at) FILTER (WHERE te.event_type = 'quiz_completed')    AS quiz_completed_at,
    min(te.occurred_at) FILTER (WHERE te.event_type = 'session_completed') AS completed_at
FROM public.tracking_events te
WHERE te.visit_id IS NOT NULL
GROUP BY te.visit_id, te.user_id, te.content_id;

-- 5. lesson_progress: one row per (user, lesson) -------------------------------
-- A lesson counts as completed the first time the patient taps "Mark as completed".
CREATE OR REPLACE VIEW public.lesson_progress
WITH (security_invoker = true) AS
SELECT
    v.user_id,
    v.content_id,
    min(v.started_at)          AS first_opened_at,
    max(v.last_event_at)       AS last_activity_at,
    count(*)::int              AS visits,
    sum(v.time_on_page_s)::int AS time_on_page_s,
    sum(v.video_s)::int        AS video_s,
    sum(v.audio_s)::int        AS audio_s,
    sum(v.infographic_s)::int  AS infographic_s,
    sum(v.script_s)::int       AS script_s,
    min(v.quiz_completed_at)   AS quiz_completed_at,
    min(v.completed_at)        AS completed_at,
    CASE WHEN bool_or(v.completed) THEN 'completed' ELSE 'in_progress' END AS status
FROM public.lesson_visits v
WHERE v.content_id IS NOT NULL
GROUP BY v.user_id, v.content_id;

REVOKE ALL ON public.lesson_visits, public.lesson_progress FROM anon, PUBLIC;
GRANT SELECT ON public.lesson_visits, public.lesson_progress TO authenticated;

-- 6. Staff-only statistics functions ------------------------------------------
-- SECURITY DEFINER + explicit staff check, so the dashboard gets one consistent
-- answer regardless of profile / role RLS details. Patients get 42501.

-- 6a. KPI cards for a time window ([p_from, p_to), NULL = open-ended)
CREATE OR REPLACE FUNCTION public.analytics_overview(
    p_from TIMESTAMPTZ DEFAULT NULL,
    p_to   TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    session_opens     INTEGER,
    unique_viewers    INTEGER,
    avg_time_s        INTEGER,
    total_time_s      INTEGER,
    completions       INTEGER,
    completion_rate   NUMERIC,
    video_plays       INTEGER,
    audio_plays       INTEGER,
    infographic_opens INTEGER,
    script_reads      INTEGER,
    quiz_completions  INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH v AS (
        SELECT * FROM public.lesson_visits lv
        WHERE (p_from IS NULL OR lv.started_at >= p_from)
          AND (p_to   IS NULL OR lv.started_at <  p_to)
    )
    SELECT
        count(*)::int,
        count(DISTINCT v.user_id)::int,
        coalesce(round(avg(v.time_on_page_s)), 0)::int,
        coalesce(sum(v.time_on_page_s), 0)::int,
        count(DISTINCT (v.user_id, v.content_id)) FILTER (WHERE v.completed)::int,
        CASE WHEN count(DISTINCT (v.user_id, v.content_id)) = 0 THEN 0
             ELSE round(100.0 * count(DISTINCT (v.user_id, v.content_id)) FILTER (WHERE v.completed)
                        / count(DISTINCT (v.user_id, v.content_id)), 1)
        END,
        coalesce(sum(v.video_plays), 0)::int,
        coalesce(sum(v.audio_plays), 0)::int,
        coalesce(sum(v.infographic_opens), 0)::int,
        (count(*) FILTER (WHERE v.script_s >= 5))::int,
        count(DISTINCT (v.user_id, v.content_id)) FILTER (WHERE v.quiz_completed)::int
    FROM v;
END;
$$;

-- 6b. Weekly opens vs first-time completions (chart)
CREATE OR REPLACE FUNCTION public.analytics_weekly(
    p_weeks INTEGER DEFAULT 8,
    p_tz    TEXT    DEFAULT 'UTC'
)
RETURNS TABLE (
    week_start  DATE,
    opens       INTEGER,
    completions INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_tz    TEXT := 'UTC';
    v_weeks INTEGER := greatest(1, least(coalesce(p_weeks, 8), 52));
    v_first DATE;
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;
    IF p_tz IS NOT NULL AND EXISTS (SELECT 1 FROM pg_timezone_names WHERE name = p_tz) THEN
        v_tz := p_tz;
    END IF;

    v_first := (date_trunc('week', now() AT TIME ZONE v_tz) - make_interval(weeks => v_weeks - 1))::date;

    RETURN QUERY
    WITH weeks AS (
        SELECT gs::date AS wk
        FROM generate_series(v_first, v_first + (v_weeks - 1) * 7, interval '7 days') gs
    ),
    o AS (
        SELECT date_trunc('week', lv.started_at AT TIME ZONE v_tz)::date AS wk, count(*)::int AS n
        FROM public.lesson_visits lv
        GROUP BY 1
    ),
    c AS (
        SELECT date_trunc('week', lp.completed_at AT TIME ZONE v_tz)::date AS wk, count(*)::int AS n
        FROM public.lesson_progress lp
        WHERE lp.completed_at IS NOT NULL
        GROUP BY 1
    )
    SELECT w.wk, coalesce(o.n, 0), coalesce(c.n, 0)
    FROM weeks w
    LEFT JOIN o ON o.wk = w.wk
    LEFT JOIN c ON c.wk = w.wk
    ORDER BY w.wk;
END;
$$;

-- 6c. Per-lesson performance (All Content Performance table)
CREATE OR REPLACE FUNCTION public.analytics_content_performance(
    p_from TIMESTAMPTZ DEFAULT NULL,
    p_to   TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    content_id        UUID,
    title             TEXT,
    group_id          TEXT,
    category          TEXT,
    is_active         BOOLEAN,
    video_duration_s  INTEGER,
    opens             INTEGER,
    unique_viewers    INTEGER,
    avg_time_s        INTEGER,
    total_time_s      INTEGER,
    video_plays       INTEGER,
    video_s           INTEGER,
    audio_plays       INTEGER,
    audio_s           INTEGER,
    infographic_opens INTEGER,
    avg_infographic_s INTEGER,
    script_reads      INTEGER,
    script_s          INTEGER,
    quiz_starts       INTEGER,
    quiz_completions  INTEGER,
    completions       INTEGER,
    completion_rate   NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH v AS (
        SELECT * FROM public.lesson_visits lv
        WHERE (p_from IS NULL OR lv.started_at >= p_from)
          AND (p_to   IS NULL OR lv.started_at <  p_to)
    ),
    agg AS (
        SELECT
            v.content_id                                                   AS cid,
            count(*)::int                                                  AS opens,
            count(DISTINCT v.user_id)::int                                 AS uniq,
            round(avg(v.time_on_page_s))::int                              AS avg_t,
            sum(v.time_on_page_s)::int                                     AS tot_t,
            sum(v.video_plays)::int                                        AS vp,
            sum(v.video_s)::int                                            AS vs,
            sum(v.audio_plays)::int                                        AS ap,
            sum(v.audio_s)::int                                            AS a_s,
            sum(v.infographic_opens)::int                                  AS io,
            sum(v.infographic_s)::int                                      AS i_s,
            (count(*) FILTER (WHERE v.script_s >= 5))::int                 AS sr,
            sum(v.script_s)::int                                           AS ss,
            sum(v.quiz_starts)::int                                        AS qs,
            count(DISTINCT v.user_id) FILTER (WHERE v.quiz_completed)::int AS qc,
            count(DISTINCT v.user_id) FILTER (WHERE v.completed)::int      AS comp
        FROM v
        GROUP BY v.content_id
    )
    SELECT
        ci.id, ci.title, ci.group_id, cc.name, ci.is_active,
        public.mmss_to_seconds(ci.video_duration),
        coalesce(a.opens, 0), coalesce(a.uniq, 0), coalesce(a.avg_t, 0), coalesce(a.tot_t, 0),
        coalesce(a.vp, 0), coalesce(a.vs, 0), coalesce(a.ap, 0), coalesce(a.a_s, 0),
        coalesce(a.io, 0),
        CASE WHEN coalesce(a.io, 0) = 0 THEN 0 ELSE round(a.i_s::numeric / a.io)::int END,
        coalesce(a.sr, 0), coalesce(a.ss, 0),
        coalesce(a.qs, 0), coalesce(a.qc, 0), coalesce(a.comp, 0),
        CASE WHEN coalesce(a.uniq, 0) = 0 THEN 0
             ELSE round(100.0 * a.comp / a.uniq, 1) END
    FROM public.content_items ci
    LEFT JOIN public.content_categories cc ON cc.id = ci.category_id
    LEFT JOIN agg a ON a.cid = ci.id
    WHERE ci.kind = 'session'
    ORDER BY ci.group_number NULLS LAST, ci.title;
END;
$$;

-- 6d. Patient list for Individual User Analytics
CREATE OR REPLACE FUNCTION public.analytics_patients()
RETURNS TABLE (
    user_id           UUID,
    full_name         TEXT,
    username          TEXT,
    display_id        TEXT,
    is_active         BOOLEAN,
    last_active_at    TIMESTAMPTZ,
    lessons_opened    INTEGER,
    lessons_completed INTEGER,
    visits            INTEGER,
    total_time_s      INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH lp AS (
        SELECT
            p.user_id                                               AS uid,
            max(p.last_activity_at)                                 AS last_at,
            count(*)::int                                           AS opened,
            (count(*) FILTER (WHERE p.status = 'completed'))::int   AS done,
            sum(p.visits)::int                                      AS n_visits,
            sum(p.time_on_page_s)::int                              AS secs
        FROM public.lesson_progress p
        GROUP BY p.user_id
    )
    SELECT
        pr.id, pr.full_name, pr.username, pr.display_id, ar.is_active,
        lp.last_at,
        coalesce(lp.opened, 0), coalesce(lp.done, 0),
        coalesce(lp.n_visits, 0), coalesce(lp.secs, 0)
    FROM public.account_roles ar
    JOIN public.profiles pr ON pr.id = ar.user_id
    LEFT JOIN lp ON lp.uid = ar.user_id
    WHERE ar.role = 'patient'
    ORDER BY lp.last_at DESC NULLS LAST, coalesce(pr.full_name, pr.username);
END;
$$;

-- 6e. One patient x every lesson (Session Activity table)
CREATE OR REPLACE FUNCTION public.analytics_patient_lessons(p_user_id UUID)
RETURNS TABLE (
    content_id           UUID,
    title                TEXT,
    group_id             TEXT,
    is_active            BOOLEAN,
    opened               BOOLEAN,
    visits               INTEGER,
    video_played         BOOLEAN,
    audio_played         BOOLEAN,
    infographic_viewed   BOOLEAN,
    script_read          BOOLEAN,
    quiz_started         BOOLEAN,
    quiz_completed       BOOLEAN,
    completed            BOOLEAN,
    watched_video        BOOLEAN,
    reviewed_infographic BOOLEAN,
    time_on_page_s       INTEGER,
    video_s              INTEGER,
    audio_s              INTEGER,
    infographic_s        INTEGER,
    script_s             INTEGER,
    last_opened_at       TIMESTAMPTZ,
    completed_at         TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    WITH v AS (
        SELECT
            lv.content_id                       AS cid,
            count(*)::int                       AS n_visits,
            sum(lv.video_plays)::int            AS vp,
            sum(lv.audio_plays)::int            AS ap,
            sum(lv.infographic_opens)::int      AS io,
            sum(lv.quiz_starts)::int            AS qs,
            bool_or(lv.quiz_completed)          AS qc,
            bool_or(lv.completed)               AS comp,
            sum(lv.time_on_page_s)::int         AS t,
            sum(lv.video_s)::int                AS vs,
            sum(lv.audio_s)::int                AS a_s,
            sum(lv.infographic_s)::int          AS i_s,
            sum(lv.script_s)::int               AS ss,
            max(lv.started_at)                  AS last_at,
            min(lv.completed_at)                AS comp_at
        FROM public.lesson_visits lv
        WHERE lv.user_id = p_user_id
        GROUP BY lv.content_id
    )
    SELECT
        ci.id, ci.title, ci.group_id, ci.is_active,
        v.cid IS NOT NULL,
        coalesce(v.n_visits, 0),
        coalesce(v.vp, 0) > 0,
        coalesce(v.ap, 0) > 0,
        coalesce(v.io, 0) > 0,
        coalesce(v.ss, 0) >= 5,
        coalesce(v.qs, 0) > 0,
        coalesce(v.qc, false),
        coalesce(v.comp, false),
        -- "watched": >= 80% of the video's length (or >= 60s when length unknown)
        coalesce(v.vs, 0) >= coalesce(
            round(0.8 * public.mmss_to_seconds(ci.video_duration))::int, 60),
        coalesce(v.i_s, 0) >= 10,
        coalesce(v.t, 0), coalesce(v.vs, 0), coalesce(v.a_s, 0),
        coalesce(v.i_s, 0), coalesce(v.ss, 0),
        v.last_at, v.comp_at
    FROM public.content_items ci
    LEFT JOIN v ON v.cid = ci.id
    WHERE ci.kind = 'session'
    ORDER BY ci.group_number NULLS LAST, ci.title;
END;
$$;

-- 6f. One patient's most recent visits (Recent Visits timeline)
CREATE OR REPLACE FUNCTION public.analytics_patient_visits(
    p_user_id UUID,
    p_limit   INTEGER DEFAULT 30
)
RETURNS TABLE (
    visit_id          UUID,
    content_id        UUID,
    title             TEXT,
    started_at        TIMESTAMPTZ,
    last_event_at     TIMESTAMPTZ,
    time_on_page_s    INTEGER,
    video_plays       INTEGER,
    video_s           INTEGER,
    audio_plays       INTEGER,
    audio_s           INTEGER,
    infographic_opens INTEGER,
    infographic_s     INTEGER,
    script_s          INTEGER,
    quiz_starts       INTEGER,
    quiz_completed    BOOLEAN,
    completed         BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_active_staff() THEN
        RAISE EXCEPTION 'Only active staff can view analytics' USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT
        lv.visit_id, lv.content_id, ci.title, lv.started_at, lv.last_event_at,
        lv.time_on_page_s, lv.video_plays, lv.video_s, lv.audio_plays, lv.audio_s,
        lv.infographic_opens, lv.infographic_s, lv.script_s, lv.quiz_starts,
        lv.quiz_completed, lv.completed
    FROM public.lesson_visits lv
    LEFT JOIN public.content_items ci ON ci.id = lv.content_id
    WHERE lv.user_id = p_user_id
    ORDER BY lv.started_at DESC
    LIMIT greatest(1, least(coalesce(p_limit, 30), 200));
END;
$$;

REVOKE ALL ON FUNCTION public.analytics_overview(TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.analytics_weekly(INTEGER, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.analytics_content_performance(TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.analytics_patients() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.analytics_patient_lessons(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.analytics_patient_visits(UUID, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.analytics_overview(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.analytics_weekly(INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.analytics_content_performance(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.analytics_patients() TO authenticated;
GRANT EXECUTE ON FUNCTION public.analytics_patient_lessons(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.analytics_patient_visits(UUID, INTEGER) TO authenticated;
