import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/student_repository_impl.dart';
import '../../domain/student_models.dart';
import '../../domain/student_repository.dart';
import 'student_list_state.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) => StudentRepositoryImpl());

final studentListControllerProvider =
    StateNotifierProvider<StudentListController, StudentListState>((ref) {
  return StudentListController(ref.watch(studentRepositoryProvider));
});

class StudentListController extends StateNotifier<StudentListState> {
  StudentListController(this._repository) : super(const StudentListState()) {
    load();
  }

  final StudentRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: StudentListStatus.loading);
    try {
      final result = await _repository.list(
        query: state.query.isEmpty ? null : state.query,
        status: state.statusFilter,
      );
      state = state.copyWith(status: StudentListStatus.loaded, items: result.items);
    } catch (e) {
      state = state.copyWith(
        status: StudentListStatus.error,
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

/// One-off fetch for a single student's full profile (parents, batch).
/// Screens call `ref.refresh(studentDetailProvider(id))` after a mutation
/// to force a re-fetch rather than trusting stale cached data.
final studentDetailProvider =
    FutureProvider.family<Student, String>((ref, id) async {
  return ref.watch(studentRepositoryProvider).getById(id);
});
