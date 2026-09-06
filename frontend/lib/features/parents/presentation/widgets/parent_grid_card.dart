import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/parent_models.dart';

class ParentGridCard extends StatelessWidget {
  const ParentGridCard({super.key, required this.parent, required this.onTap});

  final Parent parent;
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(parent.name.isNotEmpty ? parent.name[0] : '?'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      parent.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (parent.phone != null || parent.email != null)
                Text(
                  parent.phone ?? parent.email ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              StatusBadge(status: parent.status),
            ],
          ),
        ),
      ),
    );
  }
}
