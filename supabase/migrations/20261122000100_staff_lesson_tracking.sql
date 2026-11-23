-- Staff and admin accounts can record lesson activity too (Bo, 2026-11-22).
--
-- Until now only active patients could insert tracking_events, so staff testing the app could
-- never complete a lesson and their progress stayed empty. The research numbers must still count
-- patients only, so every analytics function that sums across accounts now keeps patient rows
-- only. Already patient-only: analytics_patients (the patient list) and the per-patient
-- analytics_patient_lessons / analytics_patient_visits, which are opened from that list.
-- lesson_visits / lesson_progress stay unfiltered views (security_invoker): the app reads only
-- the caller's own rows, and staff see everyone's for these functions.

-- 1. Who may record: the caller's own rows, as an active patient or active staff/admin.
DROP POLICY IF EXISTS "tracking_insert_patient" ON public.tracking_events;
DROP POLICY IF EXISTS "tracking_insert_own" ON public.tracking_events;
CREATE POLICY "tracking_insert_own" ON public.tracking_events
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() AND (public.is_active_patient() OR public.is_active_staff()));

-- 2. Analytics across accounts count patients only (same bodies as 20261021000100 plus the filter).

-- 2a. Overview cards
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
          AND EXISTS (SELECT 1 FROM public.account_roles ar
                      WHERE ar.user_id = lv.user_id AND ar.role = 'patient')
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

-- 2b. Weekly opens vs first-time completions (chart)
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
        WHERE EXISTS (SELECT 1 FROM public.account_roles ar
                      WHERE ar.user_id = lv.user_id AND ar.role = 'patient')
        GROUP BY 1
    ),
    c AS (
        SELECT date_trunc('week', lp.completed_at AT TIME ZONE v_tz)::date AS wk, count(*)::int AS n
        FROM public.lesson_progress lp
        WHERE lp.completed_at IS NOT NULL
          AND EXISTS (SELECT 1 FROM public.account_roles ar
                      WHERE ar.user_id = lp.user_id AND ar.role = 'patient')
        GROUP BY 1
    )
    SELECT w.wk, coalesce(o.n, 0), coalesce(c.n, 0)
    FROM weeks w
    LEFT JOIN o ON o.wk = w.wk
    LEFT JOIN c ON c.wk = w.wk
    ORDER BY w.wk;
END;
$$;

-- 2c. Per-lesson performance (All Content Performance table)
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
          AND EXISTS (SELECT 1 FROM public.account_roles ar
                      WHERE ar.user_id = lv.user_id AND ar.role = 'patient')
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
