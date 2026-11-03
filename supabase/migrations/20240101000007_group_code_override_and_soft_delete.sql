-- Migration: Group Code Override (4 digits numeric) and Soft-Delete Cleanup
-- Phase 3 & Group Code Override

--------------------------------------------------------------------------------
-- 1. INVITE_CODES TABLE UPDATE
--------------------------------------------------------------------------------

-- Add id column if not exists
alter table public.invite_codes add column if not exists id uuid default gen_random_uuid();

-- Drop existing constraints
alter table public.invite_codes drop constraint if exists invite_codes_pkey cascade;
alter table public.invite_codes drop constraint if exists invite_codes_code_check cascade;
drop index if exists public.uq_invite_codes_one_enabled_per_group;

-- Set id as Primary Key
alter table public.invite_codes add primary key (id);

-- Enforce exactly 4 digits numeric (0000 to 9999)
alter table public.invite_codes add constraint invite_codes_code_check check (code ~ '^[0-9]{4}$');

-- Partial unique index on (code) where enabled = true (allows code reuse once disabled/expired)
create unique index if not exists uq_invite_codes_code_enabled
  on public.invite_codes (code) where (enabled = true);

create index if not exists idx_invite_codes_group_enabled
  on public.invite_codes (group_id) where (enabled = true);

--------------------------------------------------------------------------------
-- 2. GROUPS TABLE: require_approval column
--------------------------------------------------------------------------------
alter table public.groups add column if not exists require_approval boolean not null default false;

--------------------------------------------------------------------------------
-- 3. GENERATE_INVITE_CODE: 4 DIGITS NUMERIC WITHOUT MODULO BIAS
--------------------------------------------------------------------------------
create or replace function public.generate_invite_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  raw_bytes bytea;
  num int;
  candidate text;
  attempts int := 0;
begin
  loop
    attempts := attempts + 1;
    if attempts > 100 then
      raise exception 'Unable to generate unique invite code';
    end if;

    -- Disable any expired codes so their codes can be reused immediately
    update public.invite_codes
    set enabled = false
    where enabled = true
      and expires_at is not null
      and expires_at < now();

    raw_bytes := extensions.gen_random_bytes(2);
    -- 0 to 65535, reject >= 60000 to avoid modulo bias when mapping to 0..9999
    num := ((get_byte(raw_bytes, 0) << 8) | get_byte(raw_bytes, 1));
    if num < 60000 then
      candidate := lpad((num % 10000)::text, 4, '0');
      -- Check if code is currently in use by an enabled code
      if not exists (
        select 1
        from public.invite_codes
        where code = candidate
          and enabled = true
      ) then
        return candidate;
      end if;
    end if;
  end loop;
end;
$$;

comment on function public.generate_invite_code() is
  'Generates a cryptographically random 4-digit code (0000-9999) without modulo bias, retrying until unused.';

--------------------------------------------------------------------------------
-- 4. ROTATE_INVITE_CODE: 4 DIGITS & EXPIRY (1h, 24h, 7d, default 24h)
--------------------------------------------------------------------------------
create or replace function public.rotate_invite_code(
  p_group_id   uuid,
  p_expires_in interval default interval '24 hours'
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := auth.uid();
  v_code     text;
  v_exp      timestamptz;
  v_duration interval;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_owner(p_group_id) then
    raise exception 'Only the group owner can rotate the invite code.';
  end if;

  -- Disable expired codes across the board
  update public.invite_codes
  set enabled = false
  where enabled = true
    and expires_at is not null
    and expires_at < now();

  -- Disable currently enabled code for this group
  update public.invite_codes
  set enabled = false
  where group_id = p_group_id
    and enabled  = true;

  -- Default is 24 hours. Remove "Never" option.
  v_duration := coalesce(p_expires_in, interval '24 hours');
  v_exp := now() + v_duration;

  -- Generate and insert new 4-digit code
  v_code := public.generate_invite_code();
  insert into public.invite_codes (id, code, group_id, enabled, expires_at, created_by)
  values (gen_random_uuid(), v_code, p_group_id, true, v_exp, v_uid);

  return v_code;
end;
$$;

--------------------------------------------------------------------------------
-- 5. CREATE_GROUP WITH 4-DIGIT CODE AND 24H EXPIRY
--------------------------------------------------------------------------------
create or replace function public.create_group(
  p_name  text,
  p_color text default '#0F5C5A'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_group public.groups;
  v_code  text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Create the group
  insert into public.groups (name, color, owner_id)
  values (p_name, p_color, v_uid)
  returning * into v_group;

  -- Add creator as owner
  insert into public.group_members (group_id, user_id, role, status)
  values (v_group.id, v_uid, 'owner', 'active');

  -- Disable expired codes
  update public.invite_codes
  set enabled = false
  where enabled = true
    and expires_at is not null
    and expires_at < now();

  -- Generate initial 4-digit invite code with 24h default expiry
  v_code := public.generate_invite_code();
  insert into public.invite_codes (id, code, group_id, enabled, expires_at, created_by)
  values (gen_random_uuid(), v_code, v_group.id, true, now() + interval '24 hours', v_uid);

  return jsonb_build_object(
    'group', row_to_json(v_group),
    'code',  v_code
  );
end;
$$;

--------------------------------------------------------------------------------
-- 6. JOIN_GROUP: THROTTLE, 4 DIGITS, APPROVAL SUPPORT
--------------------------------------------------------------------------------
create or replace function public.join_group(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid          uuid := auth.uid();
  v_code         text;
  v_invite       public.invite_codes;
  v_existing     public.group_members;
  v_user_fails   int;
  v_global_fails int;
  v_req_approval boolean;
  v_status       text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Strip all whitespace
  v_code := regexp_replace(coalesce(p_code, ''), '\s+', '', 'g');

  -- Throttles check:
  -- 1. Global throttle: at most 200 failed attempts across all users per hour
  select count(*) into v_global_fails
  from public.join_attempts
  where succeeded = false
    and attempted_at > now() - interval '1 hour';

  if v_global_fails >= 200 then
    raise exception 'Joining groups is temporarily paused. Please try again later.';
  end if;

  -- 2. User throttle: at most 5 failed attempts per user per hour
  select count(*) into v_user_fails
  from public.join_attempts
  where user_id = v_uid
    and succeeded = false
    and attempted_at > now() - interval '1 hour';

  if v_user_fails >= 5 then
    raise exception 'Too many failed attempts. Please try again in an hour.';
  end if;

  -- Expired codes are treated as disabled
  update public.invite_codes
  set enabled = false
  where enabled = true
    and expires_at is not null
    and expires_at < now();

  -- Must be exactly 4 digits
  if v_code !~ '^[0-9]{4}$' then
    insert into public.join_attempts (user_id, succeeded)
    values (v_uid, false);
    raise exception 'Invalid or expired invite code.';
  end if;

  -- Look up invite code
  select * into v_invite
  from public.invite_codes
  where code = v_code
    and enabled = true
    and (expires_at is null or expires_at > now());

  -- Wrong, disabled and expired codes return the exact same error text
  if v_invite.code is null then
    insert into public.join_attempts (user_id, succeeded)
    values (v_uid, false);
    raise exception 'Invalid or expired invite code.';
  end if;

  -- Check if user was previously removed from this group
  select * into v_existing
  from public.group_members
  where group_id = v_invite.group_id
    and user_id  = v_uid;

  if v_existing.group_id is not null then
    if v_existing.status = 'removed' then
      -- A removed member cannot rejoin with a code
      insert into public.join_attempts (user_id, succeeded)
      values (v_uid, false);
      raise exception 'You have been removed from this group.';
    end if;

    -- Already a member
    insert into public.join_attempts (user_id, succeeded)
    values (v_uid, true);

    return jsonb_build_object(
      'group_id', v_existing.group_id,
      'status',   v_existing.status
    );
  end if;

  -- Check require_approval
  select coalesce(require_approval, false) into v_req_approval
  from public.groups
  where id = v_invite.group_id;

  v_status := case when v_req_approval then 'pending' else 'active' end;

  insert into public.group_members (group_id, user_id, role, status)
  values (v_invite.group_id, v_uid, 'viewer', v_status);

  insert into public.join_attempts (user_id, succeeded)
  values (v_uid, true);

  return jsonb_build_object(
    'group_id', v_invite.group_id,
    'status',   v_status
  );
end;
$$;

--------------------------------------------------------------------------------
-- 7. APPROVE_MEMBER & DECLINE_MEMBER RPCs
--------------------------------------------------------------------------------
create or replace function public.approve_member(
  p_group_id uuid,
  p_user_id  uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_owner(p_group_id) then
    raise exception 'Only the group owner can approve members.';
  end if;

  update public.group_members
  set status = 'active'
  where group_id = p_group_id
    and user_id  = p_user_id
    and status   = 'pending';

  if not found then
    raise exception 'Pending member not found.';
  end if;
end;
$$;

create or replace function public.decline_member(
  p_group_id uuid,
  p_user_id  uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_owner(p_group_id) then
    raise exception 'Only the group owner can decline members.';
  end if;

  delete from public.group_members
  where group_id = p_group_id
    and user_id  = p_user_id
    and status   = 'pending';

  if not found then
    raise exception 'Pending member not found.';
  end if;
end;
$$;

--------------------------------------------------------------------------------
-- 8. PURGE_SOFT_DELETED_RECORDS (CLEANUP FOR RECORDS OLDER THAN 30 DAYS)
--------------------------------------------------------------------------------
create or replace function public.purge_soft_deleted_records(p_retention_days int default 30)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted_files int := 0;
  v_deleted_folders int := 0;
  v_threshold timestamptz := now() - (p_retention_days || ' days')::interval;
begin
  with del_files as (
    delete from public.files
    where deleted = true
      and updated_at < v_threshold
    returning id
  )
  select count(*) into v_deleted_files from del_files;

  with del_folders as (
    delete from public.folders
    where deleted = true
      and updated_at < v_threshold
    returning id
  )
  select count(*) into v_deleted_folders from del_folders;

  return jsonb_build_object(
    'deleted_files', v_deleted_files,
    'deleted_folders', v_deleted_folders
  );
end;
$$;
