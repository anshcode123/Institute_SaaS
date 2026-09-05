import '../../domain/batch_models.dart';

enum BatchListStatus { initial, loading, loaded, error }

class BatchListState {
  final BatchListStatus status;
  final List<Batch> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;

  const BatchListState({
    this.status = BatchListStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.statusFilter,
  });

  BatchListState copyWith({
    BatchListStatus? status,
    List<Batch>? items,
    String? errorMessage,
    String? query,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return BatchListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}
