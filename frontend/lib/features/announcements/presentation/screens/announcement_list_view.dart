import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../domain/announcement_models.dart';

/// Shared rendering for "Announcements" wherever it appears (Student
/// portal, Parent portal for a selected child) - each caller supplies
/// its own already-role-scoped AsyncValue, this just renders it.
class AnnouncementListView extends StatelessWidget {
  const AnnouncementListView({super.key, required this.asyncAnnouncements, required this.onRetry});

  final AsyncValue<List<Announcement>> asyncAnnouncements;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return asyncAnnouncements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(message: 'Failed to load announcements', onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(message: 'No announcements right now.', icon: Icons.campaign_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final a = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(a.message),
                    const SizedBox(height: 8),
                    if (a.publishedAt != null)
                      Text(
                        DateFormat.yMMMd().format(a.publishedAt!),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
