-- Embeddings + all-or-nothing chunk jobs.
-- A chunk job writes its rows under a new "generation". Only when every chunk
-- has its embedding does knowledge_commit_chunks() switch the document to that
-- generation (one UPDATE). Search reads only the committed generation, so a
-- failed job is invisible; the server deletes its rows and the document keeps
-- its previous chunks.

create extension if not exists vector with schema extensions;

alter table public.knowledge_chunks
  add column if not exists generation uuid,
  add column if not exists embedding extensions.vector(1024);
alter table public.knowledge_chunks drop constraint knowledge_chunks_document_id_chunk_index_key;
alter table public.knowledge_chunks
  add constraint knowledge_chunks_doc_generation_index_key unique (document_id, generation, chunk_index);
create index if not exists knowledge_chunks_embedding_hnsw
  on public.knowledge_chunks using hnsw (embedding extensions.vector_cosine_ops);

alter table public.knowledge_documents
  add column if not exists chunk_generation uuid,
  add column if not exists embedding_model text,
  add column if not exists pending_chunk_settings jsonb,
  add column if not exists job_progress jsonb;

create or replace function public.knowledge_commit_chunks(
    p_document_id uuid, p_generation uuid, p_expected_count int,
    p_settings jsonb, p_embedding_model text)
returns void
language plpgsql security definer
set search_path = public, extensions, pg_temp
as $$
declare
    n int;
    missing int;
    kb uuid;
begin
    select count(*), count(*) filter (where embedding is null)
      into n, missing
      from public.knowledge_chunks
     where document_id = p_document_id and generation = p_generation;
    if n = 0 or n <> p_expected_count then
        raise exception 'Expected % chunks, found %', p_expected_count, n;
    end if;
    if missing > 0 then
        raise exception '% chunks have no embedding', missing;
    end if;

    update public.knowledge_documents
       set chunk_generation = p_generation, status = 'ready', error = null,
           chunk_count = n, chunk_settings = p_settings, embedding_model = p_embedding_model,
           processed_at = now(), job_progress = null, pending_chunk_settings = null, parse_progress = null
     where id = p_document_id
    returning knowledge_base_id into kb;
    if kb is null then
        raise exception 'Document not found';
    end if;

    update public.knowledge_bases
       set embedding_model = p_embedding_model
     where id = kb and embedding_model is distinct from p_embedding_model;
end;
$$;
revoke all on function public.knowledge_commit_chunks(uuid, uuid, int, jsonb, text) from public;
revoke all on function public.knowledge_commit_chunks(uuid, uuid, int, jsonb, text) from anon;
revoke all on function public.knowledge_commit_chunks(uuid, uuid, int, jsonb, text) from authenticated;
grant execute on function public.knowledge_commit_chunks(uuid, uuid, int, jsonb, text) to service_role;

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
    join public.knowledge_documents d on d.id = c.document_id and c.generation = d.chunk_generation
    join public.knowledge_bases kb on kb.id = d.knowledge_base_id,
         websearch_to_tsquery('english', coalesce(p_query, '')) q
    where c.search_fts @@ q and d.is_active and d.status = 'ready' and kb.is_active
      and (p_knowledge_base_id is null or d.knowledge_base_id = p_knowledge_base_id)
    order by ts_rank(c.search_fts, q) desc
    limit greatest(1, least(coalesce(p_limit, 10), 50));
end;
$$;
