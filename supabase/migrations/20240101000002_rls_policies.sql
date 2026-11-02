-- Migration: Row Level Security Policies
-- Enables RLS on every table and defines granular access policies.

--------------------------------------------------------------------------------
-- Enable RLS on all tables
--------------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.invite_codes  enable row level security;
alter table public.folders       enable row level security;
alter table public.files         enable row level security;
alter table public.join_attempts enable row level security;

--------------------------------------------------------------------------------
-- PROFILES
--------------------------------------------------------------------------------

-- Users can read their own profile
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid());

-- Users can update their own profile
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

--------------------------------------------------------------------------------
-- GROUPS
--------------------------------------------------------------------------------

-- Members can read groups they belong to
drop policy if exists "groups_select_member" on public.groups;
create policy "groups_select_member" on public.groups
  for select using (public.is_member(id));

-- Only owner can update a group
drop policy if exists "groups_update_owner" on public.groups;
create policy "groups_update_owner" on public.groups
  for update using (public.is_owner(id)) with check (public.is_owner(id));

-- Only owner can delete a group
drop policy if exists "groups_delete_owner" on public.groups;
create policy "groups_delete_owner" on public.groups
  for delete using (public.is_owner(id));

-- No direct inserts (groups are created via RPC)

--------------------------------------------------------------------------------
-- GROUP_MEMBERS
--------------------------------------------------------------------------------

-- Users can ALWAYS see their own membership rows (including removed)
drop policy if exists "gm_select_own" on public.group_members;
create policy "gm_select_own" on public.group_members
  for select using (user_id = auth.uid());

-- Active members can see other members' rows in their groups
drop policy if exists "gm_select_peers" on public.group_members;
create policy "gm_select_peers" on public.group_members
  for select using (public.is_member(group_id));

-- Owner can update member rows (but cannot modify their own owner row via this policy)
drop policy if exists "gm_update_owner" on public.group_members;
create policy "gm_update_owner" on public.group_members
  for update using (
    public.is_owner(group_id)
    and not (user_id = auth.uid() and role = 'owner')
  ) with check (
    public.is_owner(group_id)
  );

-- A member can update ONLY their own row and ONLY to set status = 'removed' (leave)
drop policy if exists "gm_update_self_leave" on public.group_members;
create policy "gm_update_self_leave" on public.group_members
  for update using (
    user_id = auth.uid()
    and role <> 'owner'  -- owners cannot leave their own group this way
  ) with check (
    user_id = auth.uid()
    and status = 'removed'
  );

-- No direct inserts or deletes on group_members

--------------------------------------------------------------------------------
-- FOLDERS
--------------------------------------------------------------------------------

-- Members can read folders in their groups
drop policy if exists "folders_select_member" on public.folders;
create policy "folders_select_member" on public.folders
  for select using (public.is_member(group_id));

-- Writers can insert folders
drop policy if exists "folders_insert_writer" on public.folders;
create policy "folders_insert_writer" on public.folders
  for insert with check (public.can_write(group_id));

-- Writers can update folders
drop policy if exists "folders_update_writer" on public.folders;
create policy "folders_update_writer" on public.folders
  for update using (public.can_write(group_id)) with check (public.can_write(group_id));

-- No hard deletes on folders

--------------------------------------------------------------------------------
-- FILES
--------------------------------------------------------------------------------

-- Members can read files in their groups
drop policy if exists "files_select_member" on public.files;
create policy "files_select_member" on public.files
  for select using (public.is_member(group_id));

-- Writers can insert files
drop policy if exists "files_insert_writer" on public.files;
create policy "files_insert_writer" on public.files
  for insert with check (public.can_write(group_id));

-- Writers can update files
drop policy if exists "files_update_writer" on public.files;
create policy "files_update_writer" on public.files
  for update using (public.can_write(group_id)) with check (public.can_write(group_id));

-- No hard deletes on files

--------------------------------------------------------------------------------
-- INVITE_CODES — no direct client access at all
--------------------------------------------------------------------------------

-- Deny everything: no policies means RLS blocks all access.
-- (RLS is enabled above, and no permissive policies are created.)

--------------------------------------------------------------------------------
-- JOIN_ATTEMPTS
--------------------------------------------------------------------------------

-- Users can insert their own rows
drop policy if exists "ja_insert_own" on public.join_attempts;
create policy "ja_insert_own" on public.join_attempts
  for insert with check (user_id = auth.uid());

-- Users can read their own rows
drop policy if exists "ja_select_own" on public.join_attempts;
create policy "ja_select_own" on public.join_attempts
  for select using (user_id = auth.uid());
