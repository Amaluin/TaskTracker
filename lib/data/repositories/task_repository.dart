import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? _getUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<List<TaskModel>> getTasks({String? status, String? priority}) async {
    final userId = _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    var query = _client
        .from('tasks')
        .select()
        .or('user_id.eq.$userId,assigned_to_user_id.eq.$userId');

    if (status != null) {
      query = query.eq('status', status);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<List<TaskModel>> searchTasks(String queryStr) async {
    final tasks = await getTasks();
    final normalized = queryStr.trim().toLowerCase();
    return tasks.where((task) {
      final title = task.title.toLowerCase();
      final description = task.description?.toLowerCase() ?? '';
      return title.contains(normalized) || description.contains(normalized);
    }).toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final response = await _client
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _client
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();
    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<TaskModel> changeStatus(String taskId, String newStatus) async {
    final response = await _client
        .from('tasks')
        .update({
          'status': newStatus,
          if (newStatus == 'archived')
            'archived_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId)
        .select()
        .single();
    return TaskModel.fromJson(response);
  }

  Future<List<TaskModel>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = _getUserId();
    if (userId == null) throw Exception('User not authenticated');

    final data = await _client
        .from('tasks')
        .select()
        .or('user_id.eq.$userId,assigned_to_user_id.eq.$userId')
        .gte('due_at', start.toIso8601String())
        .lte('due_at', end.toIso8601String())
        .order('due_at', ascending: true);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }
}
