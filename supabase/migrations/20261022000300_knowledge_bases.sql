-- Two levels: knowledge bases (collections) → documents → chunks.
create table public.knowledge_bases (
    id                  uuid primary key default gen_random_uuid(),
    name                text not null check (char_length(btrim(name)) between 1 and 100),
    -- Stable id the AI agent uses to pick a knowledge base, e.g. "patient_education".
    slug                text not null unique check (slug ~ '^[a-z][a-z0-9_]{1,49}$'),
    description         text not null default '' check (char_length(description) <= 1000),
    -- Set when vector search is switched on for this knowledge base.
    embedding_model     text check (embedding_model is null or char_length(embedding_model) <= 100),
    chunk_target_chars  int  not null default 1800 check (chunk_target_chars between 300 and 4000),
    chunk_overlap_chars int  not null default 300
        check (chunk_overlap_chars >= 0 and chunk_overlap_chars * 2 <= chunk_target_chars),
    is_active           boolean not null default true,
    created_by          uuid references auth.users(id) on delete set null,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);
create unique index knowledge_bases_name_key on public.knowledge_bases (lower(btrim(name)));
create trigger knowledge_bases_touch before update on public.knowledge_bases
    for each row execute function public.touch_updated_at();

alter table public.knowledge_bases enable row level security;
create policy knowledge_bases_staff_select on public.knowledge_bases
    for select to authenticated using (public.is_active_staff());

-- Existing documents go into a default knowledge base.
insert into public.knowledge_bases (name, slug, description)
values ('General', 'general', 'Default knowledge base.');

alter table public.knowledge_documents
    add column knowledge_base_id uuid references public.knowledge_bases(id) on delete cascade;
update public.knowledge_documents
   set knowledge_base_id = (select id from public.knowledge_bases where slug = 'general');
alter table public.knowledge_documents alter column knowledge_base_id set not null;
create index knowledge_documents_kb_idx on public.knowledge_documents (knowledge_base_id, created_at desc);

-- The same file may live in different knowledge bases, but only once per base.
alter table public.knowledge_documents drop constraint knowledge_documents_sha256_key;
alter table public.knowledge_documents
    add constraint knowledge_documents_kb_sha256_key unique (knowledge_base_id, sha256);

-- List page: one row per knowledge base with counts and owner.
create or replace function public.knowledge_base_overview()
returns table (
    id uuid, name text, slug text, description text, embedding_model text,
    chunk_target_chars int, chunk_overlap_chars int, is_active boolean,
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
           kb.chunk_target_chars, kb.chunk_overlap_chars, kb.is_active,
           p.username,
           kb.created_at,
           greatest(kb.updated_at, coalesce(max(d.updated_at), kb.updated_at)),
           count(d.id),
           count(d.id) filter (where d.status in ('uploaded', 'failed')),
           coalesce(sum(d.chunk_count) filter (where d.status = 'ready'), 0)::bigint
    from public.knowledge_bases kb
    left join public.profiles p on p.id = kb.created_by
    left join public.knowledge_documents d on d.knowledge_base_id = kb.id
    group by kb.id, p.username
    order by kb.created_at;
end;
$$;
revoke all on function public.knowledge_base_overview() from public, anon;
grant execute on function public.knowledge_base_overview() to authenticated;

-- Keyword search, optionally limited to one knowledge base.
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
           ts_rank(c.fts, q)::real
    from public.knowledge_chunks c
    join public.knowledge_documents d on d.id = c.document_id
    join public.knowledge_bases kb on kb.id = d.knowledge_base_id,
         websearch_to_tsquery('english', coalesce(p_query, '')) q
    where c.fts @@ q and d.is_active and d.status = 'ready' and kb.is_active
      and (p_knowledge_base_id is null or d.knowledge_base_id = p_knowledge_base_id)
    order by ts_rank(c.fts, q) desc
    limit greatest(1, least(coalesce(p_limit, 10), 50));
end;
$$;
revoke all on function public.knowledge_search_keyword(text, uuid, integer) from public, anon;
grant execute on function public.knowledge_search_keyword(text, uuid, integer) to authenticated;

-- Older unscoped search: superseded by knowledge_search_keyword; also respect
-- knowledge bases that are switched off.
create or replace function public.knowledge_keyword_search(p_query text, p_limit integer default 10)
returns table (chunk_id uuid, document_id uuid, title text, chunk_index integer,
               content text, metadata jsonb, rank real)
language sql stable security definer
set search_path = public, pg_temp
as $$
    select * from public.knowledge_search_keyword(p_query, null, p_limit);
$$;
