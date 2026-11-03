import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_vault/core/storage/file_storage_service.dart';
import 'package:offline_vault/data/local/database.dart';
import 'package:offline_vault/data/remote/groups_remote_source.dart';
import 'package:offline_vault/data/repositories/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUser extends Fake implements User {
  @override
  String get id => 'user-alice';
}

class MockGoTrueClient extends Fake implements GoTrueClient {
  User? mockCurrentUser = MockUser();

  @override
  User? get currentUser => mockCurrentUser;
}

class MockSupabaseClient extends Fake implements SupabaseClient {
  final _auth = MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;
}

class FakeFileStorageService extends Fake implements FileStorageService {
  final List<String> wipedGroups = [];

  @override
  Future<void> wipeGroupStorage(String groupId) async {
    wipedGroups.add(groupId);
  }
}

class FakeGroupsRemoteSource extends Fake implements GroupsRemoteSource {
  final Map<String, String> memberRoles = {};
  final List<String> removedMembers = [];
  bool leaveGroupCalled = false;

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    return [
      {
        'user_id': 'user-alice',
        'role': memberRoles['user-alice'] ?? 'editor',
        'status': 'active',
        'profiles': {'display_name': 'Alice'},
      },
      {
        'user_id': 'user-bob',
        'role': memberRoles['user-bob'] ?? 'viewer',
        'status': 'active',
        'profiles': {'display_name': 'Bob'},
      },
    ];
  }

  @override
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    memberRoles[userId] = role;
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    removedMembers.add(userId);
  }

  @override
  Future<void> leaveGroup({required String groupId}) async {
    leaveGroupCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeGroupsRemoteSource remoteSource;
  late FakeFileStorageService storageService;
  late MockSupabaseClient supabase;
  late GroupsRepository groupsRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteSource = FakeGroupsRemoteSource();
    storageService = FakeFileStorageService();
    supabase = MockSupabaseClient();

    groupsRepo = GroupsRepository(
      db: db,
      remote: remoteSource,
      supabase: supabase,
      storage: storageService,
    );

    // Seed local group with folders and files
    await db.groupsDao.upsert(
      LocalGroupsCompanion.insert(
        id: 'group-vault',
        name: 'Family Vault',
        color: const Value('#0F5C5A'),
        myRole: const Value('editor'),
      ),
    );

    await db.foldersDao.upsert(
      LocalFoldersCompanion.insert(
        id: 'folder-1',
        groupId: 'group-vault',
        name: 'Documents',
        updatedAt: DateTime.now(),
      ),
    );

    await db.filesDao.upsert(
      LocalFilesCompanion.insert(
        id: 'file-1',
        groupId: 'group-vault',
        name: 'Insurance.pdf',
        mime: 'application/pdf',
        size: 2048,
        checksum: 'chk-1',
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 6: Member Management & Local Wipe Tests', () {
    test('Leaving a group wipes local files from storage and deletes group from SQLite', () async {
      // Pre-check: group and files exist
      expect(await db.groupsDao.getById('group-vault'), isNotNull);
      final initialFiles = await db.filesDao.watchByGroup('group-vault').first;
      expect(initialFiles.length, 1);

      // User leaves group
      await groupsRepo.leaveGroup('group-vault');

      // 1. Storage wipe was called for this group
      expect(storageService.wipedGroups, contains('group-vault'));

      // 2. Database records for group are completely purged
      expect(await db.groupsDao.getById('group-vault'), isNull);
      final remainingFiles = await db.filesDao.watchByGroup('group-vault').first;
      expect(remainingFiles, isEmpty);

      // Remote leave was called
      expect(remoteSource.leaveGroupCalled, isTrue);
    });

    test('Owner removing a member updates remote and wipes if self is removed', () async {
      // 1. Remove another member (Bob)
      await groupsRepo.removeMember(
        groupId: 'group-vault',
        userId: 'user-bob',
      );
      expect(remoteSource.removedMembers, contains('user-bob'));
      // Group still exists locally for Alice
      expect(await db.groupsDao.getById('group-vault'), isNotNull);

      // 2. Remove self (Alice)
      await groupsRepo.removeMember(
        groupId: 'group-vault',
        userId: 'user-alice',
      );
      expect(storageService.wipedGroups, contains('group-vault'));
      expect(await db.groupsDao.getById('group-vault'), isNull);
    });

    test('Role change reflects in local permissions when updating own role', () async {
      var current = await db.groupsDao.getById('group-vault');
      expect(current?.myRole, 'editor');

      // Update Alice's role to owner
      await groupsRepo.updateMemberRole(
        groupId: 'group-vault',
        userId: 'user-alice',
        role: 'owner',
      );

      current = await db.groupsDao.getById('group-vault');
      expect(current?.myRole, 'owner');
      expect(remoteSource.memberRoles['user-alice'], 'owner');
    });
  });
}
