import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/parent_providers.dart';

class ParentFormScreen extends ConsumerStatefulWidget {
  const ParentFormScreen({super.key, this.editingId});

  final String? editingId;

  @override
  ConsumerState<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends ConsumerState<ParentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  bool _prefilled = false;

  bool get _isEditing => widget.editingId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(AsyncValue? asyncParent) {
    if (_prefilled || asyncParent == null || !asyncParent.hasValue) return;
    final parent = asyncParent.value;
    if (parent == null) return;
    _nameController.text = parent.name;
    _phoneController.text = parent.phone ?? '';
    _emailController.text = parent.email ?? '';
    _addressController.text = parent.address ?? '';
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
      if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
    };

    try {
      final repository = ref.read(parentRepositoryProvider);
      if (_isEditing) {
        await repository.update(widget.editingId!, data);
        ref.invalidate(parentDetailProvider(widget.editingId!));
      } else {
        await repository.create(data);
      }
      ref.read(parentListControllerProvider.notifier).load();
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
      final asyncParent = ref.watch(parentDetailProvider(widget.editingId!));
      _prefillIfNeeded(asyncParent);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Parent' : 'Add Parent')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return v.contains('@') ? null : 'Invalid email';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              maxLines: 2,
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Parent'),
            ),
          ],
        ),
      ),
    );
  }
}
