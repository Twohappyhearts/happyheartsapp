-- ============================================================================
-- Knowledge base for the AI assistant (RAG) — step 1: documents + chunks
--
-- * Original files live in the private Storage bucket "knowledge".
-- * knowledge_documents: one row per uploaded file (status, counts, active).
-- * knowledge_chunks: extracted text split into overlapping chunks, with a
--   generated full-text column (keyword search). The embedding column is
--   added in the next step, once the embedding model is chosen.
-- * Staff manage everything through dashboard server routes (secret key);
--   staff can read via RLS for the dashboard UI. Patients never read these
--   tables directly — the agent server queries them on their behalf.
-- ============================================================================

-- Private bucket, 20 MB per file, document types only.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'knowledge', 'knowledge', false, 20971520,
    ARRAY[
        'application/pdf',
        'text/plain',
        'text/markdown',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.knowledge_documents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title         TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
    description   TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 1000),
    source_type   TEXT NOT NULL DEFAULT 'upload' CHECK (source_type IN ('upload', 'lesson')),
    content_id    UUID REFERENCES public.content_items(id) ON DELETE CASCADE,
    file_name     TEXT,
    storage_path  TEXT UNIQUE,
    mime_type     TEXT,
    size_bytes    BIGINT CHECK (size_bytes IS NULL OR size_bytes >= 0),
    sha256        TEXT UNIQUE,
    status        TEXT NOT NULL DEFAULT 'processing'
                  CHECK (status IN ('processing', 'ready', 'failed')),
    error         TEXT,
    page_count    INTEGER,
    char_count    INTEGER,
    chunk_count   INTEGER NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    uploaded_by   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.knowledge_chunks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id  UUID NOT NULL REFERENCES public.knowledge_documents(id) ON DELETE CASCADE,
    chunk_index  INTEGER NOT NULL CHECK (chunk_index >= 0),
    content      TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 8000),
    token_count  INTEGER NOT NULL DEFAULT 0,
    metadata     JSONB NOT NULL DEFAULT '{}'::jsonb,
    fts          TSVECTOR GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (document_id, chunk_index)
);

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_fts ON public.knowledge_chunks USING gin (fts);
CREATE INDEX IF NOT EXISTS idx_knowledge_documents_created ON public.knowledge_documents (created_at DESC);

CREATE TRIGGER trg_knowledge_documents_touch
    BEFORE UPDATE ON public.knowledge_documents
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.knowledge_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.knowledge_documents, public.knowledge_chunks FROM anon, authenticated;
GRANT SELECT ON public.knowledge_documents, public.knowledge_chunks TO authenticated;

CREATE POLICY "knowledge_documents_select_staff" ON public.knowledge_documents
    FOR SELECT TO authenticated USING (public.is_active_staff());
CREATE POLICY "knowledge_chunks_select_staff" ON public.knowledge_chunks
    FOR SELECT TO authenticated USING (public.is_active_staff());

-- Staff keyword test search (the agent will use a hybrid version later).
CREATE OR REPLACE FUNCTION public.knowledge_keyword_search(p_query TEXT, p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    chunk_id    UUID,
    document_id UUID,
    title       TEXT,
    chunk_index INTEGER,
    content     TEXT,
    metadata    JSONB,
    rank        REAL
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
    SELECT c.id, d.id, d.title, c.chunk_index, c.content, c.metadata,
           ts_rank(c.fts, q)::real
    FROM public.knowledge_chunks c
    JOIN public.knowledge_documents d ON d.id = c.document_id,
         websearch_to_tsquery('english', coalesce(p_query, '')) q
    WHERE c.fts @@ q AND d.is_active AND d.status = 'ready'
    ORDER BY ts_rank(c.fts, q) DESC
    LIMIT greatest(1, least(coalesce(p_limit, 10), 50));
END;
$$;
REVOKE ALL ON FUNCTION public.knowledge_keyword_search(TEXT, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.knowledge_keyword_search(TEXT, INTEGER) TO authenticated;
