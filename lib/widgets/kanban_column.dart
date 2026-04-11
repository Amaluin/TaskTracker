import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/models/task_model.dart';
import '../core/constants.dart';
import '../core/responsive_sizes.dart';
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
    return getStatusColor(status);
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
    final isWeb = kIsWeb;
    
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        onStatusChanged(details.data.id, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: isHovering 
                ? statusColor.withValues(alpha: 0.08)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            border: Border.all(
              color: isHovering 
                  ? statusColor
                  : statusColor.withValues(alpha: 0.2),
              width: isHovering ? (isWeb ? 4 : 3) : (isWeb ? 2 : 1.5),
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isWeb ? 20 : 16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isWeb ? 18 : 14),
                    topRight: Radius.circular(isWeb ? 18 : 14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isWeb ? 10 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: isWeb ? 2 : 1.5,
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
                        getStatusDisplayName(status),
                        style: TextStyle(
                          fontSize: isWeb ? 20 : 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 14 : 10, 
                        vertical: isWeb ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: isWeb ? 2 : 1.5,
                        ),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 14,
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
                          padding: EdgeInsets.all(isWeb ? 32 : 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isHovering ? Icons.add_circle_outline : Icons.inbox_outlined,
                                size: isWeb ? 62 : 48,
                                color: isHovering ? statusColor : Colors.grey[400],
                              ),
                              SizedBox(height: isWeb ? 16 : 12),
                              Text(
                                isHovering ? 'Отпустите здесь' : 'Нет задач',
                                style: TextStyle(
                                  color: isHovering ? statusColor : Colors.grey[600],
                                  fontSize: isWeb ? 18 : 14,
                                  fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isWeb ? 12 : 8),
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
