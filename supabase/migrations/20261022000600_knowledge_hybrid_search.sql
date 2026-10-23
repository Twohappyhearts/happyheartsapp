-- Hybrid retrieval: keyword top-N (Postgres full-text) + vector top-N (pgvector,
-- cosine), merged with Reciprocal Rank Fusion: score = Σ 1 / (k + rank).
-- The keyword half matches ANY query term (OR) and ts_rank rewards chunks that
-- match more of them — requiring every word (AND) misses natural-language questions.
-- Only committed chunks (c.generation = d.chunk_generation) of enabled
-- documents in enabled knowledge bases are searched — also while a document is
-- being re-chunked, its current chunks stay searchable.
-- Called by the server with the service role (after its own staff check, or by the AI agent).
create or replace function public.knowledge_hybrid_search(
    p_query text,
    p_embedding extensions.vector(1024),
    p_knowledge_base_ids uuid[] default null,
    p_keyword_k int default 20,
    p_vector_k int default 20,
    p_rrf_k int default 60,
    p_limit int default 20)
returns table (
    chunk_id uuid, document_id uuid, knowledge_base_id uuid, title text, chunk_index int,
    content text, search_text text, metadata jsonb,
    keyword_rank int, keyword_score real, vector_rank int, vector_similarity real, rrf_score double precision)
language plpgsql stable security definer
set search_path = public, extensions, pg_temp
as $$
declare
    kk int := greatest(0, least(coalesce(p_keyword_k, 20), 200));
    vk int := greatest(0, least(coalesce(p_vector_k, 20), 200));
    tsq tsquery;
begin
    -- Query terms (English stemming, stop words removed) joined with OR.
    select to_tsquery('simple', string_agg(quote_literal(l), ' | '))
      into tsq
      from unnest(tsvector_to_array(to_tsvector('english', coalesce(p_query, '')))) as l;
    if tsq is null then
        kk := 0;
    end if;

    -- Filters are applied after the HNSW scan; widen it so N results survive them.
    perform set_config('hnsw.ef_search', greatest(40, vk * 4)::text, true);
    perform set_config('hnsw.iterative_scan', 'relaxed_order', true);

    return query
    with kw as (
        select x.id, row_number() over (order by x.score desc, x.id)::int as rnk, x.score
        from (
            select c.id, ts_rank(c.search_fts, tsq)::real as score
            from public.knowledge_chunks c
            join public.knowledge_documents d on d.id = c.document_id and c.generation = d.chunk_generation
            join public.knowledge_bases kb on kb.id = d.knowledge_base_id
            where kk > 0 and c.search_fts @@ tsq
              and d.is_active and kb.is_active
              and (p_knowledge_base_ids is null or d.knowledge_base_id = any (p_knowledge_base_ids))
            order by score desc
            limit kk
        ) x
    ),
    vec as (
        select y.id, row_number() over (order by y.dist, y.id)::int as rnk, (1 - y.dist)::real as sim
        from (
            select c.id, c.embedding <=> p_embedding as dist
            from public.knowledge_chunks c
            join public.knowledge_documents d on d.id = c.document_id and c.generation = d.chunk_generation
            join public.knowledge_bases kb on kb.id = d.knowledge_base_id
            where vk > 0 and p_embedding is not null and c.embedding is not null
              and d.is_active and kb.is_active
              and (p_knowledge_base_ids is null or d.knowledge_base_id = any (p_knowledge_base_ids))
            order by c.embedding <=> p_embedding
            limit vk
        ) y
    ),
    fused as (
        select coalesce(kw.id, vec.id) as id,
               kw.rnk as k_rank, kw.score as k_score, vec.rnk as v_rank, vec.sim as v_sim,
               coalesce(1.0 / (p_rrf_k + kw.rnk), 0) + coalesce(1.0 / (p_rrf_k + vec.rnk), 0) as rrf
        from kw full outer join vec on kw.id = vec.id
    )
    select c.id, d.id, d.knowledge_base_id, d.title, c.chunk_index,
           c.content, coalesce(c.embedding_text, c.content), c.metadata,
           f.k_rank, f.k_score, f.v_rank, f.v_sim, f.rrf::double precision
    from fused f
    join public.knowledge_chunks c on c.id = f.id
    join public.knowledge_documents d on d.id = c.document_id
    order by f.rrf desc, f.v_rank nulls last, f.k_rank nulls last
    limit greatest(1, least(coalesce(p_limit, 20), 200));
end;
$$;
revoke all on function public.knowledge_hybrid_search(text, extensions.vector, uuid[], int, int, int, int) from public;
revoke all on function public.knowledge_hybrid_search(text, extensions.vector, uuid[], int, int, int, int) from anon;
revoke all on function public.knowledge_hybrid_search(text, extensions.vector, uuid[], int, int, int, int) from authenticated;
grant execute on function public.knowledge_hybrid_search(text, extensions.vector, uuid[], int, int, int, int) to service_role;

-- Keyword-only search: same visibility rule (committed chunks, also during a re-chunk).
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
    where c.search_fts @@ q and d.is_active and kb.is_active
      and (p_knowledge_base_id is null or d.knowledge_base_id = p_knowledge_base_id)
    order by ts_rank(c.search_fts, q) desc
    limit greatest(1, least(coalesce(p_limit, 10), 50));
end;
$$;
