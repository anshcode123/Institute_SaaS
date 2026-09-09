import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../tests/domain/test_models.dart';
import '../providers/parent_portal_providers.dart';

class ChildResultViewScreen extends ConsumerWidget {
  const ChildResultViewScreen(
      {super.key, required this.studentId, required this.resultId});
  final String studentId;
  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail =
        ref.watch(_detailProvider((studentId: studentId, resultId: resultId)));
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load result',
          onRetry: () => ref.invalidate(
              _detailProvider((studentId: studentId, resultId: resultId))),
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(detail.testName,
                style: Theme.of(context).textTheme.headlineSmall),
            Text(detail.batchName, style: const TextStyle(color: Colors.grey)),
            Text(DateFormat.yMMMd().format(detail.testDate),
                style: const TextStyle(color: Colors.grey)),
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
                            Text('${mark.obtainedMarks} / ${mark.maxMarks}')
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            '${detail.result.obtainedMarks} / ${detail.result.totalMarks}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
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
                    _row('Percentage', '${detail.result.percentage}%'),
                    _row('Grade', detail.result.grade),
                    _row('Status', detail.result.status,
                        valueColor: detail.result.status == 'PASS'
                            ? Colors.green
                            : Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: valueColor))
        ],
      ),
    );
  }
}

final _detailProvider = FutureProvider.family<StudentResultDetail,
    ({String studentId, String resultId})>((ref, args) async {
  return ref
      .watch(parentPortalRepositoryProvider)
      .getChildResultDetail(args.studentId, args.resultId);
});
