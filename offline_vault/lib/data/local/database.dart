import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Tables
// ═══════════════════════════════════════════════════════════════════════════

/// Groups that the current user belongs to.
class LocalGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().withDefault(const Constant('#0F5C5A'))();
  TextColumn get myRole => text().withDefault(const Constant('viewer'))();
  DateTimeColumn get lastSyncCursor => dateTime().nullable()();
  TextColumn get lastSyncCursorId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Folders within a group, supporting nesting via [parentId].
class LocalFolders extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(LocalGroups, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Files synced or tracked locally.
class LocalFiles extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(LocalGroups, #id)();
  TextColumn get folderId => text().nullable().references(LocalFolders, #id)();
  TextColumn get name => text().withLength(min: 1, max: 300)();
  TextColumn get note => text().nullable()();
  TextColumn get mime => text()();
  IntColumn get size => integer()();
  TextColumn get checksum => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get thumbState =>
      text().withDefault(const Constant('remote'))();
  TextColumn get originalState =>
      text().withDefault(const Constant('remote'))();
  TextColumn get localThumbPath => text().nullable()();
  TextColumn get localOriginalPath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queue of files waiting to be uploaded to the server.
class UploadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get localPath => text()();
  TextColumn get groupId => text().references(LocalGroups, #id)();
  TextColumn get folderId => text().nullable().references(LocalFolders, #id)();
  TextColumn get name => text().withLength(min: 1, max: 300)();
  TextColumn get mime => text()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get bytesSent => integer().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Log of sync cycles for diagnostics and display in the sync centre.
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get bytesDown => integer().withDefault(const Constant(0))();
  IntColumn get bytesUp => integer().withDefault(const Constant(0))();
  TextColumn get result => text().withDefault(const Constant(''))();
}

// ═══════════════════════════════════════════════════════════════════════════
// FTS5 virtual table for full-text search over file name and note
// ═══════════════════════════════════════════════════════════════════════════

/// FTS5 index over [LocalFiles.name] and [LocalFiles.note].
///
/// This is declared as a raw SQL statement in the database constructor
/// because Drift does not natively support FTS5 table declarations.

// ═══════════════════════════════════════════════════════════════════════════
// DAOs
// ═══════════════════════════════════════════════════════════════════════════

@DriftAccessor(tables: [LocalGroups])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  /// Watch all groups ordered by name.
  Stream<List<LocalGroup>> watchAll() {
    return (select(localGroups)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get all groups as a one-shot query.
  Future<List<LocalGroup>> getAll() {
    return (select(localGroups)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get a single group by ID, or null if not found.
  Future<LocalGroup?> getById(String groupId) {
    return (select(localGroups)..where((t) => t.id.equals(groupId)))
        .getSingleOrNull();
  }

  /// Watch a single group by ID.
  Stream<LocalGroup?> watchById(String groupId) {
    return (select(localGroups)..where((t) => t.id.equals(groupId)))
        .watchSingleOrNull();
  }

  /// Insert or update a group.
  Future<void> upsert(LocalGroupsCompanion group) {
    return into(localGroups).insertOnConflictUpdate(group);
  }

  /// Delete a group and cascade-delete its folders and files.
  Future<void> deleteGroup(String groupId) async {
    await (delete(localGroups)..where((t) => t.id.equals(groupId))).go();
  }

  /// Update the sync cursor for a group using server updated_at and tiebreaker row id.
  Future<void> updateSyncCursor(String groupId, DateTime cursor, {String? cursorId}) {
    return (update(localGroups)..where((t) => t.id.equals(groupId))).write(
      LocalGroupsCompanion(
        lastSyncCursor: Value(cursor),
        lastSyncCursorId: Value(cursorId),
      ),
    );
  }

  /// Reset all sync cursors to null (one-time migration / safe re-pull).
  Future<void> resetAllSyncCursors() {
    return update(localGroups).write(
      const LocalGroupsCompanion(
        lastSyncCursor: Value(null),
        lastSyncCursorId: Value(null),
      ),
    );
  }
}

@DriftAccessor(tables: [LocalFolders])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  /// Delete a folder by ID.
  Future<int> deleteById(String folderId) {
    return (delete(localFolders)..where((t) => t.id.equals(folderId))).go();
  }

  /// Watch folders for a specific group, optionally filtered by parent.
  Stream<List<LocalFolder>> watchByGroup(
    String groupId, {
    String? parentId,
  }) {
    final query = select(localFolders)
      ..where((t) => t.groupId.equals(groupId));

    if (parentId != null) {
      query.where((t) => t.parentId.equals(parentId));
    } else {
      query.where((t) => t.parentId.isNull());
    }

    return (query..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Get a single folder by ID.
  Future<LocalFolder?> getById(String folderId) {
    return (select(localFolders)..where((t) => t.id.equals(folderId)))
        .getSingleOrNull();
  }

  /// Insert or update a folder.
  Future<void> upsert(LocalFoldersCompanion folder) {
    return into(localFolders).insertOnConflictUpdate(folder);
  }

  /// Delete a folder by ID.
  Future<void> deleteFolder(String folderId) {
    return (delete(localFolders)..where((t) => t.id.equals(folderId))).go();
  }

  /// Delete all folders for a group.
  Future<void> deleteByGroup(String groupId) {
    return (delete(localFolders)..where((t) => t.groupId.equals(groupId)))
        .go();
  }

  /// Count folders in a group.
  Future<int> countByGroup(String groupId) async {
    final count = countAll();
    final query = selectOnly(localFolders)
      ..addColumns([count])
      ..where(localFolders.groupId.equals(groupId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}

@DriftAccessor(tables: [LocalFiles])
class FilesDao extends DatabaseAccessor<AppDatabase> with _$FilesDaoMixin {
  FilesDao(super.db);

  /// Delete a file by ID.
  Future<int> deleteById(String fileId) {
    return (delete(localFiles)..where((t) => t.id.equals(fileId))).go();
  }

  /// Watch files for a group, optionally in a specific folder.
  Stream<List<LocalFile>> watchByGroup(
    String groupId, {
    String? folderId,
  }) {
    final query = select(localFiles)
      ..where((t) => t.groupId.equals(groupId));

    if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    } else {
      query.where((t) => t.folderId.isNull());
    }

    return (query..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  /// Get a single file by ID.
  Future<LocalFile?> getById(String fileId) {
    return (select(localFiles)..where((t) => t.id.equals(fileId)))
        .getSingleOrNull();
  }

  /// Watch a single file by ID.
  Stream<LocalFile?> watchById(String fileId) {
    return (select(localFiles)..where((t) => t.id.equals(fileId)))
        .watchSingleOrNull();
  }

  /// Insert or update a file.
  Future<void> upsert(LocalFilesCompanion file) {
    return into(localFiles).insertOnConflictUpdate(file);
  }

  /// Update the thumbnail sync state and optional local path.
  Future<void> updateThumbState(
    String fileId,
    String state, {
    String? localPath,
  }) {
    return (update(localFiles)..where((t) => t.id.equals(fileId))).write(
      LocalFilesCompanion(
        thumbState: Value(state),
        localThumbPath: Value(localPath),
      ),
    );
  }

  /// Update the original file sync state and optional local path.
  Future<void> updateOriginalState(
    String fileId,
    String state, {
    String? localPath,
  }) {
    return (update(localFiles)..where((t) => t.id.equals(fileId))).write(
      LocalFilesCompanion(
        originalState: Value(state),
        localOriginalPath: Value(localPath),
      ),
    );
  }

  /// Delete a file by ID.
  Future<void> deleteFile(String fileId) {
    return (delete(localFiles)..where((t) => t.id.equals(fileId))).go();
  }

  /// Delete all files for a group.
  Future<void> deleteByGroup(String groupId) {
    return (delete(localFiles)..where((t) => t.groupId.equals(groupId))).go();
  }

  /// Count files and total size for a group.
  Future<({int count, int totalSize})> statsByGroup(String groupId) async {
    final fileCount = countAll();
    final totalSize = localFiles.size.sum();
    final query = selectOnly(localFiles)
      ..addColumns([fileCount, totalSize])
      ..where(localFiles.groupId.equals(groupId));
    final row = await query.getSingle();
    return (
      count: row.read(fileCount) ?? 0,
      totalSize: row.read(totalSize) ?? 0,
    );
  }

  /// Full-text search across file names and notes using FTS5.
  Future<List<LocalFile>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final sanitized = trimmed.replaceAll('"', '""');
      final results = await customSelect(
        'SELECT f.* FROM local_files f '
        'INNER JOIN files_fts fts ON f.rowid = fts.rowid '
        'WHERE files_fts MATCH ? '
        'ORDER BY rank',
        variables: [Variable.withString(sanitized)],
        readsFrom: {localFiles},
      ).get();

      if (results.isNotEmpty) {
        return results.map((row) {
          return LocalFile(
            id: row.read<String>('id'),
            groupId: row.read<String>('group_id'),
            folderId: row.readNullable<String>('folder_id'),
            name: row.read<String>('name'),
            note: row.readNullable<String>('note'),
            mime: row.read<String>('mime'),
            size: row.read<int>('size'),
            checksum: row.read<String>('checksum'),
            width: row.readNullable<int>('width'),
            height: row.readNullable<int>('height'),
            thumbState: row.read<String>('thumb_state'),
            originalState: row.read<String>('original_state'),
            localThumbPath: row.readNullable<String>('local_thumb_path'),
            localOriginalPath: row.readNullable<String>('local_original_path'),
            updatedAt: row.read<DateTime>('updated_at'),
          );
        }).toList();
      }
    } catch (_) {
      // Fall back to SQL LIKE if FTS is unavailable
    }

    final pattern = '%${trimmed.toLowerCase()}%';
    return (select(localFiles)
          ..where(
            (t) =>
                t.name.lower().like(pattern) |
                t.note.lower().like(pattern),
          ))
        .get();
  }
}

@DriftAccessor(tables: [UploadQueue])
class UploadQueueDao extends DatabaseAccessor<AppDatabase>
    with _$UploadQueueDaoMixin {
  UploadQueueDao(super.db);

  /// Insert an item into the upload queue.
  Future<void> insertItem(UploadQueueCompanion item) => enqueue(item);

  /// Get pending upload items.
  Future<List<UploadQueueData>> getPending() => getByState('pending');

  /// Update queue item state.
  Future<void> updateState(String id, String state, {int? bytesSent}) =>
      updateProgress(id, state: state, bytesSent: bytesSent);

  /// Update queue item attempts and state.
  Future<void> updateAttempts(String id, int attempts, String state, {String? error}) async {
    await (update(uploadQueue)..where((t) => t.id.equals(id))).write(
      UploadQueueCompanion(
        attempts: Value(attempts),
        state: Value(state),
        lastError: Value(error),
      ),
    );
  }

  /// Watch all pending and failed uploads, ordered by creation time.
  Stream<List<UploadQueueData>> watchPending() {
    return (select(uploadQueue)
          ..where(
            (t) =>
                t.state.equals('pending') | t.state.equals('failed'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Get all items with a specific state.
  Future<List<UploadQueueData>> getByState(String state) {
    return (select(uploadQueue)
          ..where((t) => t.state.equals(state))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get the next pending item to upload.
  Future<UploadQueueData?> getNextPending() {
    return (select(uploadQueue)
          ..where((t) => t.state.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Enqueue a new upload.
  Future<void> enqueue(UploadQueueCompanion item) {
    return into(uploadQueue).insert(item);
  }

  /// Update the state and progress of an upload item.
  Future<void> updateProgress(
    String itemId, {
    required String state,
    int? bytesSent,
    String? lastError,
  }) {
    return (update(uploadQueue)..where((t) => t.id.equals(itemId))).write(
      UploadQueueCompanion(
        state: Value(state),
        bytesSent: bytesSent != null ? Value(bytesSent) : const Value.absent(),
        lastError: Value(lastError),
      ),
    );
  }

  /// Increment the attempt counter for a failed item.
  Future<void> incrementAttempts(String itemId) async {
    final item = await (select(uploadQueue)
          ..where((t) => t.id.equals(itemId)))
        .getSingle();
    await (update(uploadQueue)..where((t) => t.id.equals(itemId))).write(
      UploadQueueCompanion(attempts: Value(item.attempts + 1)),
    );
  }

  /// Remove completed uploads older than [before].
  Future<void> pruneCompleted(DateTime before) {
    return (delete(uploadQueue)
          ..where(
            (t) =>
                t.state.equals('done') & t.createdAt.isSmallerThanValue(before),
          ))
        .go();
  }

  /// Delete an item from the queue.
  Future<void> deleteItem(String itemId) {
    return (delete(uploadQueue)..where((t) => t.id.equals(itemId))).go();
  }

  /// Count items by state.
  Future<int> countByState(String state) async {
    final count = countAll();
    final query = selectOnly(uploadQueue)
      ..addColumns([count])
      ..where(uploadQueue.state.equals(state));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}

@DriftAccessor(tables: [SyncLog])
class SyncLogDao extends DatabaseAccessor<AppDatabase>
    with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  /// Insert a completed sync log.
  Future<int> insertLog(SyncLogCompanion log) => into(syncLog).insert(log);

  /// Watch the most recent sync logs.
  Stream<List<SyncLogData>> watchRecent({int limit = 20}) {
    return (select(syncLog)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .watch();
  }

  /// Get the most recent completed sync entry.
  Future<SyncLogData?> getLastCompleted() {
    return (select(syncLog)
          ..where((t) => t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Start a new sync log entry and return its ID.
  Future<int> startSync() async {
    return into(syncLog).insert(
      SyncLogCompanion.insert(startedAt: DateTime.now()),
    );
  }

  /// Complete a sync log entry.
  Future<void> completeSync(
    int logId, {
    required int bytesDown,
    required int bytesUp,
    required String result,
  }) {
    return (update(syncLog)..where((t) => t.id.equals(logId))).write(
      SyncLogCompanion(
        endedAt: Value(DateTime.now()),
        bytesDown: Value(bytesDown),
        bytesUp: Value(bytesUp),
        result: Value(result),
      ),
    );
  }

  /// Delete sync logs older than [before].
  Future<void> prune(DateTime before) {
    return (delete(syncLog)
          ..where((t) => t.startedAt.isSmallerThanValue(before)))
        .go();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Database
// ═══════════════════════════════════════════════════════════════════════════

@DriftDatabase(
  tables: [LocalGroups, LocalFolders, LocalFiles, UploadQueue, SyncLog],
  daos: [GroupsDao, FoldersDao, FilesDao, UploadQueueDao, SyncLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with an in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create FTS5 virtual table for file search.
        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS files_fts USING fts5('
          'name, note, content=local_files, content_rowid=rowid'
          ')',
        );
        // Triggers to keep the FTS index in sync.
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS files_fts_insert AFTER INSERT ON local_files BEGIN '
          'INSERT INTO files_fts(rowid, name, note) VALUES (new.rowid, new.name, new.note); '
          'END',
        );
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS files_fts_delete AFTER DELETE ON local_files BEGIN '
          "INSERT INTO files_fts(files_fts, rowid, name, note) VALUES ('delete', old.rowid, old.name, old.note); "
          'END',
        );
        await customStatement(
          'CREATE TRIGGER IF NOT EXISTS files_fts_update AFTER UPDATE ON local_files BEGIN '
          "INSERT INTO files_fts(files_fts, rowid, name, note) VALUES ('delete', old.rowid, old.name, old.note); "
          'INSERT INTO files_fts(rowid, name, note) VALUES (new.rowid, new.name, new.note); '
          'END',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(localGroups, localGroups.lastSyncCursorId);
          await customStatement('UPDATE local_groups SET last_sync_cursor = NULL, last_sync_cursor_id = NULL;');
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'offline_vault.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod provider for the Drift database singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
