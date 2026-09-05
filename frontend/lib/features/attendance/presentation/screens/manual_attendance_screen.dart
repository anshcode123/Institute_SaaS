import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../batches/presentation/providers/batch_providers.dart';
import '../providers/attendance_providers.dart';

const _statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];

/// Fallback for when QR isn't available: pick a date, then set each
/// enrolled student's status directly. Loads the batch's current student
/// list from the existing batch detail endpoint - no duplicate student
/// list logic.
class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key, required this.batchId, required this.batchName});

  final String batchId;
  final String batchName;

  @override
  ConsumerState<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends ConsumerState<ManualAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _statusByStudent = {};
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final batch = ref.read(batchDetailProvider(widget.batchId)).value;
    if (batch == null || batch.students.isEmpty) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      // Every enrolled student is submitted, not just ones the user
      // explicitly touched - untouched rows keep their visible default
      // (PRESENT) rather than being silently dropped from the save.
      final entries = batch.students
          .map((s) => {'studentId': s.id, 'status': _statusByStudent[s.id] ?? 'PRESENT'})
          .toList();

      await ref.read(attendanceRepositoryProvider).markManual(
            batchId: widget.batchId,
            date: _selectedDate,
            entries: entries,
          );
      ref.invalidate(batchAttendanceSummaryProvider(widget.batchId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Attendance saved')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to save attendance');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncBatch = ref.watch(batchDetailProvider(widget.batchId));

    return Scaffold(
      appBar: AppBar(title: Text('Manual Attendance — ${widget.batchName}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: asyncBatch.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: 'Failed to load students',
                onRetry: () => ref.invalidate(batchDetailProvider(widget.batchId)),
              ),
              data: (batch) => ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: batch.students.length,
                itemBuilder: (context, index) {
                  final student = batch.students[index];
                  final current = _statusByStudent[student.id] ?? 'PRESENT';
                  return ListTile(
                    title: Text(student.fullName),
                    trailing: DropdownButton<String>(
                      value: current,
                      items: _statuses
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _statusByStudent[student.id] = value);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
