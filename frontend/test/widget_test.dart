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
  @override
  Future<AuthSession> loginInstitute({required String instituteCode, required String password}) => throw UnimplementedError();
  @override
  Future<AuthSession> loginSuperAdmin({required String email, required String password}) => throw UnimplementedError();
  @override
  Future<AuthSession> loginTeacher({required String email, required String password}) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession?> restoreSession() async => null;
}

void main() {
  Widget harness(Widget child, {AuthController? auth}) => ProviderScope(
        overrides: [
          institutesProvider.overrideWith((ref) => InstitutesNotifier(_FakeInstitutesRepository())),
          authControllerProvider.overrideWith((ref) => auth ?? AuthController(_FakeAuthRepository())),
        ],
        child: MaterialApp(home: child),
      );

  testWidgets('institute admin home renders institute modules', (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '1', name: 'Admin', role: 'INSTITUTE_ADMIN'),
    );
    await tester.pump();
    expect(find.text('Signed in as Admin\nRole: INSTITUTE_ADMIN'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
    expect(find.text('Batches'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
  });

  testWidgets('super admin home renders institute dashboard', (tester) async {
    final auth = AuthController(_FakeAuthRepository());
    await tester.pumpWidget(harness(const HomeScreen(), auth: auth));
    auth.state = const AuthState.authenticated(
      AuthUser(id: '1', name: 'Admin', role: 'SUPER_ADMIN'),
    );
    await tester.pump();
    expect(find.text('Super Admin Dashboard'), findsOneWidget);
    expect(find.text('Total Institutes'), findsOneWidget);
    expect(find.text('Create Institute'), findsOneWidget);
    expect(find.text('Students'), findsNothing);
  });

  testWidgets('institutes screen renders empty state', (tester) async {
    await tester.pumpWidget(harness(const InstitutesScreen()));
    await tester.pump();
    expect(find.text('No institutes yet'), findsOneWidget);
    expect(find.text('Create institute'), findsOneWidget);
  });

  testWidgets('create institute form validates required fields', (tester) async {
    await tester.pumpWidget(harness(const CreateInstituteScreen()));
    await tester.tap(find.text('Create institute'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(3));
  });
}
