import '../../domain/teacher_models.dart';

enum TeacherListStatus { initial, loading, loaded, error }

class TeacherListState {
  final TeacherListStatus status;
  final List<Teacher> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;

  const TeacherListState({
    this.status = TeacherListStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.statusFilter,
  });

  TeacherListState copyWith({
    TeacherListStatus? status,
    List<Teacher>? items,
    String? errorMessage,
    String? query,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return TeacherListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}
