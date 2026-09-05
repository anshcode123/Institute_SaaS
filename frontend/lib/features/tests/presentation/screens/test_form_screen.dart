import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../batches/presentation/providers/batch_providers.dart';
import '../providers/test_providers.dart';

class _SubjectRow {
  String? subjectId;
  final maxMarksController = TextEditingController();
  final passingMarksController = TextEditingController();
}

class TestFormScreen extends ConsumerStatefulWidget {
  const TestFormScreen({super.key});

  @override
  ConsumerState<TestFormScreen> createState() => _TestFormScreenState();
}

class _TestFormScreenState extends ConsumerState<TestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _passingMarksController = TextEditingController();
  String? _selectedBatchId;
  DateTime? _testDate;
  final List<_SubjectRow> _subjectRows = [_SubjectRow()];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passingMarksController.dispose();
    for (final row in _subjectRows) {
      row.maxMarksController.dispose();
      row.passingMarksController.dispose();
    }
    super.dispose();
  }

  int get _totalMarks => _subjectRows.fold(
        0,
        (sum, row) => sum + (int.tryParse(row.maxMarksController.text) ?? 0),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _testDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedBatchId == null) {
      setState(() => _errorMessage = 'Select a batch');
      return;
    }
    if (_testDate == null) {
      setState(() => _errorMessage = 'Select a test date');
      return;
    }
    if (_subjectRows.any((r) => r.subjectId == null)) {
      setState(() => _errorMessage = 'Select a subject for every row');
      return;
    }
    final subjectIds = _subjectRows.map((r) => r.subjectId).toSet();
    if (subjectIds.length != _subjectRows.length) {
      setState(() => _errorMessage = 'The same subject is selected more than once');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(testRepositoryProvider).createTest(
            batchId: _selectedBatchId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            testDate: _testDate!,
            durationMinutes: int.tryParse(_durationController.text),
            passingMarks: int.parse(_passingMarksController.text),
            subjects: _subjectRows
                .map((r) => {
                      'subjectId': r.subjectId,
                      'maxMarks': int.parse(r.maxMarksController.text),
                      'passingMarks': int.parse(r.passingMarksController.text),
                    })
                .toList(),
          );
      ref.read(testListControllerProvider.notifier).load();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Failed to create test');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncBatches = ref.watch(batchListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Test')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Test Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedBatchId,
              decoration: const InputDecoration(labelText: 'Batch', border: OutlineInputBorder()),
              items: asyncBatches.items
                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedBatchId = value),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Test Date'),
              subtitle: Text(_testDate != null ? DateFormat.yMMMd().format(_testDate!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (minutes, optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passingMarksController,
              decoration: const InputDecoration(labelText: 'Overall Passing Marks', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a valid number';
                if (n > _totalMarks) return 'Cannot exceed total marks ($_totalMarks)';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subjects', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => setState(() => _subjectRows.add(_SubjectRow())),
                ),
              ],
            ),
            for (var i = 0; i < _subjectRows.length; i++) _buildSubjectRow(context, i),
            const SizedBox(height: 8),
            Text('Total Marks: $_totalMarks'),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectRow(BuildContext context, int index) {
    final row = _subjectRows[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: row.subjectId,
            decoration: const InputDecoration(labelText: 'Subject ID', isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => row.subjectId = v.trim().isEmpty ? null : v.trim(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.maxMarksController,
                  decoration: const InputDecoration(labelText: 'Max Marks', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: row.passingMarksController,
                  decoration: const InputDecoration(labelText: 'Passing Marks', isDense: true),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null,
                ),
              ),
              if (_subjectRows.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _subjectRows.removeAt(index)),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
