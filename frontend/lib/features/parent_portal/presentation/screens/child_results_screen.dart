import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../providers/parent_portal_providers.dart';

class ChildResultsScreen extends ConsumerWidget {
  const ChildResultsScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(_resultsProvider(studentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(message: 'Failed to load results', onRetry: () => ref.invalidate(_resultsProvider(studentId))),
        data: (results) {
          if (results.isEmpty) {
            return const EmptyState(message: 'No published results yet.', icon: Icons.grade_outlined);
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
                  trailing: Text(r.status, style: TextStyle(color: r.status == 'PASS' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => context.push('/parent/children/$studentId/results/${r.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _resultsProvider = FutureProvider.family((ref, String studentId) async {
  return ref.watch(parentPortalRepositoryProvider).getChildResults(studentId);
});
