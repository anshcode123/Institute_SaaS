import '../../domain/student_models.dart';

enum StudentListStatus { initial, loading, loaded, error }

class StudentListState {
  final StudentListStatus status;
  final List<Student> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;

  const StudentListState({
    this.status = StudentListStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.statusFilter,
  });

  StudentListState copyWith({
    StudentListStatus? status,
    List<Student>? items,
    String? errorMessage,
    String? query,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return StudentListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}
