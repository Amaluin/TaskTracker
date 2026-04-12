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
    final remindAtStr = json['remind_at'] as String;
    var remindAt = DateTime.parse(remindAtStr);
    // Если время пришло как UTC, конвертируем в локальное
    if (remindAt.isUtc || remindAtStr.endsWith('Z')) {
      remindAt = remindAt.toLocal();
    }

    final createdAtStr = json['created_at'] as String;
    var createdAt = DateTime.parse(createdAtStr);
    if (createdAt.isUtc || createdAtStr.endsWith('Z')) {
      createdAt = createdAt.toLocal();
    }

    return TaskReminderModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      remindAt: remindAt,
      type: json['type'] as String,
      enabled: json['enabled'] as bool,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      // Сохраняем в UTC, чтобы Supabase корректно хранил
      'remind_at': remindAt.toUtc().toIso8601String(),
      'type': type,
      'enabled': enabled,
      'created_at': createdAt.toUtc().toIso8601String(),
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
