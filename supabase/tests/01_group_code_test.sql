BEGIN;
SELECT plan(12);

-- 1. Check invite_codes columns and constraints
SELECT has_column('public', 'invite_codes', 'id');
SELECT has_column('public', 'invite_codes', 'code');
SELECT has_column('public', 'invite_codes', 'enabled');
SELECT has_column('public', 'invite_codes', 'expires_at');

-- 2. Check groups require_approval column
SELECT has_column('public', 'groups', 'require_approval');

-- 3. Check functions exist
SELECT has_function('public', 'approve_member', ARRAY['uuid', 'uuid']);
SELECT has_function('public', 'decline_member', ARRAY['uuid', 'uuid']);
SELECT has_function('public', 'purge_soft_deleted_records', ARRAY['integer']);

-- 4. Check generate_invite_code returns 4 digits
SELECT matches(public.generate_invite_code(), '^[0-9]{4}$', 'Generated code is exactly 4 digits');

-- 5. Check RLS is active on join_attempts, group_members, invite_codes
SELECT row_level_security_is_active('public', 'join_attempts');
SELECT row_level_security_is_active('public', 'group_members');
SELECT row_level_security_is_active('public', 'invite_codes');

SELECT * FROM finish();
ROLLBACK;
