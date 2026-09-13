import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/attendance_models.dart';
import '../providers/attendance_providers.dart';
import 'qr_scanner_screen.dart';

class AttendanceHubScreen extends ConsumerWidget {
  const AttendanceHubScreen({super.key});

  Future<void> _scanAttendance(BuildContext context, WidgetRef ref) async {
    final qrToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(
          title: 'Scan Attendance QR',
          prompt: 'Align student attendance QR within frame',
        ),
      ),
    );
    if (qrToken == null || !context.mounted) return;

    try {
      final result = await ref.read(attendanceRepositoryProvider).scan(
            qrToken: qrToken,
          );
      if (context.mounted) {
        _showAttendanceResultDialog(context, result);
      }
    } catch (e) {
      final message =
          e is AppException ? e.message : 'Failed to record attendance';
      if (context.mounted) {
        _showErrorDialog(context, 'Attendance Check-in Failed', message);
      }
    }
  }

  Future<void> _scanLeaving(BuildContext context, WidgetRef ref) async {
    final qrToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(
          title: 'Scan Leaving QR',
          prompt: 'Align student leaving QR within frame',
        ),
      ),
    );
    if (qrToken == null || !context.mounted) return;

    try {
      final result = await ref.read(attendanceRepositoryProvider).scanLeaving(
            qrToken: qrToken,
          );
      if (context.mounted) {
        _showLeavingResultDialog(context, result);
      }
    } catch (e) {
      final message =
          e is AppException ? e.message : 'Failed to record leaving';
      if (context.mounted) {
        _showErrorDialog(context, 'Leaving Check-out Failed', message);
      }
    }
  }

  void _showAttendanceResultDialog(BuildContext context, ScanResult result) {
    final record = result.attendance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.alreadyMarked ? Icons.info_outline : Icons.check_circle,
          color: result.alreadyMarked ? Colors.orange : Colors.green,
          size: 40,
        ),
        title: Text(result.alreadyMarked
            ? 'Already Checked In Today'
            : 'Attendance Marked (Check-in)'),
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
          FilledButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showLeavingResultDialog(
      BuildContext context, Map<String, dynamic> result) {
    final student = result['student'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Leaving Recorded (Check-out)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student?['fullName'] ?? student?['name'] ?? '-'}'),
            const SizedBox(height: 4),
            Text('Student Code: ${student?['studentCode'] ?? '-'}'),
            const SizedBox(height: 4),
            const Text('Status: Checked Out'),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Attendance Management',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan student Check-in QR and Leaving Check-out QR directly',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Scan Attendance QR (Check-in)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _scanAttendance(context, ref),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.logout),
            label: const Text('Scan Leaving QR (Check-out)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _scanLeaving(context, ref),
          ),
          const SizedBox(height: 24),
          Text('Batch & Historical Records',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Batch Attendance & Manual Entry'),
              subtitle: const Text('Mark attendance by batch or edit entries'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/batches'),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Attendance History'),
              subtitle: const Text('Filter and review past attendance logs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/attendance/history'),
            ),
          ),
        ],
      ),
    );
  }
}
