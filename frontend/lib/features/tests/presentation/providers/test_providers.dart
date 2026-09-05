import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/test_repository_impl.dart';
import '../../domain/test_models.dart';
import '../../domain/test_repository.dart';

final testRepositoryProvider = Provider<TestRepository>((ref) => TestRepositoryImpl());

enum TestListStatus { initial, loading, loaded, error }

class TestListState {
  final TestListStatus status;
  final List<Test> items;
  final String? errorMessage;
  final String? batchFilter;
  final String? statusFilter;

  const TestListState({
    this.status = TestListStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.batchFilter,
    this.statusFilter,
  });

  TestListState copyWith({
    TestListStatus? status,
    List<Test>? items,
    String? errorMessage,
    String? batchFilter,
    String? statusFilter,
    bool clearBatchFilter = false,
    bool clearStatusFilter = false,
  }) {
    return TestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      batchFilter: clearBatchFilter ? null : (batchFilter ?? this.batchFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class TestListController extends StateNotifier<TestListState> {
  TestListController(this._repository) : super(const TestListState()) {
    load();
  }

  final TestRepository _repository;

  Future<void> load() async {
    state = state.copyWith(status: TestListStatus.loading);
    try {
      final result = await _repository.listTests(
        batchId: state.batchFilter,
        status: state.statusFilter,
      );
      state = state.copyWith(status: TestListStatus.loaded, items: result.items);
    } catch (e) {
      state = state.copyWith(
        status: TestListStatus.error,
        errorMessage: e is AppException ? e.message : e.toString(),
      );
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    load();
  }
}

final testListControllerProvider = StateNotifierProvider<TestListController, TestListState>((ref) {
  return TestListController(ref.watch(testRepositoryProvider));
});

final testDetailProvider = FutureProvider.family<Test, String>((ref, id) async {
  return ref.watch(testRepositoryProvider).getTest(id);
});

final testResultsProvider = FutureProvider.family<TestResultsPage, String>((ref, testId) async {
  return ref.watch(testRepositoryProvider).getTestResults(testId);
});

final studentResultsProvider = FutureProvider.family<List<StudentTestResult>, String>((ref, studentId) async {
  return ref.watch(testRepositoryProvider).getStudentResults(studentId);
});
