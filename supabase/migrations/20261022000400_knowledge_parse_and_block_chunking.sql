-- Pipeline: upload → parse (MinerU / built-in → Markdown + images) → chunk (block-aware) → [embed].

-- Documents: a parse step before chunking.
alter table public.knowledge_documents drop constraint knowledge_documents_status_check;
alter table public.knowledge_documents
  add constraint knowledge_documents_status_check
  check (status in ('uploaded', 'parsing', 'parsed', 'processing', 'ready', 'failed'));
alter table public.knowledge_documents
  add column if not exists parser text check (parser is null or parser in ('builtin', 'mineru')),
  add column if not exists parse_task_id text,
  add column if not exists parse_progress jsonb,
  add column if not exists parsed_path text,
  add column if not exists parsed_at timestamptz;
comment on column public.knowledge_documents.parsed_path is
  'Storage path of the parsed Markdown (images under <doc id>/assets/). Null until parsed.';

-- Knowledge bases: structure tolerance factor; defaults follow the block-aware chunker.
alter table public.knowledge_bases drop constraint knowledge_bases_chunk_target_chars_check;
alter table public.knowledge_bases
  add constraint knowledge_bases_chunk_target_chars_check check (chunk_target_chars between 200 and 8192);
alter table public.knowledge_bases
  add column if not exists chunk_tolerance_factor int not null default 3
    check (chunk_tolerance_factor between 1 and 8);
comment on column public.knowledge_bases.chunk_tolerance_factor is
  'A whole section / table / list / code block may grow to chunk size × this (capped at 8192 chars) instead of being split.';
alter table public.knowledge_bases alter column chunk_target_chars set default 1024;
alter table public.knowledge_bases alter column chunk_overlap_chars set default 128;
update public.knowledge_bases set chunk_target_chars = 1024, chunk_overlap_chars = 128
 where slug = 'general' and chunk_target_chars = 1800 and chunk_overlap_chars = 300;

-- Chunks: separate text for search/embedding (outline path + table "column: value" rows, no image URLs).
alter table public.knowledge_chunks drop constraint knowledge_chunks_content_check;
alter table public.knowledge_chunks
  add constraint knowledge_chunks_content_check check (char_length(content) between 1 and 32000);
alter table public.knowledge_chunks add column if not exists embedding_text text;
-- Keyword index over the search text (the older "fts" column over content is no longer used).
alter table public.knowledge_chunks
  add column if not exists search_fts tsvector
  generated always as (to_tsvector('english', coalesce(embedding_text, content))) stored;
create index if not exists knowledge_chunks_search_fts_idx on public.knowledge_chunks using gin (search_fts);

create or replace function public.knowledge_search_keyword(
    p_query text, p_knowledge_base_id uuid default null, p_limit integer default 10)
returns table (chunk_id uuid, document_id uuid, title text, chunk_index integer,
               content text, metadata jsonb, rank real)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
    if not public.is_active_staff() then
        raise exception 'staff only' using errcode = '42501';
    end if;
    return query
    select c.id, d.id, d.title, c.chunk_index, c.content, c.metadata,
           ts_rank(c.search_fts, q)::real
    from public.knowledge_chunks c
    join public.knowledge_documents d on d.id = c.document_id
    join public.knowledge_bases kb on kb.id = d.knowledge_base_id,
         websearch_to_tsquery('english', coalesce(p_query, '')) q
    where c.search_fts @@ q and d.is_active and d.status = 'ready' and kb.is_active
      and (p_knowledge_base_id is null or d.knowledge_base_id = p_knowledge_base_id)
    order by ts_rank(c.search_fts, q) desc
    limit greatest(1, least(coalesce(p_limit, 10), 50));
end;
$$;

-- List page: counts + tolerance factor ("not chunked" now also covers parsing / parsed).
create or replace function public.knowledge_base_list()
returns table (
    id uuid, name text, slug text, description text, embedding_model text,
    chunk_target_chars int, chunk_overlap_chars int, chunk_tolerance_factor int, is_active boolean,
    owner_username text, created_at timestamptz, updated_at timestamptz,
    document_count bigint, not_chunked_count bigint, chunk_count bigint
)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
    if not public.is_active_staff() then
        raise exception 'staff only' using errcode = '42501';
    end if;
    return query
    select kb.id, kb.name, kb.slug, kb.description, kb.embedding_model,
           kb.chunk_target_chars, kb.chunk_overlap_chars, kb.chunk_tolerance_factor, kb.is_active,
           p.username,
           kb.created_at,
           greatest(kb.updated_at, coalesce(max(d.updated_at), kb.updated_at)),
           count(d.id),
           count(d.id) filter (where d.status <> 'ready'),
           coalesce(sum(d.chunk_count) filter (where d.status = 'ready'), 0)::bigint
    from public.knowledge_bases kb
    left join public.profiles p on p.id = kb.created_by
    left join public.knowledge_documents d on d.knowledge_base_id = kb.id
    group by kb.id, p.username
    order by kb.created_at;
end;
$$;
revoke all on function public.knowledge_base_list() from public, anon;
grant execute on function public.knowledge_base_list() to authenticated;
-- (knowledge_base_overview from the previous migration is kept for compatibility; the dashboard uses knowledge_base_list.)

-- Storage: Office/PPT originals, parsed Markdown and extracted images; 50 MB per file.
update storage.buckets
   set file_size_limit = 52428800,
       allowed_mime_types = array[
         'application/pdf', 'text/plain', 'text/markdown',
         'application/msword',
         'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
         'application/vnd.ms-powerpoint',
         'application/vnd.openxmlformats-officedocument.presentationml.presentation',
         'image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/bmp'
       ]
 where id = 'knowledge';
