import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/student_portal_providers.dart';

/// Only ever shows published results - /student/results (the endpoint
/// this calls) filters that server-side, so there's no unpublished
/// result this list could accidentally leak.
class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(_myResultsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Results')),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
            message: 'Failed to load results',
            onRetry: () => ref.invalidate(_myResultsProvider)),
        data: (results) {
          if (results.isEmpty) {
            return const EmptyState(
                message: 'No published results yet.',
                icon: Icons.grade_outlined);
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${r.obtainedMarks} / ${r.totalMarks}'),
                  subtitle: Text('${r.percentage}% • Grade ${r.grade}'),
                  trailing: Text(r.status,
                      style: TextStyle(
                          color: r.status == 'PASS' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold)),
                  onTap: () => context.push('/student/results/${r.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _myResultsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(studentPortalRepositoryProvider).getMyResults();
});
