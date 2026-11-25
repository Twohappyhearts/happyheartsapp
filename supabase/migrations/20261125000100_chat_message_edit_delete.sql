-- Editing and deleting Care Team chat messages (patient ⇄ research team).
--
-- In-place update + history: a message keeps its id; chat_messages holds its current text,
-- and before any change the earlier text is copied to chat_message_revisions (append-only).
--
--   edit     the sender, within 15 minutes of sending (database clock), not once deleted
--   delete   the sender, any time; Careteam/Admin may also remove a patient's message, with
--            a reason. The row stays as a tombstone: content '', deleted_at/by/role set.
--   restore  Admin: the text from before the deletion comes back.
--   purge    Admin, with a reason: the text is erased from the history too. Cannot be undone.
--   history  Careteam/Admin read earlier texts with chat_message_history(); every read, removal,
--            restore and purge is written to audit_log.
--
-- Clients still cannot UPDATE or DELETE chat_messages themselves (no RLS policy, and the
-- trigger below): only these functions can, by setting app.chat_message_write for their own
-- transaction. The removal reason is kept in the history only (staff-readable), not on the
-- message row the patient can read.

-- ---------------------------------------------------------------- message state

alter table public.chat_messages
    add column if not exists edited_at       timestamptz,
    add column if not exists deleted_at      timestamptz,
    add column if not exists deleted_by      uuid,
    add column if not exists deleted_by_role text,
    add column if not exists purged_at       timestamptz;

alter table public.chat_messages drop constraint if exists chat_messages_deleted_by_role_check;
alter table public.chat_messages add constraint chat_messages_deleted_by_role_check
    check (deleted_by_role is null or deleted_by_role in ('user', 'team'));

-- A deleted message has no text left.
alter table public.chat_messages drop constraint if exists chat_messages_content_length_check;
alter table public.chat_messages add constraint chat_messages_content_length_check
    check (deleted_at is not null or char_length(btrim(content)) between 1 and 5000) not valid;

comment on column public.chat_messages.edited_at is 'Last edit by the sender (null: never edited). Earlier texts: chat_message_revisions.';
comment on column public.chat_messages.deleted_at is 'Deleted (tombstone): content is empty; the text is in chat_message_revisions.';
comment on column public.chat_messages.deleted_by_role is 'Who deleted it: user (the patient) or team (Careteam/Admin, their own message or a removal).';

-- ---------------------------------------------------------------- history

create table if not exists public.chat_message_revisions (
    id              bigint generated always as identity primary key,
    message_id      uuid not null references public.chat_messages (id) on delete cascade,
    conversation_id uuid not null,
    action          text not null check (action in ('edit', 'delete', 'restore', 'purge')),
    -- The message text just before this action (null for restore/purge, or once purged).
    content         text,
    actor_id        uuid not null,
    actor_role      text not null,
    reason          text,
    created_at      timestamptz not null default now()
);
comment on table public.chat_message_revisions is
    'Append-only history of chat message edits and deletions. Read through chat_message_history() (Careteam/Admin).';

create index if not exists idx_chat_message_revisions_message on public.chat_message_revisions (message_id, id);

alter table public.chat_message_revisions enable row level security;
-- No policies: only the functions below read and write it.
revoke all on table public.chat_message_revisions from anon, authenticated;

-- Append-only: no update or delete, except a purge erasing texts, and rows going with their
-- message when an account or conversation is deleted (cascade).
create or replace function public.chat_message_revisions_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'UPDATE' and current_setting('app.chat_message_purge', true) = 'on' then
        return new;
    end if;
    if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
        return old;
    end if;
    raise exception 'chat_message_revisions is append-only';
end;
$$;

drop trigger if exists chat_message_revisions_no_change on public.chat_message_revisions;
create trigger chat_message_revisions_no_change
    before update or delete on public.chat_message_revisions
    for each row execute function public.chat_message_revisions_append_only();

-- ---------------------------------------------------------------- write guard

-- As before (sender, role, time and conversation are decided by the database), plus: an
-- UPDATE is allowed only from the functions below.
create or replace function public.enforce_chat_message_write()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
DECLARE
    v_uid UUID := auth.uid();
    v_role TEXT;
    v_active BOOLEAN;
    v_patient UUID;
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        IF v_uid IS NOT NULL AND pg_trigger_depth() <= 1
           AND NOT (TG_OP = 'UPDATE' AND current_setting('app.chat_message_write', true) = 'on') THEN
            RAISE EXCEPTION 'chat messages cannot be edited or deleted';
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;

    IF v_uid IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT ar.role, ar.is_active INTO v_role, v_active
    FROM public.account_roles ar WHERE ar.user_id = v_uid;

    IF v_role IS NULL OR v_active IS NOT TRUE THEN
        RAISE EXCEPTION 'account is not active';
    END IF;

    SELECT c.patient_id INTO v_patient
    FROM public.conversations c WHERE c.id = NEW.conversation_id;
    IF v_patient IS NULL THEN
        RAISE EXCEPTION 'conversation not found';
    END IF;

    IF v_role = 'patient' THEN
        IF v_patient <> v_uid THEN
            RAISE EXCEPTION 'patients may only write to their own conversation';
        END IF;
        NEW.sender_role := 'user';
    ELSIF v_role IN ('staff', 'admin') THEN
        NEW.sender_role := 'team';
    ELSE
        RAISE EXCEPTION 'unsupported role';
    END IF;

    NEW.sender_id := v_uid;
    NEW.user_id := v_patient;
    NEW.created_at := now();
    NEW.content := btrim(NEW.content);
    -- A new message is never born edited or deleted.
    NEW.edited_at := NULL;
    NEW.deleted_at := NULL;
    NEW.deleted_by := NULL;
    NEW.deleted_by_role := NULL;
    NEW.purged_at := NULL;
    RETURN NEW;
END;
$function$;

-- ---------------------------------------------------------------- helpers

-- The caller's active role (patient, staff, admin), else an error.
create or replace function public.chat_caller_role()
returns text
language plpgsql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_role text;
begin
    if auth.uid() is null then
        raise exception 'not authenticated' using errcode = '28000';
    end if;
    select ar.role into v_role from public.account_roles ar where ar.user_id = auth.uid() and ar.is_active;
    if v_role is null then
        raise exception 'account is not active' using errcode = '42501';
    end if;
    return v_role;
end;
$$;

-- Lock a message the caller can see (one of their conversations), else "not found".
create or replace function public.chat_lock_message(p_message_id uuid)
returns public.chat_messages
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_msg public.chat_messages;
begin
    select * into v_msg from public.chat_messages m where m.id = p_message_id for update;
    if not found or not public.can_access_conversation(v_msg.conversation_id) then
        raise exception 'message not found' using errcode = 'P0002';
    end if;
    return v_msg;
end;
$$;

-- ---------------------------------------------------------------- actions

-- Edit: the sender, within 15 minutes. Error codes: HC001 too late, HC002 deleted,
-- 23514 length, 42501 not the sender, P0002 not found.
create or replace function public.chat_edit_message(p_message_id uuid, p_content text)
returns public.chat_messages
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_uid  uuid := auth.uid();
    v_role text := public.chat_caller_role();
    v_text text := btrim(coalesce(p_content, ''));
    v_msg  public.chat_messages := public.chat_lock_message(p_message_id);
begin
    if v_msg.sender_id is distinct from v_uid then
        raise exception 'only the sender can edit a message' using errcode = '42501';
    end if;
    if v_msg.deleted_at is not null then
        raise exception 'message was deleted' using errcode = 'HC002';
    end if;
    if now() - v_msg.created_at > interval '15 minutes' then
        raise exception 'messages can only be edited within 15 minutes' using errcode = 'HC001';
    end if;
    if char_length(v_text) < 1 or char_length(v_text) > 5000 then
        raise exception 'message length' using errcode = '23514';
    end if;
    if v_text = v_msg.content then
        return v_msg;
    end if;

    insert into public.chat_message_revisions (message_id, conversation_id, action, content, actor_id, actor_role)
    values (v_msg.id, v_msg.conversation_id, 'edit', v_msg.content, v_uid, v_role);

    perform set_config('app.chat_message_write', 'on', true);
    update public.chat_messages m
    set content = v_text, edited_at = now()
    where m.id = v_msg.id
    returning * into v_msg;
    perform set_config('app.chat_message_write', 'off', true);
    return v_msg;
end;
$$;

-- Delete: the sender, any time; Careteam/Admin may remove a patient's message with a reason
-- (HC004 without one). Deleting a deleted message changes nothing.
create or replace function public.chat_delete_message(p_message_id uuid, p_reason text default null)
returns public.chat_messages
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_uid    uuid := auth.uid();
    v_role   text := public.chat_caller_role();
    v_msg    public.chat_messages := public.chat_lock_message(p_message_id);
    v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
    v_remove boolean := false;
begin
    if v_msg.deleted_at is not null then
        return v_msg;
    end if;
    if v_msg.sender_id is not distinct from v_uid then
        v_reason := null;
    elsif v_role in ('staff', 'admin') and v_msg.sender_role = 'user' then
        if v_reason is null or char_length(v_reason) > 500 then
            raise exception 'a reason (1-500 characters) is needed to remove a message' using errcode = 'HC004';
        end if;
        v_remove := true;
    else
        raise exception 'you cannot delete this message' using errcode = '42501';
    end if;

    insert into public.chat_message_revisions (message_id, conversation_id, action, content, actor_id, actor_role, reason)
    values (v_msg.id, v_msg.conversation_id, 'delete', v_msg.content, v_uid, v_role, v_reason);

    perform set_config('app.chat_message_write', 'on', true);
    update public.chat_messages m
    set content = '',
        deleted_at = now(),
        deleted_by = v_uid,
        deleted_by_role = case when v_role = 'patient' then 'user' else 'team' end
    where m.id = v_msg.id
    returning * into v_msg;
    perform set_config('app.chat_message_write', 'off', true);

    if v_remove then
        insert into public.audit_log (actor_id, actor_role, action, target_type, target_id, subject_user_id, details)
        values (v_uid, v_role, 'chat_message.remove', 'chat_message', v_msg.id, v_msg.user_id, jsonb_build_object('reason', v_reason));
    end if;
    return v_msg;
end;
$$;

-- Restore (Admin): the text from before the latest deletion. HC003 once purged.
create or replace function public.chat_restore_message(p_message_id uuid)
returns public.chat_messages
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_uid  uuid := auth.uid();
    v_role text := public.chat_caller_role();
    v_msg  public.chat_messages;
    v_text text;
begin
    if v_role <> 'admin' then
        raise exception 'only an Admin can restore a message' using errcode = '42501';
    end if;
    v_msg := public.chat_lock_message(p_message_id);
    if v_msg.deleted_at is null then
        return v_msg;
    end if;
    if v_msg.purged_at is not null then
        raise exception 'message was erased' using errcode = 'HC003';
    end if;
    select r.content into v_text
    from public.chat_message_revisions r
    where r.message_id = v_msg.id and r.action = 'delete'
    order by r.id desc
    limit 1;
    if v_text is null or btrim(v_text) = '' then
        raise exception 'message was erased' using errcode = 'HC003';
    end if;

    insert into public.chat_message_revisions (message_id, conversation_id, action, content, actor_id, actor_role)
    values (v_msg.id, v_msg.conversation_id, 'restore', null, v_uid, v_role);

    perform set_config('app.chat_message_write', 'on', true);
    update public.chat_messages m
    set content = v_text, deleted_at = null, deleted_by = null, deleted_by_role = null
    where m.id = v_msg.id
    returning * into v_msg;
    perform set_config('app.chat_message_write', 'off', true);

    insert into public.audit_log (actor_id, actor_role, action, target_type, target_id, subject_user_id, details)
    values (v_uid, v_role, 'chat_message.restore', 'chat_message', v_msg.id, v_msg.user_id, '{}'::jsonb);
    return v_msg;
end;
$$;

-- Purge (Admin, with a reason): the message is deleted if it is not yet, and its text is
-- erased from every earlier version. Cannot be undone.
create or replace function public.chat_purge_message(p_message_id uuid, p_reason text)
returns public.chat_messages
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
    v_uid    uuid := auth.uid();
    v_role   text := public.chat_caller_role();
    v_msg    public.chat_messages;
    v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
    if v_role <> 'admin' then
        raise exception 'only an Admin can erase a message' using errcode = '42501';
    end if;
    if v_reason is null or char_length(v_reason) > 500 then
        raise exception 'a reason (1-500 characters) is needed to erase a message' using errcode = 'HC004';
    end if;
    v_msg := public.chat_lock_message(p_message_id);
    if v_msg.purged_at is not null then
        return v_msg;
    end if;

    perform set_config('app.chat_message_purge', 'on', true);
    update public.chat_message_revisions r set content = null where r.message_id = v_msg.id;
    perform set_config('app.chat_message_purge', 'off', true);

    insert into public.chat_message_revisions (message_id, conversation_id, action, content, actor_id, actor_role, reason)
    values (v_msg.id, v_msg.conversation_id, 'purge', null, v_uid, v_role, v_reason);

    perform set_config('app.chat_message_write', 'on', true);
    update public.chat_messages m
    set content = '',
        purged_at = now(),
        deleted_at = coalesce(m.deleted_at, now()),
        deleted_by = coalesce(m.deleted_by, v_uid),
        deleted_by_role = coalesce(m.deleted_by_role, 'team')
    where m.id = v_msg.id
    returning * into v_msg;
    perform set_config('app.chat_message_write', 'off', true);

    insert into public.audit_log (actor_id, actor_role, action, target_type, target_id, subject_user_id, details)
    values (v_uid, v_role, 'chat_message.purge', 'chat_message', v_msg.id, v_msg.user_id, jsonb_build_object('reason', v_reason));
    return v_msg;
end;
$$;

-- History (Careteam/Admin): every earlier version, oldest first, with who changed it.
-- Each read is written to audit_log.
create or replace function public.chat_message_history(p_message_id uuid)
returns table (
    revision_id bigint,
    action      text,
    content     text,
    actor_id    uuid,
    actor_role  text,
    actor_name  text,
    reason      text,
    created_at  timestamptz
)
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
#variable_conflict use_column
declare
    v_role text := public.chat_caller_role();
    v_msg  public.chat_messages;
begin
    if v_role not in ('staff', 'admin') then
        raise exception 'only Careteam and Admin accounts can see message history' using errcode = '42501';
    end if;
    select * into v_msg from public.chat_messages m where m.id = p_message_id;
    if not found then
        raise exception 'message not found' using errcode = 'P0002';
    end if;

    insert into public.audit_log (actor_id, actor_role, action, target_type, target_id, subject_user_id, details)
    values (auth.uid(), v_role, 'chat_message.history.view', 'chat_message', v_msg.id, v_msg.user_id, '{}'::jsonb);

    return query
        select r.id,
               r.action,
               r.content,
               r.actor_id,
               r.actor_role,
               coalesce(nullif(btrim(p.display_id), ''), nullif(btrim(p.full_name), ''), '@' || p.username),
               r.reason,
               r.created_at
        from public.chat_message_revisions r
        left join public.profiles p on p.id = r.actor_id
        where r.message_id = v_msg.id
        order by r.id;
end;
$$;

-- ---------------------------------------------------------------- access

revoke all on function public.chat_caller_role() from public, anon, authenticated;
revoke all on function public.chat_lock_message(uuid) from public, anon, authenticated;

revoke all on function public.chat_edit_message(uuid, text) from public, anon;
revoke all on function public.chat_delete_message(uuid, text) from public, anon;
revoke all on function public.chat_restore_message(uuid) from public, anon;
revoke all on function public.chat_purge_message(uuid, text) from public, anon;
revoke all on function public.chat_message_history(uuid) from public, anon;

grant execute on function public.chat_edit_message(uuid, text) to authenticated;
grant execute on function public.chat_delete_message(uuid, text) to authenticated;
grant execute on function public.chat_restore_message(uuid) to authenticated;
grant execute on function public.chat_purge_message(uuid, text) to authenticated;
grant execute on function public.chat_message_history(uuid) to authenticated;
