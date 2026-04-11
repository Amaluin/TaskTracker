import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../models/task_reminder_model.dart';

class ReminderRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserId);
  }

  Future<List<TaskReminderModel>> getRemindersForTask(String taskId) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not identified');

    final data = await _client
        .from('task_reminders')
        .select()
        .eq('task_id', taskId)
        .eq('user_id', userId)
        .order('remind_at', ascending: true);
    return (data as List).map((e) => TaskReminderModel.fromJson(e)).toList();
  }

  Future<List<TaskReminderModel>> getAllReminders() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not identified');

    final data = await _client
        .from('task_reminders')
        .select()
        .eq('user_id', userId)
        .eq('enabled', true)
        .order('remind_at', ascending: true);
    return (data as List).map((e) => TaskReminderModel.fromJson(e)).toList();
  }

  Future<TaskReminderModel> createReminder(TaskReminderModel reminder) async {
    final response = await _client
        .from('task_reminders')
        .insert(reminder.toJson())
        .select()
        .single();
    return TaskReminderModel.fromJson(response);
  }

  Future<TaskReminderModel> updateReminder(TaskReminderModel reminder) async {
    final response = await _client
        .from('task_reminders')
        .update(reminder.toJson())
        .eq('id', reminder.id)
        .select()
        .single();
    return TaskReminderModel.fromJson(response);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _client.from('task_reminders').delete().eq('id', reminderId);
  }

  Future<void> toggleReminder(String reminderId, bool enabled) async {
    await _client
        .from('task_reminders')
        .update({'enabled': enabled})
        .eq('id', reminderId);
  }
}
