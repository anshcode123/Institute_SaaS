import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../batches/presentation/providers/batch_providers.dart';
import '../providers/test_providers.dart';

/// The core teacher workflow: Subject -> student list -> enter/edit
/// marks -> save. Loads the batch's student roster via the existing
/// batch detail endpoint (no duplicate student-list logic) and any
/// already-saved marks for this subject to prefill the fields.
class MarksEntryScreen extends ConsumerStatefulWidget {
  const MarksEntryScreen({
    super.key,
    required this.testId,
    required this.subjectId,
    required this.subjectName,
    required this.maxMarks,
  });

  final String testId;
  final String subjectId;
  final String subjectName;
  final int maxMarks;

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  String? _errorMessage;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String studentId) {
    return _controllers.putIfAbsent(studentId, () => TextEditingController());
  }

  Future<void> _prefillExisting() async {
    if (_prefilled) return;
    _prefilled = true;
    try {
      final marks = await ref.read(testRepositoryProvider).listMarks(widget.testId, subjectId: widget.subjectId);
      for (final m in marks) {
        _controllerFor(m.student.id).text = m.obtainedMarks.toString();
      }
      if (mounted) setState(() {});
    } catch (_) {
      // No existing marks yet, or fetch failed - fields just start empty.
    }
  }

  Future<void> _save(List<String> studentIds) async {
    final entries = <Map<String, dynamic>>[];
    for (final id in studentIds) {
      final text = _controllers[id]?.text.trim();
      if (text == null || text.isEmpty) continue;
      final marks = int.tryParse(text);
      if (marks == null) continue;
      entries.add({'studentId': id, 'obtainedMarks': marks});
    }

    if (entries.isEmpty) {
      setState(() => _errorMessage = 'Enter at least one mark before saving');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(testRepositoryProvider).saveMarks(
            testId: widget.testId,
            subjectId: widget.subjectId,
            entries: entries,
          );
      ref.invalidate(testResultsProvider(widget.testId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved')));
      }
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to save marks');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTest = ref.watch(testDetailProvider(widget.testId));

    return Scaffold(
      appBar: AppBar(title: Text('Marks — ${widget.subjectName}')),
      body: asyncTest.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load test',
          onRetry: () => ref.invalidate(testDetailProvider(widget.testId)),
        ),
        data: (test) {
          final batchId = test.batch?.id;
          if (batchId == null) return const ErrorState(message: 'This test has no batch');

          final asyncBatch = ref.watch(batchDetailProvider(batchId));
          return asyncBatch.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(
              message: 'Failed to load students',
              onRetry: () => ref.invalidate(batchDetailProvider(batchId)),
            ),
            data: (batch) {
              _prefillExisting();
              final studentIds = batch.students.map((s) => s.id).toList();

              return Column(
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: batch.students.length,
                      itemBuilder: (context, index) {
                        final student = batch.students[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(student.fullName),
                            trailing: SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _controllerFor(student.id),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  isDense: true,
                                  suffixText: '/ ${widget.maxMarks}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _isSaving ? null : () => _save(studentIds),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Marks'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
