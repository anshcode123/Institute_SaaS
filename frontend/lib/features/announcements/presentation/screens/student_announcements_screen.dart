import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/announcement_providers.dart';
import 'announcement_list_view.dart';

class StudentAnnouncementsScreen extends ConsumerWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAnnouncementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: AnnouncementListView(
        asyncAnnouncements: async,
        onRetry: () => ref.invalidate(myAnnouncementsProvider),
      ),
    );
  }
}
