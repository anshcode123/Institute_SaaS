import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/attendance_models.dart';
import '../providers/attendance_providers.dart';
import 'qr_scanner_screen.dart';

class BatchAttendanceScreen extends ConsumerWidget {
  const BatchAttendanceScreen({super.key, required this.batchId, required this.batchName});

  final String batchId;
  final String batchName;

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final qrToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (qrToken == null || !context.mounted) return;

    try {
      final result = await ref.read(attendanceRepositoryProvider).scan(
            qrToken: qrToken,
            batchId: batchId,
          );
      ref.invalidate(batchAttendanceSummaryProvider(batchId));
      if (context.mounted) _showResultDialog(context, result);
    } catch (e) {
      final message = e is AppException ? e.message : 'Failed to record attendance';
      if (context.mounted) _showErrorDialog(context, message);
    }
  }

  void _showResultDialog(BuildContext context, ScanResult result) {
    final record = result.attendance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.alreadyMarked ? Icons.info_outline : Icons.check_circle,
          color: result.alreadyMarked ? Colors.orange : Colors.green,
          size: 40,
        ),
        title: Text(result.alreadyMarked ? 'Attendance Already Marked' : 'Attendance Marked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${record.student?.fullName ?? '-'}'),
            const SizedBox(height: 4),
            Text('Batch: ${record.batch?.name ?? '-'}'),
            const SizedBox(height: 4),
            Text('Status: ${record.status}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: const Text('Could Not Mark Attendance'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(batchAttendanceSummaryProvider(batchId));
    final dateLabel = DateFormat.yMMMMd().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text('Attendance — $batchName')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(batchAttendanceSummaryProvider(batchId)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Date: $dateLabel', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Student QR'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => _scan(context, ref),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Manual Attendance'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => context.push(
                '/attendance/batch/$batchId/manual?name=${Uri.encodeComponent(batchName)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Attendance History'),
              onPressed: () => context.push('/attendance/history?batchId=$batchId'),
            ),
            const SizedBox(height: 24),
            asyncSummary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: 'Failed to load summary',
                onRetry: () => ref.invalidate(batchAttendanceSummaryProvider(batchId)),
              ),
              data: (summary) => _SummaryCard(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final BatchAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Summary", style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _statRow('Students Present', summary.present.toString(), Colors.green),
            _statRow('Students Remaining', summary.remaining.toString(), Colors.orange),
            _statRow('Absent', summary.absent.toString(), Colors.red),
            _statRow('Late', summary.late.toString(), Colors.amber),
            _statRow('Excused', summary.excused.toString(), Colors.blueGrey),
            const Divider(),
            _statRow('Attendance', '${summary.percentage}%', Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
