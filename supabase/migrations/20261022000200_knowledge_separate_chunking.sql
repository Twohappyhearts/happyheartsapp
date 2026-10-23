-- Upload and chunking are separate steps: an upload is stored as 'uploaded'
-- and chunked later (one by one or in batches) with chosen settings.
alter table public.knowledge_documents drop constraint knowledge_documents_status_check;
alter table public.knowledge_documents
  add constraint knowledge_documents_status_check
  check (status in ('uploaded', 'processing', 'ready', 'failed'));
alter table public.knowledge_documents alter column status set default 'uploaded';

alter table public.knowledge_documents
  add column if not exists chunk_settings jsonb,
  add column if not exists processed_at timestamptz;

comment on column public.knowledge_documents.chunk_settings is
  'Settings used for the current chunks, e.g. {"target_chars":1800,"overlap_chars":300}.';
