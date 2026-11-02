-- Migration: Storage Bucket & Policies
-- Creates the private `vault` bucket and applies access policies.

--------------------------------------------------------------------------------
-- Create the vault bucket (private, 25 MB limit)
--------------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'vault',
  'vault',
  false,
  26214400,  -- 25 MiB in bytes
  array[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/avif',
    'image/svg+xml',
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'application/pdf',
    'application/zip'
  ]
)
on conflict (id) do update set
  file_size_limit    = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

--------------------------------------------------------------------------------
-- Helper: extract group_id (first path segment) from storage path
-- Storage paths follow: <group_id>/originals/... or <group_id>/thumbs/...
--------------------------------------------------------------------------------

-- SELECT: members can read objects belonging to their groups
drop policy if exists "vault_select_member" on storage.objects;
create policy "vault_select_member" on storage.objects
  for select using (
    bucket_id = 'vault'
    and public.is_member((storage.foldername(name))[1]::uuid)
  );

-- INSERT: writers can upload to originals/ or thumbs/ subdirectories
drop policy if exists "vault_insert_writer" on storage.objects;
create policy "vault_insert_writer" on storage.objects
  for insert with check (
    bucket_id = 'vault'
    and public.can_write((storage.foldername(name))[1]::uuid)
    and (
      (storage.foldername(name))[2] = 'originals'
      or (storage.foldername(name))[2] = 'thumbs'
    )
  );

-- UPDATE: writers can update objects in their groups
drop policy if exists "vault_update_writer" on storage.objects;
create policy "vault_update_writer" on storage.objects
  for update using (
    bucket_id = 'vault'
    and public.can_write((storage.foldername(name))[1]::uuid)
  ) with check (
    bucket_id = 'vault'
    and public.can_write((storage.foldername(name))[1]::uuid)
  );

-- DELETE: writers can delete objects in their groups
drop policy if exists "vault_delete_writer" on storage.objects;
create policy "vault_delete_writer" on storage.objects
  for delete using (
    bucket_id = 'vault'
    and public.can_write((storage.foldername(name))[1]::uuid)
  );
