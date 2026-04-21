import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_reminder_model.dart';

class ReminderRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> _getUserId() async {
    // Сначала пробуем получить ID из Supabase auth
    final user = _client.auth.currentUser;
    if (user != null) {
      return user.id;
    }

    // Если пользователь не авторизован через Supabase, возвращаем null
    return null;
  }

  Future<List<TaskReminderModel>> getRemindersForTask(String taskId) async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Пользователь не авторизован. Пожалуйста, войдите в систему.',
      );
    }

    final data = await _client
        .from('task_reminders')
        .select()
        .eq('task_id', taskId)
        .eq('user_id', userId)
        .order('remind_at', ascending: true);
    return (data as List).map((e) => TaskReminderModel.fromJson(e)).toList();
  }

  Future<void> deleteExpiredRemindersForTask(String taskId) async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Пользователь не авторизован. Пожалуйста, войдите в систему.',
      );
    }

    await _client
        .from('task_reminders')
        .delete()
        .eq('task_id', taskId)
        .eq('user_id', userId)
        .lt('remind_at', DateTime.now().toUtc().toIso8601String());
  }

  Future<List<TaskReminderModel>> getAllReminders() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Пользователь не авторизован. Пожалуйста, войдите в систему.',
      );
    }

    final data = await _client
        .from('task_reminders')
        .select()
        .eq('user_id', userId)
        .eq('enabled', true)
        .order('remind_at', ascending: true);
    return (data as List).map((e) => TaskReminderModel.fromJson(e)).toList();
  }

  Future<void> deleteAllExpiredReminders() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Пользователь не авторизован. Пожалуйста, войдите в систему.',
      );
    }

    await _client
        .from('task_reminders')
        .delete()
        .eq('user_id', userId)
        .lt('remind_at', DateTime.now().toUtc().toIso8601String());
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
