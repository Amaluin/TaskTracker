class TaskStatusHistoryModel {
  final String id;
  final String taskId;
  final String? fromStatus;
  final String toStatus;
  final DateTime changedAt;
  final String changedBy;

  TaskStatusHistoryModel({
    required this.id,
    required this.taskId,
    this.fromStatus,
    required this.toStatus,
    required this.changedAt,
    required this.changedBy,
  });

  factory TaskStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return TaskStatusHistoryModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      changedAt: DateTime.parse(json['changed_at'] as String),
      changedBy: json['changed_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_at': changedAt.toIso8601String(),
      'changed_by': changedBy,
    };
  }
}
