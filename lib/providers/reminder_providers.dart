import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task_reminder_model.dart';
import '../data/repositories/reminder_repository.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

final remindersProvider =
    StateNotifierProvider<
      RemindersNotifier,
      AsyncValue<List<TaskReminderModel>>
    >((ref) {
      return RemindersNotifier(ref.watch(reminderRepositoryProvider));
    });

class RemindersNotifier
    extends StateNotifier<AsyncValue<List<TaskReminderModel>>> {
  final ReminderRepository _repository;

  RemindersNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadRemindersForTask(String taskId) async {
    try {
      final reminders = await _repository.getRemindersForTask(taskId);
      state = AsyncValue.data(reminders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadAllReminders() async {
    try {
      state = const AsyncValue.loading();
      final reminders = await _repository.getAllReminders();
      state = AsyncValue.data(reminders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addReminder(TaskReminderModel reminder) async {
    try {
      await _repository.createReminder(reminder);
      await loadRemindersForTask(reminder.taskId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateReminder(TaskReminderModel reminder) async {
    try {
      await _repository.updateReminder(reminder);
      await loadRemindersForTask(reminder.taskId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteReminder(String reminderId, String taskId) async {
    try {
      await _repository.deleteReminder(reminderId);
      await loadRemindersForTask(taskId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleReminder(
    String reminderId,
    bool enabled,
    String taskId,
  ) async {
    try {
      await _repository.toggleReminder(reminderId, enabled);
      await loadRemindersForTask(taskId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
