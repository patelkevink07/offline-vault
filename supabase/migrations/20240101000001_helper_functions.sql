-- Migration: Helper Functions
-- Reusable SECURITY DEFINER helpers for membership checks, used by RLS policies.

--------------------------------------------------------------------------------
-- is_member: true if the current user is an active member of the group
--------------------------------------------------------------------------------
create or replace function public.is_member(gid uuid)
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

comment on function public.is_member(uuid) is
  'Returns true when the calling user is an active member of the given group.';

--------------------------------------------------------------------------------
-- can_write: true if the current user is an active owner or editor
--------------------------------------------------------------------------------
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
      and role in ('owner', 'editor')
  );
$$;

comment on function public.can_write(uuid) is
  'Returns true when the calling user can modify content in the given group (owner or editor).';

--------------------------------------------------------------------------------
-- is_owner: true if the current user is the active owner
--------------------------------------------------------------------------------
create or replace function public.is_owner(gid uuid)
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
      and role     = 'owner'
  );
$$;

comment on function public.is_owner(uuid) is
  'Returns true when the calling user is the owner of the given group.';
