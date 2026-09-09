import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/student_portal_repository.dart';
import '../../domain/student_dashboard.dart';

final studentPortalRepositoryProvider = Provider<StudentPortalRepository>((ref) => StudentPortalRepository());

final myDashboardProvider = FutureProvider.autoDispose<StudentDashboard>((ref) async {
  return ref.watch(studentPortalRepositoryProvider).getMyDashboard();
});
