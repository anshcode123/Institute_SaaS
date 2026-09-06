import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/theme_toggle.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/login_form.dart';

class TeacherLoginScreen extends ConsumerWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) context.go('/home');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Login'),
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
                LoginForm(
                  identifierLabel: 'Email',
                  isLoading: authState.status == AuthStatus.loading,
                  errorMessage: authState.status == AuthStatus.error
                      ? authState.errorMessage
                      : null,
                  onSubmit: (email, password) {
                    ref
                        .read(authControllerProvider.notifier)
                        .loginTeacher(email: email, password: password);
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Institute login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
