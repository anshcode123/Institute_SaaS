import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/parent_models.dart';
import '../providers/parent_providers.dart';

class ParentDetailScreen extends ConsumerWidget {
  const ParentDetailScreen({super.key, required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParent = ref.watch(parentDetailProvider(parentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Details'),
        actions: [
          asyncParent.maybeWhen(
            data: (parent) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/parents/$parentId/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncParent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: 'Failed to load parent',
          onRetry: () => ref.invalidate(parentDetailProvider(parentId)),
        ),
        data: (parent) => _ParentBody(parent: parent, parentId: parentId),
      ),
    );
  }
}

class _ParentBody extends ConsumerWidget {
  const _ParentBody({required this.parent, required this.parentId});

  final Parent parent;
  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(parent.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        StatusBadge(status: parent.status),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${parent.phone ?? '-'}'),
                const SizedBox(height: 4),
                Text('Email: ${parent.email ?? '-'}'),
                const SizedBox(height: 4),
                Text('Address: ${parent.address ?? '-'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Linked Students',
                    style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                if (parent.students.isEmpty)
                  const Text('No students linked yet'),
                for (final s in parent.students)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${s.fullName} (${s.relationship})'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Login Account',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        parent.hasLogin
                            ? 'Parent can sign in (${parent.loginEmail ?? parent.email})'
                            : 'Enable portal access for this parent',
                      ),
                    ],
                  ),
                ),
                if (!parent.hasLogin)
                  FilledButton(
                    onPressed: () => _createLogin(context, ref),
                    child: const Text('Create Login'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _resetPassword(context, ref),
                    child: const Text('Reset Password'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.block),
          label: const Text('Deactivate Parent'),
          onPressed: parent.status == 'INACTIVE'
              ? null
              : () async {
                  final confirmed = await confirmAction(
                    context,
                    title: 'Deactivate parent?',
                    message:
                        'This can be reversed later by editing the parent.',
                    confirmLabel: 'Deactivate',
                  );
                  if (!confirmed) return;
                  await ref.read(parentRepositoryProvider).deactivate(parentId);
                  ref.invalidate(parentDetailProvider(parentId));
                  ref.read(parentListControllerProvider.notifier).load();
                },
        ),
      ],
    );
  }

  Future<void> _createLogin(BuildContext context, WidgetRef ref) async {
    final loginIdController = TextEditingController(text: parent.email ?? '');
    final passwordController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Parent Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: loginIdController,
              decoration: const InputDecoration(
                labelText: 'Login ID / Email',
                hintText: 'parent@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (leave blank to auto-generate)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate != true || !context.mounted) return;

    try {
      final result = await ref.read(parentRepositoryProvider).createLogin(
            parentId,
            loginId: loginIdController.text.trim().isEmpty
                ? null
                : loginIdController.text.trim(),
            password: passwordController.text.trim().isEmpty
                ? null
                : passwordController.text.trim(),
          );
      ref.invalidate(parentDetailProvider(parentId));
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Login Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Save these credentials now - the password will not be shown again.'),
              const SizedBox(height: 16),
              SelectableText('Login ID / Email: ${result['email']}'),
              const SizedBox(height: 4),
              SelectableText('Password: ${result['initialPassword']}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e is AppException ? e.message : 'Failed to create login')),
      );
    }
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Parent Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password (leave blank to auto-generate)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset != true || !context.mounted) return;

    try {
      final result = await ref.read(parentRepositoryProvider).resetPassword(
            parentId,
            newPassword: passwordController.text.trim().isEmpty
                ? null
                : passwordController.text.trim(),
          );
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New credentials for parent:'),
              const SizedBox(height: 16),
              SelectableText('Login ID / Email: ${result['email']}'),
              const SizedBox(height: 4),
              SelectableText('New Password: ${result['newPassword']}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                e is AppException ? e.message : 'Failed to reset password')),
      );
    }
  }
}
