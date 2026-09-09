import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../../../announcements/presentation/screens/announcement_list_view.dart';

class ChildAnnouncementsScreen extends ConsumerWidget {
  const ChildAnnouncementsScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childAnnouncementsProvider(studentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: AnnouncementListView(
        asyncAnnouncements: async,
        onRetry: () => ref.invalidate(childAnnouncementsProvider(studentId)),
      ),
    );
  }
}
