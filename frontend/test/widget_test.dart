import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_saas/features/auth/domain/auth_models.dart';
import 'package:student_saas/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_saas/features/auth/presentation/providers/auth_state.dart';
import 'package:student_saas/features/auth/presentation/screens/home_screen.dart';
import 'package:student_saas/features/auth/domain/auth_repository.dart';
import 'package:student_saas/features/institutes/domain/institute.dart';
import 'package:student_saas/features/institutes/domain/institutes_repository.dart';
import 'package:student_saas/features/institutes/presentation/providers/institutes_provider.dart';
import 'package:student_saas/features/institutes/presentation/screens/create_institute_screen.dart';
import 'package:student_saas/features/institutes/presentation/screens/institutes_screen.dart';

import 'package:student_saas/core/router/app_router.dart';
import 'package:student_saas/core/network/paginated_result.dart';
import 'package:student_saas/features/parent_portal/presentation/providers/parent_portal_providers.dart';
import 'package:student_saas/features/student_portal/presentation/providers/student_portal_providers.dart';
import 'package:student_saas/features/student_portal/domain/student_dashboard.dart';
import 'package:student_saas/features/students/domain/student_models.dart';
import 'package:student_saas/features/students/domain/student_repository.dart';
import 'package:student_saas/features/students/presentation/providers/student_providers.dart';
import 'package:student_saas/features/parents/domain/parent_models.dart';
import 'package:student_saas/features/parents/domain/parent_repository.dart';
import 'package:student_saas/features/parents/presentation/providers/parent_providers.dart';
import 'package:student_saas/features/fees/domain/fee_models.dart';
import 'package:student_saas/features/notifications/presentation/providers/notification_providers.dart';
import 'package:student_saas/features/notifications/domain/notification_models.dart';

class _FakeInstitutesRepository implements InstitutesRepository {
  @override
  Future<List<Institute>> getInstitutes() async => const [];

  @override
  Future<InstituteCreationResult> createInstitute({
    required String name,
    required String email,
    required String adminName,
    String? phone,
    String? address,
  }) async {
    throw StateError('not used');
  }

  @override
  Future<Institute> updateStatus(String id, InstituteStatus status) async {
    throw StateError('not used');
  }
}

class _FakeAuthRepository implements AuthRepository {
  final AuthSession? currentSession;
  _FakeAuthRepository([this.currentSession]);

  @override
  Future<AuthSession> loginInstitute(
          {required String instituteCode, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthSession> loginSuperAdmin(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthSession> loginTeacher(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthSession> loginStudent(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthSession> loginParent(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession?> restoreSession() async => currentSession;
}

class _FakeStudentRepository implements StudentRepository {
  @override
  Future<PaginatedResult<Student>> list({
    String? query,
    String? status,
    String? batchId,
    int page = 1,
  }) async {
    return PaginatedResult(
      items: [
        Student(
          id: 'std_1',
          studentCode: 'S001',
          firstName: 'John',
          lastName: 'Doe',
          admissionDate: DateTime(2026, 1, 1),
          status: 'ACTIVE',
        ),
      ],
      total: 1,
      page: 1,
      limit: 10,
    );
  }

  @override
  Future<Student> getById(String id) async => throw UnimplementedError();
  @override
  Future<Student> create(Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<Student> update(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<void> deactivate(String id) async {}
  @override
  Future<void> linkParent(String studentId, String parentId,
      {String? relationship}) async {}
  @override
  Future<void> unlinkParent(String studentId, String parentId) async {}
  @override
  Future<Student> assignBatch(String studentId, String batchId) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> createLogin(String studentId,
          {String? loginId, String? password}) async =>
      {};
  @override
  Future<Map<String, dynamic>> resetPassword(String studentId,
          {String? newPassword}) async =>
      {};
}

class _FakeParentRepository implements ParentRepository {
  @override
  Future<PaginatedResult<Parent>> list({
    String? query,
    String? status,
    int page = 1,
  }) async {
    return const PaginatedResult(
      items: [
        Parent(
          id: 'par_1',
          name: 'Parent Jane',
          status: 'ACTIVE',
        ),
      ],
      total: 1,
      page: 1,
      limit: 10,
    );
  }

  @override
  Future<Parent> getById(String id) async => throw UnimplementedError();
  @override
  Future<Parent> create(Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<Parent> update(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<void> deactivate(String id) async {}
  @override
  Future<Map<String, dynamic>> createLogin(String parentId,
          {String? loginId, String? password}) async =>
      {};
  @override
  Future<Map<String, dynamic>> resetPassword(String parentId,
          {String? newPassword}) async =>
      {};
}

void main() {
  Widget harness(Widget child, {AuthController? auth}) => ProviderScope(
        overrides: [
          institutesProvider.overrideWith(
              (ref) => InstitutesNotifier(_FakeInstitutesRepository())),
          studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
          parentRepositoryProvider.overrideWithValue(_FakeParentRepository()),
          authControllerProvider.overrideWith(
              (ref) => auth ?? AuthController(_FakeAuthRepository())),
          notificationsProvider.overrideWith((ref) async =>
              const NotificationsPage(items: [], total: 0, unreadCount: 0)),
          myChildrenProvider.overrideWith((ref) async => const []),
          myDashboardProvider.overrideWith((ref) async => StudentDashboard(
                student: Student(
                  id: 's1',
                  studentCode: 'S001',
                  firstName: 'Alice',
                  lastName: 'Student',
                  admissionDate: DateTime(2026, 1, 1),
                  status: 'ACTIVE',
                ),
                feesSummary: const StudentFeesSummary(
                  totalAmount: 0,
                  discountAmount: 0,
                  finalAmount: 0,
                  paidAmount: 0,
                  outstandingAmount: 0,
                ),
                unreadNotificationCount: 0,
              )),
        ],
        child: MaterialApp(home: child),
      );

  Widget routerHarness({AuthController? auth}) => ProviderScope(
        overrides: [
          institutesProvider.overrideWith(
              (ref) => InstitutesNotifier(_FakeInstitutesRepository())),
          studentRepositoryProvider.overrideWithValue(_FakeStudentRepository()),
          parentRepositoryProvider.overrideWithValue(_FakeParentRepository()),
          authControllerProvider.overrideWith(
              (ref) => auth ?? AuthController(_FakeAuthRepository())),
          notificationsProvider.overrideWith((ref) async =>
              const NotificationsPage(items: [], total: 0, unreadCount: 0)),
          myChildrenProvider.overrideWith((ref) async => const []),
          myDashboardProvider.overrideWith((ref) async => StudentDashboard(
                student: Student(
                  id: 's1',
                  studentCode: 'S001',
                  firstName: 'Alice',
                  lastName: 'Student',
                  admissionDate: DateTime(2026, 1, 1),
                  status: 'ACTIVE',
                ),
                feesSummary: const StudentFeesSummary(
                  totalAmount: 0,
                  discountAmount: 0,
                  finalAmount: 0,
                  paidAmount: 0,
                  outstandingAmount: 0,
                ),
                unreadNotificationCount: 0,
              )),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      );

  testWidgets('institute admin home renders institute modules', (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '1', name: 'Admin', role: 'INSTITUTE_ADMIN'),
    );
    await tester.pump();
    expect(
        find.text('Signed in as Admin\nRole: INSTITUTE_ADMIN'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
    expect(find.text('Batches'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('Fees'), findsOneWidget);
  });

  testWidgets('teacher home renders teacher modules and hides admin-only cards',
      (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '2', name: 'Teacher Jane', role: 'TEACHER'),
    );
    await tester.pump();
    expect(
        find.text('Signed in as Teacher Jane\nRole: TEACHER'), findsOneWidget);
    expect(find.text('My Batches'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('My Tests'), findsOneWidget);
    expect(find.text('Students'), findsNothing);
    expect(find.text('Parents'), findsNothing);
    expect(find.text('Teachers'), findsNothing);
    expect(find.text('Fees'), findsNothing);
  });

  testWidgets('institutes screen renders empty state', (tester) async {
    await tester.pumpWidget(harness(const InstitutesScreen()));
    await tester.pump();
    expect(find.text('No institutes yet'), findsOneWidget);
    expect(find.text('Create institute'), findsOneWidget);
  });

  testWidgets('create institute form validates required fields',
      (tester) async {
    await tester.pumpWidget(harness(const CreateInstituteScreen()));
    await tester.tap(find.text('Create institute'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(3));
  });

  test('defaultLocationForRole routes every role to its appropriate portal',
      () {
    expect(defaultLocationForRole('SUPER_ADMIN'), '/institutes');
    expect(defaultLocationForRole('STUDENT'), '/student/dashboard');
    expect(defaultLocationForRole('PARENT'), '/parent/children');
    expect(defaultLocationForRole('TEACHER'), '/home');
    expect(defaultLocationForRole('INSTITUTE_ADMIN'), '/home');
    expect(defaultLocationForRole(null), '/home');
  });

  testWidgets(
      'parent home renders parent dashboard and hides institute modules',
      (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '3', name: 'Parent John', role: 'PARENT'),
    );
    await tester.pump();
    expect(find.text('My Children'), findsOneWidget);
    expect(find.text('Students'), findsNothing);
    expect(find.text('Parents'), findsNothing);
    expect(find.text('Teachers'), findsNothing);
    expect(find.text('Fees'), findsNothing);
  });

  testWidgets(
      'student home renders student dashboard and hides institute modules',
      (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '4', name: 'Student Alice', role: 'STUDENT'),
    );
    await tester.pump();
    expect(find.text('My Dashboard'), findsOneWidget);
    expect(find.text('Students'), findsNothing);
    expect(find.text('Parents'), findsNothing);
    expect(find.text('Teachers'), findsNothing);
    expect(find.text('Fees'), findsNothing);
  });

  testWidgets(
      'clicking Students navigates to Students screen and back for institute admin',
      (tester) async {
    const session = AuthSession(
      user: AuthUser(id: '1', name: 'Admin', role: 'INSTITUTE_ADMIN'),
      accessToken: 'acc',
      refreshToken: 'ref',
    );
    final auth = AuthController(_FakeAuthRepository(session));

    await tester.pumpWidget(routerHarness(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Institute Dashboard'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);

    // Tap Students
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();

    // Verify Students screen opened
    expect(find.text('Search students'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Go back
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Verify back on Institute Dashboard
    expect(find.text('Institute Dashboard'), findsOneWidget);
  });

  testWidgets(
      'clicking Parents navigates to Parents screen and back for institute admin',
      (tester) async {
    const session = AuthSession(
      user: AuthUser(id: '1', name: 'Admin', role: 'INSTITUTE_ADMIN'),
      accessToken: 'acc',
      refreshToken: 'ref',
    );
    final auth = AuthController(_FakeAuthRepository(session));

    await tester.pumpWidget(routerHarness(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Institute Dashboard'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);

    // Tap Parents
    await tester.tap(find.text('Parents'));
    await tester.pumpAndSettle();

    // Verify Parents screen opened
    expect(find.text('Search parents'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Go back
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Verify back on Institute Dashboard
    expect(find.text('Institute Dashboard'), findsOneWidget);
  });
}
