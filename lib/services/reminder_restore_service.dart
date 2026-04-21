import 'package:flutter/foundation.dart' show debugPrint;
import '../data/repositories/task_repository.dart';
import '../data/repositories/reminder_repository.dart';
import 'notification_service.dart';

class ReminderRestoreService {
  static final ReminderRestoreService _instance =
      ReminderRestoreService._internal();
  factory ReminderRestoreService() => _instance;
  ReminderRestoreService._internal();

  final NotificationService _notificationService = NotificationService();

  void _log(String stage, String message) {
    debugPrint('[ReminderRestoreService][$stage] $message');
  }

  Future<void> restoreRemindersAfterBoot() async {
    _log('restore', 'start');
    await _notificationService.initialize();
    _log('restore', 'notification service initialized');

    // Проверяем разрешение на точные будильники
    final hasPermission = await _notificationService.hasExactAlarmPermission();
    _log('restore-permission', 'exact alarm permission=$hasPermission');
    if (hasPermission == false) {
      _log('restore-permission', 'request exact alarm permission');
      await _notificationService.requestExactAlarmPermission();
    }

    try {
      final repository = ReminderRepository();
      final taskRepository = TaskRepository();
      final reminders = await repository.getAllReminders();
      final tasks = await taskRepository.getTasks();
      final taskTitlesById = {for (final task in tasks) task.id: task.title};
      _log('restore-fetch', 'loaded reminders count=${reminders.length}');

      // Отменяем все существующие уведомления перед пересозданием
      await _notificationService.cancelAllNotifications();
      _log('restore-cancel', 'all previous notifications cancelled');

      final now = DateTime.now();
      int restoredCount = 0;
      int skippedCount = 0;

      for (final reminder in reminders) {
        if (!reminder.enabled) {
          _log('restore-item', 'skip disabled id=${reminder.id}');
          skippedCount++;
          continue;
        }
        if (reminder.remindAt.isBefore(now)) {
          _log('restore-item', 'skip past remindAt=${reminder.remindAt}');
          skippedCount++;
          continue;
        }

        _log(
          'restore-item',
          'schedule id=${reminder.id.hashCode} at=${reminder.remindAt}',
        );
        await _notificationService.scheduleNotification(
          id: reminder.id.hashCode,
          title: taskTitlesById[reminder.taskId] ?? 'Напоминание',
          body: taskTitlesById[reminder.taskId] ?? 'Напоминание',
          scheduledDate: reminder.remindAt,
          payload: reminder.taskId,
        );
        restoredCount++;
      }

      await _notificationService.markNotificationsScheduled();
      _log(
        'restore',
        'completed restored=$restoredCount skipped=$skippedCount',
      );
    } catch (e, stack) {
      _log('restore-error', '$e');
      _log('restore-error', '$stack');
    }
  }

  Future<void> rescheduleAllReminders() async {
    _log('reschedule', 'start');
    await _notificationService.initialize();
    await _notificationService.cancelAllNotifications();
    await _notificationService.clearNotificationsScheduledFlag();
    await restoreRemindersAfterBoot();
    _log('reschedule', 'completed');
  }
}
