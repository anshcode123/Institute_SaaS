import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/test_providers.dart';
import '../widgets/test_status_chip.dart';

class TestDetailScreen extends ConsumerWidget {
  const TestDetailScreen({super.key, required this.testId});

  final String testId;

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(testRepositoryProvider).publishTest(testId);
      ref.invalidate(testDetailProvider(testId));
      ref.read(testListControllerProvider.notifier).load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Results published')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is AppException ? e.message : 'Failed to publish')),
        );
      }
    }
  }

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Unpublish results?',
      message: 'Results will no longer be visible and marks can be edited again.',
      confirmLabel: 'Unpublish',
    );
    if (!confirmed) return;
    await ref.read(testRepositoryProvider).unpublishTest(testId);
    ref.invalidate(testDetailProvider(testId));
    ref.read(testListControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTest = ref.watch(testDetailProvider(testId));
    final isAdmin = ref.watch(authControllerProvider).user?.role == 'INSTITUTE_ADMIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Test Details')),
      body: asyncTest.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load test',
          onRetry: () => ref.invalidate(testDetailProvider(testId)),
        ),
        data: (test) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(test.name, style: Theme.of(context).textTheme.headlineSmall),
            if (test.description != null) ...[
              const SizedBox(height: 4),
              Text(test.description!),
            ],
            const SizedBox(height: 8),
            TestStatusChip(status: test.status),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch: ${test.batch?.name ?? '-'}'),
                    Text('Date: ${DateFormat.yMMMd().format(test.testDate)}'),
                    if (test.durationMinutes != null) Text('Duration: ${test.durationMinutes} minutes'),
                    Text('Total Marks: ${test.totalMarks}'),
                    Text('Passing Marks: ${test.passingMarks}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Subjects', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final subject in test.subjects)
              Card(
                child: ListTile(
                  title: Text(subject.subject.name),
                  subtitle: Text('Max: ${subject.maxMarks} • Passing: ${subject.passingMarks}'),
                  trailing: TextButton(
                    onPressed: test.status == 'PUBLISHED'
                        ? null
                        : () => context.push(
                              '/tests/$testId/marks?subjectId=${subject.subject.id}&subjectName=${Uri.encodeComponent(subject.subject.name)}&maxMarks=${subject.maxMarks}',
                            ),
                    child: const Text('Enter Marks'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.leaderboard_outlined),
              label: const Text('View Results'),
              onPressed: () => context.push('/tests/$testId/results'),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              if (test.status != 'PUBLISHED' && test.status != 'CANCELLED')
                OutlinedButton.icon(
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Publish Results'),
                  onPressed: () => _publish(context, ref),
                ),
              if (test.status == 'PUBLISHED')
                OutlinedButton.icon(
                  icon: const Icon(Icons.unpublished_outlined),
                  label: const Text('Unpublish Results'),
                  onPressed: () => _unpublish(context, ref),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
