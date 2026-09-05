import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/teacher_repository_impl.dart';
import '../../domain/teacher_models.dart';
import '../../domain/teacher_repository.dart';
import 'teacher_list_state.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) => TeacherRepositoryImpl());

final teacherListControllerProvider =
    StateNotifierProvider<TeacherListController, TeacherListState>((ref) {
  return TeacherListController(ref.watch(teacherRepositoryProvider));
});

class TeacherListController extends StateNotifier<TeacherListState> {
  TeacherListController(this._repository) : super(const TeacherListState()) {
    load();
  }

  final TeacherRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: TeacherListStatus.loading);
    try {
      final result = await _repository.list(
        query: state.query.isEmpty ? null : state.query,
        status: state.statusFilter,
      );
      state = state.copyWith(status: TeacherListStatus.loaded, items: result.items);
    } catch (e) {
      state = state.copyWith(
        status: TeacherListStatus.error,
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

final teacherDetailProvider = FutureProvider.family<Teacher, String>((ref, id) async {
  return ref.watch(teacherRepositoryProvider).getById(id);
});
