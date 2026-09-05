import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/parent_repository_impl.dart';
import '../../domain/parent_models.dart';
import '../../domain/parent_repository.dart';
import 'parent_list_state.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) => ParentRepositoryImpl());

final parentListControllerProvider =
    StateNotifierProvider<ParentListController, ParentListState>((ref) {
  return ParentListController(ref.watch(parentRepositoryProvider));
});

class ParentListController extends StateNotifier<ParentListState> {
  ParentListController(this._repository) : super(const ParentListState()) {
    load();
  }

  final ParentRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: ParentListStatus.loading);
    try {
      final result = await _repository.list(
        query: state.query.isEmpty ? null : state.query,
        status: state.statusFilter,
      );
      state = state.copyWith(status: ParentListStatus.loaded, items: result.items);
    } catch (e) {
      state = state.copyWith(
        status: ParentListStatus.error,
        errorMessage: e is AppException ? e.message : e.toString(),
      );
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    load();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    load();
  }
}

final parentDetailProvider = FutureProvider.family<Parent, String>((ref, id) async {
  return ref.watch(parentRepositoryProvider).getById(id);
});
