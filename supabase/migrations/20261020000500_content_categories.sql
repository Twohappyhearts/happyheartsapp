-- Content categories (staff-managed in the dashboard) + import of the 5
-- education sessions that were hard-coded in the mobile app.
-- Additive and idempotent: no DROP statements.

-- 1. content_categories ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One spelling per category ("Sleep Health" vs "sleep health" is the same one).
CREATE UNIQUE INDEX IF NOT EXISTS idx_content_categories_name_lower
    ON public.content_categories (lower(btrim(name)));
CREATE INDEX IF NOT EXISTS idx_content_categories_order
    ON public.content_categories (sort_order, name);

CREATE OR REPLACE FUNCTION public.content_categories_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.name := btrim(regexp_replace(NEW.name, '\s+', ' ', 'g'));
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := now();
    ELSIF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'created_at cannot be changed';
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.content_categories_before_write() FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_content_categories_before_write') THEN
        CREATE TRIGGER trg_content_categories_before_write
            BEFORE INSERT OR UPDATE ON public.content_categories
            FOR EACH ROW EXECUTE FUNCTION public.content_categories_before_write();
    END IF;
END $$;

ALTER TABLE public.content_categories ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.content_categories FROM anon, authenticated;
GRANT SELECT ON public.content_categories TO authenticated;
GRANT INSERT (id, name, sort_order, is_active) ON public.content_categories TO authenticated;
GRANT UPDATE (name, sort_order, is_active) ON public.content_categories TO authenticated;
GRANT DELETE ON public.content_categories TO authenticated;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'content_categories' AND policyname = 'categories_select_staff') THEN
        CREATE POLICY "categories_select_staff" ON public.content_categories
            FOR SELECT TO authenticated USING (public.is_active_staff());
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'content_categories' AND policyname = 'categories_select_active_patient') THEN
        CREATE POLICY "categories_select_active_patient" ON public.content_categories
            FOR SELECT TO authenticated USING (is_active AND public.is_active_patient());
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'content_categories' AND policyname = 'categories_insert_staff') THEN
        CREATE POLICY "categories_insert_staff" ON public.content_categories
            FOR INSERT TO authenticated WITH CHECK (public.is_active_staff());
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'content_categories' AND policyname = 'categories_update_staff') THEN
        CREATE POLICY "categories_update_staff" ON public.content_categories
            FOR UPDATE TO authenticated USING (public.is_active_staff()) WITH CHECK (public.is_active_staff());
    END IF;
    -- Deleting a category that content still uses is blocked by the foreign key
    -- (ON DELETE RESTRICT); staff can deactivate it instead.
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
                   AND tablename = 'content_categories' AND policyname = 'categories_delete_staff') THEN
        CREATE POLICY "categories_delete_staff" ON public.content_categories
            FOR DELETE TO authenticated USING (public.is_active_staff());
    END IF;
END $$;

INSERT INTO public.content_categories (name, sort_order)
SELECT v.name, v.ord
FROM (VALUES
    ('Heart Health', 1),
    ('Sleep Health', 2),
    ('Emotional Support & Resources', 3),
    ('Resources', 4)
) AS v(name, ord)
WHERE NOT EXISTS (
    SELECT 1 FROM public.content_categories c WHERE lower(c.name) = lower(v.name)
);

-- 2. content_items: category + thumbnail alt text --------------------------------
ALTER TABLE public.content_items
    ADD COLUMN IF NOT EXISTS category_id UUID
        REFERENCES public.content_categories(id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS thumbnail_alt TEXT
        CHECK (thumbnail_alt IS NULL OR char_length(thumbnail_alt) <= 300);

CREATE INDEX IF NOT EXISTS idx_content_items_category
    ON public.content_items (category_id);

-- 3. Import the 5 sessions previously hard-coded in the mobile app ---------------
-- (education_hub_screen.dart). Order kept: they become session1..session5.
-- Per-user progress ("completed"/"in_progress") is not content and is not
-- imported; it will come from tracking_events. The app's total "30 min" style
-- durations are not video MM:SS durations, so they are left empty.
INSERT INTO public.content_items
    (kind, title, description, category_id, thumbnail_url, thumbnail_alt,
     infographic_url, video_url, quiz_url, is_active)
SELECT 'session', v.title, v.description,
       (SELECT c.id FROM public.content_categories c WHERE lower(c.name) = lower(v.category)),
       v.thumbnail, v.alt, v.infographic, v.video, v.quiz, true
FROM (VALUES
    (1, 'Preeclampsia Education',
        'Understanding preeclampsia risks, signs, and management during pregnancy',
        'Heart Health',
        'https://img.rocket.new/generatedImages/rocket_gen_img_41f31f362-1791350628906.png',
        'Preeclampsia education infographic showing risks, signs, and management during pregnancy',
        'https://img.rocket.new/generatedImages/rocket_gen_img_49143873a-1792368870940.png',
        'https://www.youtube.com/watch?v=Y05BNvwf9w0',
        'https://kahoot.it/challenge/05183456?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1787846922340'),
    (2, 'Physical Activity and Sleep',
        'Building healthy sleep and exercise habits during pregnancy',
        'Sleep Health',
        'https://img.rocket.new/generatedImages/rocket_gen_img_11e27b303-1767093625473.png',
        'Physical activity and sleep infographic showing healthy exercise and sleep habits during pregnancy',
        'https://img.rocket.new/generatedImages/rocket_gen_img_11e27b303-1767093625473.png',
        'https://www.youtube.com/watch?v=s4LWkyhV9AQ',
        'https://kahoot.it/challenge/04339948?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788603912485'),
    (3, 'Understanding Prenatal Anxiety',
        'Recognizing and managing anxiety during pregnancy',
        'Emotional Support & Resources',
        'https://res.cloudinary.com/drytmgv5/image/upload/f_auto,q_auto/peri-anxiModified-11-25-2025-LN-819x1024',
        'Prenatal anxiety infographic showing how to recognize and manage anxiety during pregnancy',
        'https://res.cloudinary.com/drytmgv5/image/upload/f_auto,q_auto/peri-anxiModified-11-25-2025-LN-819x1024',
        'https://www.youtube.com/watch?v=0xEC23Zmdrs',
        'https://kahoot.it/challenge/03641688?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788587319343'),
    (4, 'Perinatal Depression & Anxiety Resources',
        'Resources and support for perinatal mood disorders',
        'Emotional Support & Resources',
        'https://img.rocket.new/generatedImages/rocket_gen_img_4ea9ae0e5-1791350627795.png',
        'Perinatal depression and anxiety resources infographic showing support options for mood disorders',
        'https://img.rocket.new/generatedImages/rocket_gen_img_4a2a636d1-1792368870652.png',
        'https://www.youtube.com/watch?v=Kq_Jm_PJuqo',
        'https://kahoot.it/challenge/07018409?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788596476612'),
    (5, 'How to Talk to Your Healthcare Provider',
        'Tips for effective communication with your medical team',
        'Resources',
        'https://img.rocket.new/generatedImages/rocket_gen_img_4c29facf2-1791350628334.png',
        'Communicating with healthcare provider infographic showing tips for effective medical communication',
        'https://img.rocket.new/generatedImages/rocket_gen_img_482332aaf-1792368871006.png',
        'https://www.youtube.com/watch?v=lJnPvsTvsyU',
        'https://kahoot.it/challenge/04107757?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788598632783')
) AS v(ord, title, description, category, thumbnail, alt, infographic, video, quiz)
WHERE NOT EXISTS (
    SELECT 1 FROM public.content_items c WHERE c.kind = 'session' AND c.title = v.title
)
ORDER BY v.ord;

NOTIFY pgrst, 'reload schema';
