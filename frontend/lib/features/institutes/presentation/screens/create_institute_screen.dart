import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/institutes_provider.dart';

class CreateInstituteScreen extends ConsumerStatefulWidget {
  const CreateInstituteScreen({super.key});

  @override
  ConsumerState<CreateInstituteScreen> createState() => _CreateInstituteScreenState();
}

class _CreateInstituteScreenState extends ConsumerState<CreateInstituteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _adminName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _adminName, _phone, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(institutesProvider.notifier).create(
            name: _name.text.trim(),
            email: _email.text.trim(),
            adminName: _adminName.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
          );
      if (!mounted || result == null) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Institute Created Successfully'),
          content: SelectableText(
            'Institute ID: ${result.instituteCode}\n'
            'Institute Name: ${result.institute.name}\n'
            'Institute Admin: ${_adminName.text.trim()}\n\n'
            'Initial password: ${result.initialPassword}\n\n'
            'Save these credentials securely. The password will not be shown again.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
      if (mounted) context.go('/institutes');
    } catch (_) {
      if (mounted) {
        final message = ref.read(institutesProvider).errorMessage ?? 'Unable to create institute.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Institute')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Institute details', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  _field(_name, 'Institute name', validator: (value) {
                    final error = _required(value);
                    return error ?? (value!.trim().length < 2 ? 'Use at least 2 characters' : null);
                  }),
                  _field(_email, 'Email', keyboardType: TextInputType.emailAddress, validator: (value) {
                    final error = _required(value);
                    return error ?? (!value!.contains('@') ? 'Enter a valid email' : null);
                  }),
                  _field(_adminName, 'Institute admin name', validator: _required),
                  _field(_phone, 'Phone', keyboardType: TextInputType.phone),
                  _field(_address, 'Address', maxLines: 3),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_business),
                    label: const Text('Create institute'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
