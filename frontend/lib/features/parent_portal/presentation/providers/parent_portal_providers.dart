import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/parent_portal_repository.dart';
import '../../domain/parent_portal_models.dart';

final parentPortalRepositoryProvider = Provider<ParentPortalRepository>((ref) => ParentPortalRepository());

final myChildrenProvider = FutureProvider.autoDispose<List<LinkedChild>>((ref) async {
  return ref.watch(parentPortalRepositoryProvider).getMyChildren();
});

final childDashboardProvider = FutureProvider.family<ChildDashboard, String>((ref, studentId) async {
  return ref.watch(parentPortalRepositoryProvider).getChildDashboard(studentId);
});
