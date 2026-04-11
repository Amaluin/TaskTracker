import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../models/task_model.dart';

class TaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserId);
  }

  Future<List<TaskModel>> getTasks({String? status, String? priority}) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not identified');

    var query = _client.from('tasks').select().eq('user_id', userId);

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
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not identified');

    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .or('title.ilike.%$queryStr%,description.ilike.%$queryStr%')
        .order('created_at', ascending: false);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
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
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not identified');

    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .gte('due_at', start.toIso8601String())
        .lte('due_at', end.toIso8601String())
        .order('due_at', ascending: true);
    return (data as List).map((e) => TaskModel.fromJson(e)).toList();
  }
}
