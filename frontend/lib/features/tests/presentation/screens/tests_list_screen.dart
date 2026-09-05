import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/test_providers.dart';
import '../widgets/test_status_chip.dart';

/// Doubles as "Tests Dashboard" (Institute Admin) and "My Tests"
/// (Teacher, filtered server-side to their assigned batches) - same
/// screen, same list controller, matching the single-Home-screen +
/// role-conditional pattern used everywhere else rather than building
/// separate dashboard screens per role.
class TestsListScreen extends ConsumerWidget {
  const TestsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testListControllerProvider);
    final controller = ref.read(testListControllerProvider.notifier);
    final isTeacher = ref.watch(authControllerProvider).user?.role == 'TEACHER';

    return Scaffold(
      appBar: AppBar(title: Text(isTeacher ? 'My Tests' : 'Tests')),
      floatingActionButton: isTeacher
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/tests/new'),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<String?>(
              value: state.statusFilter,
              hint: const Text('Filter by status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'SCHEDULED', child: Text('Scheduled')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                DropdownMenuItem(value: 'PUBLISHED', child: Text('Published')),
              ],
              onChanged: controller.setStatusFilter,
            ),
          ),
          Expanded(
            child: switch (state.status) {
              TestListStatus.initial || TestListStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              TestListStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load tests',
                  onRetry: controller.load,
                ),
              TestListStatus.loaded => state.items.isEmpty
                  ? const EmptyState(message: 'No tests yet.', icon: Icons.quiz_outlined)
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final test = state.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () => context.push('/tests/${test.id}'),
                              title: Text(test.name),
                              subtitle: Text(
                                '${test.batch?.name ?? '-'} • ${DateFormat.yMMMd().format(test.testDate)}\n'
                                '${test.subjects.length} subjects • ${test.resultCount ?? 0} results',
                              ),
                              isThreeLine: true,
                              trailing: TestStatusChip(status: test.status),
                            ),
                          );
                        },
                      ),
                    ),
            },
          ),
        ],
      ),
    );
  }
}
