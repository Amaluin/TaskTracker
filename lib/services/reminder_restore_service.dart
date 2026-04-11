import '../data/repositories/reminder_repository.dart';
import 'notification_service.dart';

class ReminderRestoreService {
  static final ReminderRestoreService _instance =
      ReminderRestoreService._internal();
  factory ReminderRestoreService() => _instance;
  ReminderRestoreService._internal();

  final NotificationService _notificationService = NotificationService();

  Future<void> restoreRemindersAfterBoot() async {
    await _notificationService.initialize();

    final alreadyScheduled = await _notificationService
        .areNotificationsScheduled();
    if (alreadyScheduled) return;

    try {
      final repository = ReminderRepository();
      final reminders = await repository.getAllReminders();

      final now = DateTime.now();
      for (final reminder in reminders) {
        if (!reminder.enabled) continue;
        if (reminder.remindAt.isBefore(now)) continue;

        await _notificationService.scheduleNotification(
          id: reminder.id.hashCode,
          title: 'Task Reminder',
          body: 'You have a task reminder',
          scheduledDate: reminder.remindAt,
          payload: reminder.taskId,
        );
      }

      await _notificationService.markNotificationsScheduled();
    } catch (e) {
      // ignore: avoid_print
      print('Error restoring reminders after boot: $e');
    }
  }

  Future<void> rescheduleAllReminders() async {
    await _notificationService.initialize();
    await _notificationService.cancelAllNotifications();
    await _notificationService.clearNotificationsScheduledFlag();
    await restoreRemindersAfterBoot();
  }
}
