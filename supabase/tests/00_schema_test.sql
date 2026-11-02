BEGIN;
SELECT plan(18);

-- 1. Check pgcrypto extension installed
SELECT has_extension('pgcrypto');

-- 2. Check all tables exist
SELECT has_table('profiles');
SELECT has_table('groups');
SELECT has_table('group_members');
SELECT has_table('invite_codes');
SELECT has_table('folders');
SELECT has_table('files');
SELECT has_table('join_attempts');

-- 3. Check helper functions exist
SELECT has_function('is_member', ARRAY['uuid']);
SELECT has_function('can_write', ARRAY['uuid']);
SELECT has_function('is_owner', ARRAY['uuid']);

-- 4. Check RPC functions exist
SELECT has_function('create_group', ARRAY['text', 'text']);
SELECT has_function('join_group', ARRAY['text']);
SELECT has_function('rotate_invite_code', ARRAY['uuid', 'interval']);
SELECT has_function('set_invite_code_state', ARRAY['uuid', 'boolean', 'timestamp with time zone']);
SELECT has_function('get_invite_code', ARRAY['uuid']);

-- 5. Check RLS is enabled on all tables
SELECT row_level_security_is_active('profiles');
SELECT row_level_security_is_active('groups');
SELECT row_level_security_is_active('files');

SELECT * FROM finish();
ROLLBACK;
