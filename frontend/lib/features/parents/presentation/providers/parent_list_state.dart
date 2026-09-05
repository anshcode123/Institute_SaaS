import '../../domain/parent_models.dart';

enum ParentListStatus { initial, loading, loaded, error }

class ParentListState {
  final ParentListStatus status;
  final List<Parent> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;

  const ParentListState({
    this.status = ParentListStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.statusFilter,
  });

  ParentListState copyWith({
    ParentListStatus? status,
    List<Parent>? items,
    String? errorMessage,
    String? query,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return ParentListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}
