import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/announcement_repository_impl.dart';
import '../../domain/announcement_models.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) => AnnouncementRepository());

final adminAnnouncementsProvider = FutureProvider.autoDispose<List<Announcement>>((ref) async {
  return ref.watch(announcementRepositoryProvider).listForAdmin();
});

final myAnnouncementsProvider = FutureProvider.autoDispose<List<Announcement>>((ref) async {
  return ref.watch(announcementRepositoryProvider).listForStudent();
});

final childAnnouncementsProvider =
    FutureProvider.autoDispose.family<List<Announcement>, String>((ref, studentId) async {
  return ref.watch(announcementRepositoryProvider).listForChild(studentId);
});
