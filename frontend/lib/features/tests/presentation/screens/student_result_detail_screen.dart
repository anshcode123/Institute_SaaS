import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/test_models.dart';
import '../providers/test_providers.dart';

final _resultDetailProvider =
    FutureProvider.family<StudentResultDetail, ({String studentId, String resultId})>((ref, args) async {
  return ref.watch(testRepositoryProvider).getStudentResultDetail(args.studentId, args.resultId);
});

/// The clean per-student result view from the spec's mockup - subject-
/// wise marks, total, percentage, grade, pass/fail, test date and batch.
class StudentResultDetailScreen extends ConsumerWidget {
  const StudentResultDetailScreen({super.key, required this.studentId, required this.resultId});

  final String studentId;
  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(_resultDetailProvider((studentId: studentId, resultId: resultId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load result',
          onRetry: () => ref.invalidate(_resultDetailProvider((studentId: studentId, resultId: resultId))),
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(detail.testName, style: Theme.of(context).textTheme.headlineSmall),
            Text(detail.batchName, style: const TextStyle(color: Colors.grey)),
            Text(DateFormat.yMMMd().format(detail.testDate), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final mark in detail.subjectMarks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(mark.subject.name),
                            Text('${mark.obtainedMarks} / ${mark.maxMarks}'),
                          ],
                        ),
                      ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${detail.result.obtainedMarks} / ${detail.result.totalMarks}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, 'Percentage', '${detail.result.percentage}%'),
                    _row(context, 'Grade', detail.result.grade),
                    _row(
                      context,
                      'Status',
                      detail.result.status,
                      valueColor: detail.result.status == 'PASS' ? Colors.green : Colors.red,
                    ),
                    if (detail.result.rank != null) _row(context, 'Rank', '#${detail.result.rank}'),
                  ],
                ),
              ),
            ),
            if (detail.result.publishedAt == null) ...[
              const SizedBox(height: 12),
              Text(
                'Not yet published',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor),
          ),
        ],
      ),
    );
  }
}
