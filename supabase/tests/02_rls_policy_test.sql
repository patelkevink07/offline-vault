BEGIN;
SELECT plan(10);

-- Test 1: Public schema tables RLS enabled check
SELECT row_level_security_is_active('public', 'profiles');
SELECT row_level_security_is_active('public', 'groups');
SELECT row_level_security_is_active('public', 'group_members');
SELECT row_level_security_is_active('public', 'invite_codes');
SELECT row_level_security_is_active('public', 'folders');
SELECT row_level_security_is_active('public', 'files');
SELECT row_level_security_is_active('public', 'join_attempts');

-- Test 2: Storage objects RLS enabled check
SELECT row_level_security_is_active('storage', 'objects');

-- Test 3: Verify policies exist on files table
SELECT policies_are('public', 'files', ARRAY[
  'files_select_member',
  'files_insert_writer',
  'files_update_writer',
  'files_delete_writer'
]);

-- Test 4: Verify policies exist on groups table
SELECT policies_are('public', 'groups', ARRAY[
  'groups_select_member',
  'groups_update_owner',
  'groups_delete_owner'
]);

SELECT * FROM finish();
ROLLBACK;
