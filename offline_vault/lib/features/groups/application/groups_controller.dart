import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/repositories/groups_repository.dart';

final groupsListProvider = StreamProvider<List<LocalGroup>>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.watchGroups();
});

final groupsControllerProvider =
    StateNotifierProvider<GroupsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupsController(repository: repository);
});

class GroupsController extends StateNotifier<AsyncValue<void>> {
  GroupsController({required GroupsRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(null));

  final GroupsRepository _repository;

  Future<Map<String, dynamic>?> createGroup({
    required String name,
    required String color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createGroup(name: name, color: color);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGroup(String code) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.joinGroup(code);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
