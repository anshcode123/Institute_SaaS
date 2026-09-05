import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/batch_repository_impl.dart';
import '../../domain/batch_models.dart';
import '../../domain/batch_repository.dart';
import 'batch_list_state.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) => BatchRepositoryImpl());

final batchListControllerProvider =
    StateNotifierProvider<BatchListController, BatchListState>((ref) {
  return BatchListController(ref.watch(batchRepositoryProvider));
});

class BatchListController extends StateNotifier<BatchListState> {
  BatchListController(this._repository) : super(const BatchListState()) {
    load();
  }

  final BatchRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: BatchListStatus.loading);
    try {
      final result = await _repository.list(
        query: state.query.isEmpty ? null : state.query,
        status: state.statusFilter,
      );
      state = state.copyWith(status: BatchListStatus.loaded, items: result.items);
    } catch (e) {
      state = state.copyWith(
        status: BatchListStatus.error,
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

final batchDetailProvider = FutureProvider.family<Batch, String>((ref, id) async {
  return ref.watch(batchRepositoryProvider).getById(id);
});
