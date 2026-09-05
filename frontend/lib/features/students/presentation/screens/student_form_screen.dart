import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/student_providers.dart';

/// Single screen for both Add and Edit - editingId == null means "Add".
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.editingId});

  final String? editingId;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentCodeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  bool _prefilled = false;

  bool get _isEditing => widget.editingId != null;

  @override
  void dispose() {
    _studentCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(AsyncValue? asyncStudent) {
    if (_prefilled || asyncStudent == null || !asyncStudent.hasValue) return;
    final student = asyncStudent.value;
    if (student == null) return;
    _studentCodeController.text = student.studentCode;
    _firstNameController.text = student.firstName;
    _lastNameController.text = student.lastName;
    _phoneController.text = student.phone ?? '';
    _emailController.text = student.email ?? '';
    _addressController.text = student.address ?? '';
    _prefilled = true;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'studentCode': _studentCodeController.text.trim(),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
    };

    try {
      final repository = ref.read(studentRepositoryProvider);
      if (_isEditing) {
        await repository.update(widget.editingId!, data);
        ref.invalidate(studentDetailProvider(widget.editingId!));
      } else {
        await repository.create(data);
      }
      ref.read(studentListControllerProvider.notifier).load();
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _errorMessage = e is AppException ? e.message : 'Something went wrong';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      final asyncStudent = ref.watch(studentDetailProvider(widget.editingId!));
      _prefillIfNeeded(asyncStudent);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Student' : 'Add Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _studentCodeController,
              decoration: const InputDecoration(labelText: 'Student Code / Roll Number', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Student'),
            ),
          ],
        ),
      ),
    );
  }
}
