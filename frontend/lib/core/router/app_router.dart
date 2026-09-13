import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/institute_login_screen.dart';
import '../../features/auth/presentation/screens/super_admin_login_screen.dart';
import '../../features/auth/presentation/screens/teacher_login_screen.dart';
import '../../features/auth/presentation/screens/student_login_screen.dart';
import '../../features/auth/presentation/screens/parent_login_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/announcements/presentation/screens/student_announcements_screen.dart';
import '../../features/student_portal/presentation/screens/student_dashboard_screen.dart';
import '../../features/student_portal/presentation/screens/student_attendance_history_screen.dart';
import '../../features/student_portal/presentation/screens/student_leaving_qr_screen.dart';
import '../../features/student_portal/presentation/screens/student_fees_screen.dart';
import '../../features/student_portal/presentation/screens/student_results_screen.dart';
import '../../features/student_portal/presentation/screens/student_result_view_screen.dart';
import '../../features/parent_portal/presentation/screens/children_list_screen.dart';
import '../../features/parent_portal/presentation/screens/child_dashboard_screen.dart';
import '../../features/parent_portal/presentation/screens/child_attendance_screen.dart';
import '../../features/parent_portal/presentation/screens/child_fees_screen.dart';
import '../../features/parent_portal/presentation/screens/child_results_screen.dart';
import '../../features/parent_portal/presentation/screens/child_result_view_screen.dart';
import '../../features/parent_portal/presentation/screens/child_announcements_screen.dart';
import '../../features/attendance/presentation/screens/attendance_hub_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/batch_attendance_screen.dart';
import '../../features/attendance/presentation/screens/manual_attendance_screen.dart';
import '../../features/batches/presentation/screens/batch_detail_screen.dart';
import '../../features/batches/presentation/screens/batch_form_screen.dart';
import '../../features/batches/presentation/screens/batches_list_screen.dart';
import '../../features/fees/presentation/screens/all_student_fees_screen.dart';
import '../../features/fees/presentation/screens/assign_fee_screen.dart';
import '../../features/fees/presentation/screens/fee_dashboard_screen.dart';
import '../../features/fees/presentation/screens/fee_structure_detail_screen.dart';
import '../../features/fees/presentation/screens/fee_structure_form_screen.dart';
import '../../features/fees/presentation/screens/fee_structures_list_screen.dart';
import '../../features/fees/presentation/screens/payment_history_screen.dart';
import '../../features/fees/presentation/screens/receipt_screen.dart';
import '../../features/fees/presentation/screens/record_payment_screen.dart';
import '../../features/fees/presentation/screens/student_fee_detail_screen.dart';
import '../../features/parents/presentation/screens/parent_detail_screen.dart';
import '../../features/parents/presentation/screens/parent_form_screen.dart';
import '../../features/parents/presentation/screens/parents_list_screen.dart';
import '../../features/students/presentation/screens/link_parent_screen.dart';
import '../../features/students/presentation/screens/student_form_screen.dart';
import '../../features/students/presentation/screens/student_profile_screen.dart';
import '../../features/students/presentation/screens/students_list_screen.dart';
import '../../features/teachers/presentation/screens/teacher_detail_screen.dart';
import '../../features/teachers/presentation/screens/teacher_form_screen.dart';
import '../../features/teachers/presentation/screens/teachers_list_screen.dart';
import '../../features/tests/presentation/screens/marks_entry_screen.dart';
import '../../features/tests/presentation/screens/student_result_detail_screen.dart';
import '../../features/tests/presentation/screens/test_detail_screen.dart';
import '../../features/tests/presentation/screens/test_form_screen.dart';
import '../../features/tests/presentation/screens/test_results_screen.dart';
import '../../features/tests/presentation/screens/tests_list_screen.dart';
import '../../features/institutes/domain/institute.dart';
import '../../features/institutes/presentation/screens/institutes_screen.dart';
import '../../features/institutes/presentation/screens/create_institute_screen.dart';
import '../../features/institutes/presentation/screens/institute_details_screen.dart';

String defaultLocationForRole(String? role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return '/institutes';
    case 'STUDENT':
      return '/student/dashboard';
    case 'PARENT':
      return '/parent/children';
    case 'TEACHER':
    case 'INSTITUTE_ADMIN':
    default:
      return '/home';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/' ||
          state.matchedLocation == '/super-admin/login' ||
          state.matchedLocation == '/teacher/login' ||
          state.matchedLocation == '/student/login' ||
          state.matchedLocation == '/parent/login';

      // Auth not resolved yet (checking secure storage on boot) - stay put.
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!authState.isAuthenticated) {
        if (!loggingIn) return '/';
        return null;
      }

      final role = authState.user?.role;
      final defaultLoc = defaultLocationForRole(role);

      // Authenticated user attempting to access login screens
      if (loggingIn) {
        return defaultLoc;
      }

      final path = state.matchedLocation;

      // Super Admin routes: only SUPER_ADMIN
      if (path.startsWith('/institutes')) {
        if (role != 'SUPER_ADMIN') return defaultLoc;
        return null;
      }

      // Student portal routes: only STUDENT
      if (path == '/student' || path.startsWith('/student/')) {
        if (role != 'STUDENT') return defaultLoc;
        return null;
      }

      // Parent portal routes: only PARENT
      if (path == '/parent' || path.startsWith('/parent/')) {
        if (role != 'PARENT') return defaultLoc;
        return null;
      }

      // Notifications: all authenticated roles allowed
      if (path == '/notifications') {
        return null;
      }

      // Institute-Admin-only routes (Teacher/Student/Parent blocked)
      if (path.startsWith('/students') ||
          path.startsWith('/parents') ||
          path.startsWith('/teachers') ||
          path.startsWith('/fees') ||
          path.startsWith('/payments') ||
          path.startsWith('/receipts')) {
        if (role != 'INSTITUTE_ADMIN') return defaultLoc;
        return null;
      }

      // Teacher & Institute-Admin shared routes: Batches, Attendance, Tests
      if (path.startsWith('/batches') ||
          path.startsWith('/attendance') ||
          path.startsWith('/tests')) {
        if (role != 'INSTITUTE_ADMIN' && role != 'TEACHER') return defaultLoc;
        return null;
      }

      // Home route: redirect roles with dedicated portals to their portals
      if (path == '/home') {
        if (role == 'SUPER_ADMIN' || role == 'STUDENT' || role == 'PARENT') {
          return defaultLoc;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/', builder: (context, state) => const InstituteLoginScreen()),
      GoRoute(
        path: '/super-admin/login',
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),
      GoRoute(
        path: '/teacher/login',
        builder: (context, state) => const TeacherLoginScreen(),
      ),
      GoRoute(
        path: '/student/login',
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: '/parent/login',
        builder: (context, state) => const ParentLoginScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // Super Admin
      GoRoute(
        path: '/institutes',
        builder: (context, state) => const InstitutesScreen(),
      ),
      GoRoute(
        path: '/institutes/create',
        builder: (context, state) => const CreateInstituteScreen(),
      ),
      GoRoute(
        path: '/institutes/:id',
        builder: (context, state) {
          final institute = state.extra as Institute?;
          if (institute != null) {
            return InstituteDetailsScreen(institute: institute);
          }
          return const InstitutesScreen();
        },
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Student Portal
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/student/attendance-history',
        builder: (context, state) => const StudentAttendanceHistoryScreen(),
      ),
      GoRoute(
        path: '/student/leaving-qr',
        builder: (context, state) => const StudentLeavingQrScreen(),
      ),
      GoRoute(
        path: '/student/fees',
        builder: (context, state) => const StudentFeesScreen(),
      ),
      GoRoute(
        path: '/student/results',
        builder: (context, state) => const StudentResultsScreen(),
      ),
      GoRoute(
        path: '/student/results/:resultId',
        builder: (context, state) => StudentResultViewScreen(
          resultId: state.pathParameters['resultId']!,
        ),
      ),
      GoRoute(
        path: '/student/announcements',
        builder: (context, state) => const StudentAnnouncementsScreen(),
      ),

      // Parent Portal
      GoRoute(
        path: '/parent/children',
        builder: (context, state) => const ChildrenListScreen(),
      ),
      GoRoute(
        path: '/parent/children/:studentId',
        builder: (context, state) => ChildDashboardScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/parent/children/:studentId/attendance',
        builder: (context, state) => ChildAttendanceScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/parent/children/:studentId/fees',
        builder: (context, state) => ChildFeesScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/parent/children/:studentId/results',
        builder: (context, state) => ChildResultsScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: '/parent/children/:studentId/results/:resultId',
        builder: (context, state) => ChildResultViewScreen(
          studentId: state.pathParameters['studentId']!,
          resultId: state.pathParameters['resultId']!,
        ),
      ),
      GoRoute(
        path: '/parent/children/:studentId/announcements',
        builder: (context, state) => ChildAnnouncementsScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),

      // Students
      GoRoute(
          path: '/students',
          builder: (context, state) => const StudentsListScreen()),
      GoRoute(
          path: '/students/new',
          builder: (context, state) => const StudentFormScreen()),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) =>
            StudentProfileScreen(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id/edit',
        builder: (context, state) =>
            StudentFormScreen(editingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id/link-parent',
        builder: (context, state) =>
            LinkParentScreen(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id/results/:resultId',
        builder: (context, state) => StudentResultDetailScreen(
          studentId: state.pathParameters['id']!,
          resultId: state.pathParameters['resultId']!,
        ),
      ),

      // Parents
      GoRoute(
          path: '/parents',
          builder: (context, state) => const ParentsListScreen()),
      GoRoute(
          path: '/parents/new',
          builder: (context, state) => const ParentFormScreen()),
      GoRoute(
        path: '/parents/:id',
        builder: (context, state) =>
            ParentDetailScreen(parentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/parents/:id/edit',
        builder: (context, state) =>
            ParentFormScreen(editingId: state.pathParameters['id']!),
      ),

      // Teachers
      GoRoute(
          path: '/teachers',
          builder: (context, state) => const TeachersListScreen()),
      GoRoute(
          path: '/teachers/new',
          builder: (context, state) => const TeacherFormScreen()),
      GoRoute(
        path: '/teachers/:id',
        builder: (context, state) =>
            TeacherDetailScreen(teacherId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/teachers/:id/edit',
        builder: (context, state) =>
            TeacherFormScreen(editingId: state.pathParameters['id']!),
      ),

      // Batches
      GoRoute(
          path: '/batches',
          builder: (context, state) => const BatchesListScreen()),
      GoRoute(
          path: '/batches/new',
          builder: (context, state) => const BatchFormScreen()),
      GoRoute(
        path: '/batches/:id',
        builder: (context, state) =>
            BatchDetailScreen(batchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/batches/:id/edit',
        builder: (context, state) =>
            BatchFormScreen(editingId: state.pathParameters['id']!),
      ),

      // Attendance
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceHubScreen(),
      ),
      GoRoute(
        path: '/attendance/batch/:batchId',
        builder: (context, state) => BatchAttendanceScreen(
          batchId: state.pathParameters['batchId']!,
          batchName: state.uri.queryParameters['name'] ?? 'Batch',
        ),
      ),
      GoRoute(
        path: '/attendance/batch/:batchId/manual',
        builder: (context, state) => ManualAttendanceScreen(
          batchId: state.pathParameters['batchId']!,
          batchName: state.uri.queryParameters['name'] ?? 'Batch',
        ),
      ),
      GoRoute(
        path: '/attendance/history',
        builder: (context, state) => AttendanceHistoryScreen(
          initialBatchId: state.uri.queryParameters['batchId'],
          initialStudentId: state.uri.queryParameters['studentId'],
        ),
      ),

      // Fees, Payments, Receipts
      GoRoute(
          path: '/fees',
          builder: (context, state) => const FeeDashboardScreen()),
      GoRoute(
          path: '/fees/structures',
          builder: (context, state) => const FeeStructuresListScreen()),
      GoRoute(
        path: '/fees/structures/new',
        builder: (context, state) => const FeeStructureFormScreen(),
      ),
      GoRoute(
        path: '/fees/structures/:id',
        builder: (context, state) =>
            FeeStructureDetailScreen(structureId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/fees/assign',
        builder: (context, state) => AssignFeeScreen(
          preselectedFeeStructureId:
              state.uri.queryParameters['feeStructureId'],
          preselectedStudentId: state.uri.queryParameters['studentId'],
        ),
      ),
      GoRoute(
          path: '/fees/all',
          builder: (context, state) => const AllStudentFeesScreen()),
      GoRoute(
        path: '/fees/:id',
        builder: (context, state) =>
            StudentFeeDetailScreen(studentFeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/fees/:id/pay',
        builder: (context, state) => RecordPaymentScreen(
          studentFeeId: state.pathParameters['id']!,
          installmentId: state.uri.queryParameters['installmentId']!,
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => PaymentHistoryScreen(
            studentId: state.uri.queryParameters['studentId']),
      ),
      GoRoute(
        path: '/receipts/:id',
        builder: (context, state) =>
            ReceiptScreen(receiptId: state.pathParameters['id']!),
      ),

      // Tests, Marks, Results
      GoRoute(
          path: '/tests', builder: (context, state) => const TestsListScreen()),
      GoRoute(
          path: '/tests/new',
          builder: (context, state) => const TestFormScreen()),
      GoRoute(
        path: '/tests/:id',
        builder: (context, state) =>
            TestDetailScreen(testId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tests/:id/marks',
        builder: (context, state) => MarksEntryScreen(
          testId: state.pathParameters['id']!,
          subjectId: state.uri.queryParameters['subjectId']!,
          subjectName: state.uri.queryParameters['subjectName'] ?? 'Subject',
          maxMarks:
              int.tryParse(state.uri.queryParameters['maxMarks'] ?? '') ?? 100,
        ),
      ),
      GoRoute(
        path: '/tests/:id/results',
        builder: (context, state) =>
            TestResultsScreen(testId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges Riverpod state changes into something GoRouter's
/// `refreshListenable` (a plain ChangeNotifier) understands, so navigation
/// re-evaluates redirects whenever auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this.ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
  final Ref ref;
}
