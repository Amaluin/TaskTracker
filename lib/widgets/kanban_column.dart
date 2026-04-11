import 'package:flutter/material.dart';
import '../data/models/task_model.dart';
import '../core/constants.dart';
import 'draggable_task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String status;
  final List<TaskModel> tasks;
  final Function(TaskModel) onTaskTap;
  final Function(String taskId, String newStatus) onStatusChanged;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onTaskTap,
    required this.onStatusChanged,
  });

  Color _getStatusColor() {
    switch (status) {
      case AppConstants.statusPending:
        return const Color(0xFFF59E0B); // Amber
      case AppConstants.statusAccepted:
        return const Color(0xFF3B82F6); // Blue
      case AppConstants.statusPostponed:
        return const Color(0xFF8B5CF6); // Purple
      case AppConstants.statusArchived:
        return const Color(0xFF6B7280); // Gray
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (status) {
      case AppConstants.statusPending:
        return const Color(0xFFFEF3C7); // Light Amber
      case AppConstants.statusAccepted:
        return const Color(0xFFDBEAFE); // Light Blue
      case AppConstants.statusPostponed:
        return const Color(0xFFEDE9FE); // Light Purple
      case AppConstants.statusArchived:
        return const Color(0xFFF3F4F6); // Light Gray
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.pending_outlined;
      case AppConstants.statusAccepted:
        return Icons.play_circle_outline;
      case AppConstants.statusPostponed:
        return Icons.pause_circle_outline;
      case AppConstants.statusArchived:
        return Icons.archive_outlined;
      default:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final backgroundColor = _getStatusBackgroundColor();
    
    return DragTarget<TaskModel>(
      onWillAccept: (task) => task != null && task.status != status,
      onAccept: (task) {
        onStatusChanged(task.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isHovering 
                ? statusColor.withOpacity(0.1)
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering 
                  ? statusColor
                  : statusColor.withOpacity(0.3),
              width: isHovering ? 3 : 2,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getStatusDisplayName(status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tasks
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isHovering ? Icons.add_circle_outline : Icons.inbox_outlined,
                                size: 48,
                                color: isHovering ? statusColor : Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isHovering ? 'Отпустите здесь' : 'Нет задач',
                                style: TextStyle(
                                  color: isHovering ? statusColor : Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return DraggableTaskCard(
                            task: task,
                            onTap: () => onTaskTap(task),
                            onStatusChanged: (newStatus) =>
                                onStatusChanged(task.id, newStatus),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
