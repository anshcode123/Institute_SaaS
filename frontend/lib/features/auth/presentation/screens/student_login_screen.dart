import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/theme_toggle.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/login_form.dart';

class StudentLoginScreen extends ConsumerWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) context.go('/student/dashboard');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        actions: const [ThemeToggle()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in to Student Portal',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LoginForm(
                  identifierLabel: 'Email / Login ID',
                  isLoading: authState.status == AuthStatus.loading,
                  errorMessage: authState.status == AuthStatus.error
                      ? authState.errorMessage
                      : null,
                  onSubmit: (email, password) {
                    ref.read(authControllerProvider.notifier).loginStudent(
                          email: email,
                          password: password,
                        );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Institute Login'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/parent/login'),
                      child: const Text('Parent Login'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/teacher/login'),
                      child: const Text('Teacher Login'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/super-admin/login'),
                      child: const Text('Super Admin'),
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
