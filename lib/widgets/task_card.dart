import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final Function(String) onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'accepted':
        return Icons.play_circle_outline;
      case 'postponed':
        return Icons.pause_circle_outline;
      case 'archived':
        return Icons.archive_outlined;
      default:
        return Icons.task_alt;
    }
  }

  Widget? _buildOwnershipBadge(bool isWeb) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    String? label;
    Color color;
    if (task.userId == currentUserId) {
      label = 'Моя';
      color = const Color(0xFF2563EB);
    } else if (task.assignedToUserId == currentUserId) {
      label = 'Назначена мне';
      color = const Color(0xFF7C3AED);
    } else {
      return null;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 14 : 10,
        vertical: isWeb ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isWeb ? 15 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final statusColor = getStatusColor(task.status);
    final statusBgColor = getStatusBackgroundColor(task.status);
    final isWeb = kIsWeb;
    final ownershipBadge = _buildOwnershipBadge(isWeb);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWeb ? 20 : 16,
        vertical: isWeb ? 10 : 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.5),
              width: isWeb ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [statusBgColor, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
                ),
                padding: EdgeInsets.all(isWeb ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isWeb ? 10 : 8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              isWeb ? 12 : 10,
                            ),
                          ),
                          child: Icon(
                            _getStatusIcon(),
                            color: statusColor,
                            size: isWeb ? 26 : 20,
                          ),
                        ),
                        SizedBox(width: isWeb ? 16 : 12),
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: isWeb ? 20 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  decoration: task.status == 'archived'
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        SizedBox(width: isWeb ? 12 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 16 : 12,
                            vertical: isWeb ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              isWeb ? 16 : 12,
                            ),
                            border: Border.all(
                              color: priorityColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            getPriorityDisplayName(task.priority),
                            style: TextStyle(
                              fontSize: isWeb ? 16 : 12,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      SizedBox(height: isWeb ? 16 : 12),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isWeb ? 18 : 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    SizedBox(height: isWeb ? 16 : 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: isWeb ? 12 : 8,
                            runSpacing: isWeb ? 8 : 6,
                            children: [
                              if (task.dueAt != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWeb ? 14 : 10,
                                    vertical: isWeb ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.dueAt!.isBefore(DateTime.now())
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      isWeb ? 10 : 8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: isWeb ? 18 : 14,
                                        color:
                                            task.dueAt!.isBefore(DateTime.now())
                                            ? Colors.red
                                            : Colors.blue,
                                      ),
                                      SizedBox(width: isWeb ? 8 : 6),
                                      Text(
                                        '${task.dueAt!.day}.${task.dueAt!.month.toString().padLeft(2, '0')}.${task.dueAt!.year} ${task.dueAt!.hour}:${task.dueAt!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: isWeb ? 16 : 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              task.dueAt!.isBefore(
                                                DateTime.now(),
                                              )
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (task.assignedToUserName != null &&
                                  task.assignedToUserName!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWeb ? 14 : 10,
                                    vertical: isWeb ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      isWeb ? 10 : 8,
                                    ),
                                    border: Border.all(
                                      color: Colors.purple.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: isWeb ? 18 : 14,
                                        color: Colors.purple,
                                      ),
                                      SizedBox(width: isWeb ? 8 : 6),
                                      Text(
                                        task.assignedToUserName!,
                                        style: TextStyle(
                                          fontSize: isWeb ? 16 : 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (ownershipBadge != null) ownershipBadge,
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb ? 14 : 10,
                                  vertical: isWeb ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    isWeb ? 10 : 8,
                                  ),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  getStatusDisplayName(task.status),
                                  style: TextStyle(
                                    fontSize: isWeb ? 16 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: isWeb ? 26 : 20,
                            color: Colors.grey[600],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isWeb ? 16 : 12,
                            ),
                          ),
                          onSelected: onStatusChanged,
                          itemBuilder: (context) => AppConstants.allStatuses
                              .where((s) => s != task.status)
                              .map(
                                (status) => PopupMenuItem(
                                  value: status,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWeb ? 20 : 16,
                                    vertical: isWeb ? 12 : 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIconForStatus(status),
                                        size: isWeb ? 22 : 18,
                                        color: const Color(0xFF6366F1),
                                      ),
                                      SizedBox(width: isWeb ? 16 : 12),
                                      Text(
                                        getStatusDisplayName(status),
                                        style: TextStyle(
                                          fontSize: isWeb ? 18 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIconForStatus(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'accepted':
        return Icons.play_circle_outline;
      case 'postponed':
        return Icons.pause_circle_outline;
      case 'archived':
        return Icons.archive_outlined;
      default:
        return Icons.task_alt;
    }
  }
}
