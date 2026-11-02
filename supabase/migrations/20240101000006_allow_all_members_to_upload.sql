-- Migration: Allow all group members to upload documents
-- 1. Update can_write helper so all active members (owner, editor, viewer) can upload and edit files
create or replace function public.can_write(gid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.group_members
    where group_id = gid
      and user_id  = auth.uid()
      and status   = 'active'
  );
$$;

comment on function public.can_write(uuid) is
  'Returns true when the calling user is an active member who can upload/modify content in the group.';

-- 2. Update join_group to assign 'editor' role by default so joined members have upload privileges
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
  v_group       public.groups;
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

    -- Already an active member
    insert into public.join_attempts (user_id, succeeded)
    values (v_uid, true);

    select * into v_group from public.groups where id = v_existing.group_id;

    return jsonb_build_object(
      'group', row_to_json(v_group)::jsonb,
      'status', 'already_member'
    );
  end if;

  -- Insert new editor membership so member can share photos/documents
  insert into public.group_members (group_id, user_id, role, status)
  values (v_invite.group_id, v_uid, 'editor', 'active');

  -- Record successful attempt
  insert into public.join_attempts (user_id, succeeded)
  values (v_uid, true);

  select * into v_group from public.groups where id = v_invite.group_id;

  return jsonb_build_object(
    'group', row_to_json(v_group)::jsonb,
    'status', 'joined'
  );
end;
$$;
