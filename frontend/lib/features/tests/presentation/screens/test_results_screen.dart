import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/test_models.dart';
import '../providers/test_providers.dart';

class TestResultsScreen extends ConsumerWidget {
  const TestResultsScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(testResultsProvider(testId));

    return Scaffold(
      appBar: AppBar(title: const Text('Test Results')),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load results',
          onRetry: () => ref.invalidate(testResultsProvider(testId)),
        ),
        data: (page) {
          if (page.results.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No results yet. Marks need to be entered for every subject first.'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(summary: page.summary),
              const SizedBox(height: 16),
              Text('Student | Total | % | Grade | Status', style: Theme.of(context).textTheme.labelMedium),
              const Divider(),
              for (final result in page.results)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${result.rank ?? '-'}')),
                    title: Text(result.student?.fullName ?? 'Unknown'),
                    subtitle: Text(
                      '${result.obtainedMarks}/${result.totalMarks} • ${result.percentage}% • Grade ${result.grade}',
                    ),
                    trailing: Text(
                      result.status,
                      style: TextStyle(
                        color: result.status == 'PASS' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: result.student == null
                        ? null
                        : () => context.push('/students/${result.student!.id}/results/${result.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TestResultsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Performance', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _statRow('Students', '${summary.studentCount}'),
            _statRow('Average', '${summary.average}'),
            _statRow('Highest', '${summary.highest}'),
            _statRow('Lowest', '${summary.lowest}'),
            _statRow('Pass', '${summary.passCount}', color: Colors.green),
            _statRow('Fail', '${summary.failCount}', color: Colors.red),
            _statRow('Pass %', '${summary.passPercentage}%'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
