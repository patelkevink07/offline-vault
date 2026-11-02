-- Migration: RPC Functions
-- Server-side functions callable by authenticated clients.

--------------------------------------------------------------------------------
-- Internal helper: generate an 8-char invite code from the 32-char alphabet
-- Alphabet: ABCDEFGHJKLMNPQRSTUVWXYZ23456789  (no 0, O, 1, I, L)
-- 32 = 2^5, so we use the low 5 bits of each random byte — no modulo bias.
--------------------------------------------------------------------------------
create or replace function public.generate_invite_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  raw_bytes bytea;
  code text := '';
  i int;
begin
  raw_bytes := extensions.gen_random_bytes(8);
  for i in 0..7 loop
    -- Use low 5 bits (0-31) → index into 32-char alphabet
    code := code || substr(alphabet, (get_byte(raw_bytes, i) & 31) + 1, 1);
  end loop;
  return code;
end;
$$;

comment on function public.generate_invite_code() is
  'Generates a cryptographically random 8-char invite code with no modulo bias.';

--------------------------------------------------------------------------------
-- create_group(p_name, p_color)
-- Creates a group, owner membership, and initial invite code in one TX.
-- Returns a JSON object with the group row and the generated code.
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

  -- Add owner as a member
  insert into public.group_members (group_id, user_id, role, status)
  values (v_group.id, v_uid, 'owner', 'active');

  -- Generate and insert the invite code
  v_code := public.generate_invite_code();
  insert into public.invite_codes (code, group_id, enabled, created_by)
  values (v_code, v_group.id, true, v_uid);

  return jsonb_build_object(
    'group', row_to_json(v_group)::jsonb,
    'code',  v_code
  );
end;
$$;

comment on function public.create_group(text, text) is
  'Creates a new group with the caller as owner, including an initial invite code.';

--------------------------------------------------------------------------------
-- join_group(p_code)
-- Validates the code, applies rate-limiting, and inserts a viewer membership.
--------------------------------------------------------------------------------
create or replace function public.join_group(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid         uuid := auth.uid();
  v_code        text;
  v_invite      public.invite_codes;
  v_fail_count  int;
  v_existing    public.group_members;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Normalise: upper-case, strip dashes and spaces
  v_code := upper(regexp_replace(p_code, '[\s\-]', '', 'g'));

  -- Rate-limit: max 10 failed attempts per user per hour
  select count(*) into v_fail_count
  from public.join_attempts
  where user_id = v_uid
    and succeeded = false
    and attempted_at > now() - interval '1 hour';

  if v_fail_count >= 10 then
    raise exception 'Too many failed attempts. Please try again later.';
  end if;

  -- Look up the code
  select * into v_invite
  from public.invite_codes
  where code = v_code;

  -- Validate: same generic error for wrong / disabled / expired
  if v_invite.code is null
     or v_invite.enabled = false
     or (v_invite.expires_at is not null and v_invite.expires_at < now())
  then
    -- Record failed attempt
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
      raise exception 'You have been removed from this group.';
    end if;

    -- Already an active member — record success and return
    insert into public.join_attempts (user_id, succeeded)
    values (v_uid, true);

    return jsonb_build_object(
      'group_id', v_existing.group_id,
      'status',   'already_member'
    );
  end if;

  -- Insert new viewer membership
  insert into public.group_members (group_id, user_id, role, status)
  values (v_invite.group_id, v_uid, 'viewer', 'active');

  -- Record successful attempt
  insert into public.join_attempts (user_id, succeeded)
  values (v_uid, true);

  return jsonb_build_object(
    'group_id', v_invite.group_id,
    'status',   'joined'
  );
end;
$$;

comment on function public.join_group(text) is
  'Joins a group using an invite code. Rate-limited to 10 failed attempts per hour.';

--------------------------------------------------------------------------------
-- rotate_invite_code(p_group_id, p_expires_in)
-- Owner only. Disables current code, creates a new one.
--------------------------------------------------------------------------------
create or replace function public.rotate_invite_code(
  p_group_id   uuid,
  p_expires_in interval default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_code text;
  v_exp  timestamptz;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_owner(p_group_id) then
    raise exception 'Only the group owner can rotate the invite code.';
  end if;

  -- Disable all currently enabled codes for this group
  update public.invite_codes
  set enabled = false
  where group_id = p_group_id
    and enabled  = true;

  -- Calculate expiration
  if p_expires_in is not null then
    v_exp := now() + p_expires_in;
  end if;

  -- Generate and insert the new code
  v_code := public.generate_invite_code();
  insert into public.invite_codes (code, group_id, enabled, expires_at, created_by)
  values (v_code, p_group_id, true, v_exp, v_uid);

  return v_code;
end;
$$;

comment on function public.rotate_invite_code(uuid, interval) is
  'Disables the current invite code and generates a new one. Owner only.';

--------------------------------------------------------------------------------
-- set_invite_code_state(p_group_id, p_enabled, p_expires_at)
-- Owner only. Enables/disables the current code and optionally sets expiry.
--------------------------------------------------------------------------------
create or replace function public.set_invite_code_state(
  p_group_id   uuid,
  p_enabled    boolean,
  p_expires_at timestamptz default null
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
    raise exception 'Only the group owner can modify invite code state.';
  end if;

  -- When enabling, we update the most recently created code for this group.
  -- When disabling, we disable all codes for this group.
  if p_enabled then
    -- First disable any currently enabled code (to satisfy unique index)
    update public.invite_codes
    set enabled = false
    where group_id = p_group_id
      and enabled  = true;

    -- Enable the most recent code
    update public.invite_codes
    set enabled    = true,
        expires_at = p_expires_at
    where code = (
      select code
      from public.invite_codes
      where group_id = p_group_id
      order by created_at desc
      limit 1
    );
  else
    update public.invite_codes
    set enabled    = false,
        expires_at = p_expires_at
    where group_id = p_group_id
      and enabled  = true;
  end if;
end;
$$;

comment on function public.set_invite_code_state(uuid, boolean, timestamptz) is
  'Enables or disables the invite code for a group. Owner only.';

--------------------------------------------------------------------------------
-- get_invite_code(p_group_id)
-- Owner only. Returns the current enabled code (if any).
--------------------------------------------------------------------------------
create or replace function public.get_invite_code(p_group_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_code text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_owner(p_group_id) then
    raise exception 'Only the group owner can view the invite code.';
  end if;

  select code into v_code
  from public.invite_codes
  where group_id = p_group_id
    and enabled  = true
  limit 1;

  return v_code;
end;
$$;

comment on function public.get_invite_code(uuid) is
  'Returns the current enabled invite code for a group. Owner only.';
