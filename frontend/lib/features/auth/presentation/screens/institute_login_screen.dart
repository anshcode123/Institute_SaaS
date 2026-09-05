import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/login_form.dart';
import '../../../../shared/widgets/theme_toggle.dart';

/// The only login screen institutes ever see. There is deliberately no
/// "Create Account" / "Sign up" affordance anywhere on this screen -
/// institute accounts are provisioned only by the Super Admin.
class InstituteLoginScreen extends ConsumerWidget {
  const InstituteLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) context.go('/home');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Login'),
        actions: const [ThemeToggle()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in with your Institute ID',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LoginForm(
                  identifierLabel: 'Institute ID (e.g. P10001)',
                  isLoading: authState.status == AuthStatus.loading,
                  errorMessage: authState.status == AuthStatus.error
                      ? authState.errorMessage
                      : null,
                  onSubmit: (instituteCode, password) {
                    ref
                        .read(authControllerProvider.notifier)
                        .loginInstitute(instituteCode: instituteCode, password: password);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/super-admin/login'),
                      child: const Text('Super Admin login'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/teacher/login'),
                      child: const Text('Teacher login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
