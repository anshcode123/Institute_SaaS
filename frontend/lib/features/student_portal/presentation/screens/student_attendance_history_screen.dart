import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../providers/student_portal_providers.dart';

/// Read-only, own-records-only view - the student cannot edit or filter
/// into anyone else's attendance since the backend endpoint this calls
/// (/student/attendance) already forces the studentId server-side.
class StudentAttendanceHistoryScreen extends ConsumerWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(_myAttendanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: asyncResult.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(message: 'Failed to load attendance', onRetry: () => ref.invalidate(_myAttendanceProvider)),
        data: (result) {
          if (result.items.isEmpty) {
            return const EmptyState(message: 'No attendance records yet.', icon: Icons.event_busy);
          }
          return ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final record = result.items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(DateFormat.yMMMd().format(record.date)),
                  subtitle: Text(record.batch?.name ?? '-'),
                  trailing: Text(record.status, style: TextStyle(color: record.status == 'PRESENT' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _myAttendanceProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(studentPortalRepositoryProvider).getMyAttendance();
});
