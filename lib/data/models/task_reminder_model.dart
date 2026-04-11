class TaskReminderModel {
  final String id;
  final String taskId;
  final String userId;
  final DateTime remindAt;
  final String type;
  final bool enabled;
  final DateTime createdAt;

  TaskReminderModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.remindAt,
    required this.type,
    required this.enabled,
    required this.createdAt,
  });

  factory TaskReminderModel.fromJson(Map<String, dynamic> json) {
    return TaskReminderModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      remindAt: DateTime.parse(json['remind_at'] as String),
      type: json['type'] as String,
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'remind_at': remindAt.toIso8601String(),
      'type': type,
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskReminderModel copyWith({
    String? id,
    String? taskId,
    String? userId,
    DateTime? remindAt,
    String? type,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return TaskReminderModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      remindAt: remindAt ?? this.remindAt,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
