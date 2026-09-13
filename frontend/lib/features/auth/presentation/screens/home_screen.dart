import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/theme_toggle.dart';
import '../providers/auth_providers.dart';
import '../../../institutes/presentation/screens/institutes_screen.dart';
import '../../../student_portal/presentation/screens/student_dashboard_screen.dart';
import '../../../parent_portal/presentation/screens/children_list_screen.dart';

/// Role-aware Home Screen. Renders the appropriate portal dashboard for
/// Super Admin, Student, Parent, Teacher, or Institute Admin.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role;

    if (role == 'SUPER_ADMIN') {
      return const InstitutesScreen();
    }
    if (role == 'STUDENT') {
      return const StudentDashboardScreen();
    }
    if (role == 'PARENT') {
      return const ChildrenListScreen();
    }

    final isTeacher = role == 'TEACHER';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Teacher Dashboard' : 'Institute Dashboard'),
        actions: [
          const ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            user == null
                ? 'Authenticated'
                : 'Signed in as ${user.name}\nRole: ${user.role}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Student/Parent/Teacher management is Institute-Admin-only on
          // the backend - a Teacher account only manages attendance for
          // their own assigned batches, so those cards are hidden rather
          // than shown and rejected with a 403 on tap.
          if (!isTeacher) ...[
            _NavCard(
                icon: Icons.school_outlined,
                label: 'Students',
                onTap: () => context.push('/students')),
            _NavCard(
                icon: Icons.people_outline,
                label: 'Parents',
                onTap: () => context.push('/parents')),
            _NavCard(
                icon: Icons.person_outline,
                label: 'Teachers',
                onTap: () => context.push('/teachers')),
          ],
          _NavCard(
            icon: Icons.groups_outlined,
            label: isTeacher ? 'My Batches' : 'Batches',
            onTap: () => context.push('/batches'),
          ),
          _NavCard(
            icon: Icons.event_available_outlined,
            label: 'Attendance',
            onTap: () => context.push('/attendance'),
          ),
          _NavCard(
            icon: Icons.quiz_outlined,
            label: isTeacher ? 'My Tests' : 'Tests',
            onTap: () => context.push('/tests'),
          ),
          // Fees are Institute-Admin-only on the backend (spec: Teachers
          // get no financial access by default), so hidden for Teachers
          // for the same reason Students/Parents/Teachers cards are above.
          if (!isTeacher)
            _NavCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Fees',
              onTap: () => context.push('/fees'),
            ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
