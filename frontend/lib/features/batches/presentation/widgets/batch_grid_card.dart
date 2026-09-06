import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/batch_models.dart';

class BatchGridCard extends StatelessWidget {
  const BatchGridCard({super.key, required this.batch, required this.onTap});

  final Batch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batch.name,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (batch.studentCount != null)
                Text(
                  '${batch.studentCount} students',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              StatusBadge(status: batch.status),
            ],
          ),
        ),
      ),
    );
  }
}
