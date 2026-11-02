-- Migration: Initial Schema
-- Creates all core tables, triggers, and indexes for Offline Vault.

-- Enable pgcrypto for random byte generation (invite codes, etc.)
create extension if not exists pgcrypto with schema extensions;

--------------------------------------------------------------------------------
-- PROFILES
--------------------------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  display_name text,
  email      text,
  avatar_url text,
  created_at timestamptz not null default now()
);

comment on table public.profiles is 'One row per auth user, created automatically on signup.';

--------------------------------------------------------------------------------
-- GROUPS
--------------------------------------------------------------------------------
create table if not exists public.groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  color      text not null default '#0F5C5A',
  owner_id   uuid not null references public.profiles on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.groups is 'Top-level container owned by a single user.';

--------------------------------------------------------------------------------
-- GROUP_MEMBERS
--------------------------------------------------------------------------------
create table if not exists public.group_members (
  group_id   uuid not null references public.groups on delete cascade,
  user_id    uuid not null references public.profiles on delete cascade,
  role       text not null check (role in ('owner', 'editor', 'viewer')),
  status     text not null default 'active' check (status in ('active', 'removed')),
  joined_at  timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

comment on table public.group_members is 'Membership join table linking users to groups.';

--------------------------------------------------------------------------------
-- INVITE_CODES
--------------------------------------------------------------------------------
create table if not exists public.invite_codes (
  code       text primary key check (code ~ '^[A-HJ-NP-Z2-9]{8}$'),
  group_id   uuid not null references public.groups on delete cascade,
  enabled    boolean not null default true,
  expires_at timestamptz,
  created_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.invite_codes is 'Short codes used to invite users to a group.';

-- At most one enabled code per group
create unique index if not exists uq_invite_codes_one_enabled_per_group
  on public.invite_codes (group_id) where (enabled = true);

--------------------------------------------------------------------------------
-- FOLDERS
--------------------------------------------------------------------------------
create table if not exists public.folders (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references public.groups on delete cascade,
  parent_id  uuid references public.folders on delete cascade,
  name       text not null,
  created_by uuid references public.profiles on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false
);

comment on table public.folders is 'Hierarchical folder structure within a group.';

--------------------------------------------------------------------------------
-- FILES
--------------------------------------------------------------------------------
create table if not exists public.files (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.groups on delete cascade,
  folder_id    uuid references public.folders on delete set null,
  name         text not null,
  note         text,
  mime_type    text not null,
  size_bytes   bigint not null,
  width        int,
  height       int,
  checksum     text not null,
  storage_path text not null,
  thumb_path   text,
  uploaded_by  uuid references public.profiles on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted      boolean not null default false
);

comment on table public.files is 'File metadata; actual blobs live in Supabase Storage.';

--------------------------------------------------------------------------------
-- JOIN_ATTEMPTS
--------------------------------------------------------------------------------
create table if not exists public.join_attempts (
  user_id      uuid,
  attempted_at timestamptz not null default now(),
  succeeded    boolean
);

comment on table public.join_attempts is 'Audit log of invite-code join attempts for rate-limiting.';

--------------------------------------------------------------------------------
-- INDEXES
--------------------------------------------------------------------------------
create index if not exists idx_folders_group_updated
  on public.folders (group_id, updated_at);

create index if not exists idx_files_group_updated
  on public.files (group_id, updated_at);

create index if not exists idx_group_members_user
  on public.group_members (user_id);

create index if not exists idx_invite_codes_group
  on public.invite_codes (group_id);

--------------------------------------------------------------------------------
-- TRIGGER: auto-create profile on auth.users insert
--------------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
  );
  return new;
end;
$$;

-- Drop and re-create trigger to be idempotent
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

--------------------------------------------------------------------------------
-- TRIGGER: auto-set updated_at on insert/update
--------------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := clock_timestamp();
  return new;
end;
$$;

-- groups
drop trigger if exists trg_groups_set_updated_at on public.groups;
create trigger trg_groups_set_updated_at
  before insert or update on public.groups
  for each row execute function public.set_updated_at();

-- group_members
drop trigger if exists trg_group_members_set_updated_at on public.group_members;
create trigger trg_group_members_set_updated_at
  before insert or update on public.group_members
  for each row execute function public.set_updated_at();

-- folders
drop trigger if exists trg_folders_set_updated_at on public.folders;
create trigger trg_folders_set_updated_at
  before insert or update on public.folders
  for each row execute function public.set_updated_at();

-- files
drop trigger if exists trg_files_set_updated_at on public.files;
create trigger trg_files_set_updated_at
  before insert or update on public.files
  for each row execute function public.set_updated_at();
