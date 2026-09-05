import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/batch_providers.dart';

class BatchFormScreen extends ConsumerStatefulWidget {
  const BatchFormScreen({super.key, this.editingId});

  final String? editingId;

  @override
  ConsumerState<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends ConsumerState<BatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  bool _prefilled = false;

  bool get _isEditing => widget.editingId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(AsyncValue? asyncBatch) {
    if (_prefilled || asyncBatch == null || !asyncBatch.hasValue) return;
    final batch = asyncBatch.value;
    if (batch == null) return;
    _nameController.text = batch.name;
    _descriptionController.text = batch.description ?? '';
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
    };

    try {
      final repository = ref.read(batchRepositoryProvider);
      if (_isEditing) {
        await repository.update(widget.editingId!, data);
        ref.invalidate(batchDetailProvider(widget.editingId!));
      } else {
        await repository.create(data);
      }
      ref.read(batchListControllerProvider.notifier).load();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = e is AppException ? e.message : 'Something went wrong');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      final asyncBatch = ref.watch(batchDetailProvider(widget.editingId!));
      _prefillIfNeeded(asyncBatch);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Batch' : 'Create Batch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Batch Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Create Batch'),
            ),
          ],
        ),
      ),
    );
  }
}
