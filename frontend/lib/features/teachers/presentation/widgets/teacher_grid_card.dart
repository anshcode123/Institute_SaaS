import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/teacher_models.dart';

class TeacherGridCard extends StatelessWidget {
  const TeacherGridCard({super.key, required this.teacher, required this.onTap});

  final Teacher teacher;
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
                    backgroundImage: teacher.profilePhoto != null
                        ? NetworkImage(teacher.profilePhoto!)
                        : null,
                    child: teacher.profilePhoto == null
                        ? Text(teacher.name[0])
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      teacher.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (teacher.phone != null || teacher.email != null)
                Text(
                  teacher.phone ?? teacher.email ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              StatusBadge(status: teacher.status),
            ],
          ),
        ),
      ),
    );
  }
}
