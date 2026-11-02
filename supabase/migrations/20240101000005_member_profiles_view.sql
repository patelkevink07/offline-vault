-- Migration: Group Member Profiles View
-- Provides a safe view of member profiles (display_name, avatar_url only)
-- secured through the underlying group_members RLS policies.

create or replace view public.group_member_profiles as
select
  gm.group_id,
  gm.user_id,
  gm.role,
  gm.status,
  gm.joined_at,
  p.display_name,
  p.avatar_url
from public.group_members gm
join public.profiles p on p.id = gm.user_id;

comment on view public.group_member_profiles is
  'Read-only view joining group_members with profiles. Exposes display_name and avatar_url but NOT email. Access is controlled by group_members RLS policies.';
