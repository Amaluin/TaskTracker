import '../data/repositories/reminder_repository.dart';
import 'notification_service.dart';

class ReminderRestoreService {
  static final ReminderRestoreService _instance =
      ReminderRestoreService._internal();
  factory ReminderRestoreService() => _instance;
  ReminderRestoreService._internal();

  final NotificationService _notificationService = NotificationService();

  Future<void> restoreRemindersAfterBoot() async {
    print('🔄 Восстановление напоминаний...');
    await _notificationService.initialize();

    // Проверяем разрешение на точные будильники
    final hasPermission = await _notificationService.hasExactAlarmPermission();
    if (hasPermission == false) {
      print('⚠️ Нет разрешения на точные будильники, запрашиваем...');
      await _notificationService.requestExactAlarmPermission();
    }

    try {
      final repository = ReminderRepository();
      final reminders = await repository.getAllReminders();
      print('📋 Найдено напоминаний в БД: ${reminders.length}');

      // Отменяем все существующие уведомления перед пересозданием
      await _notificationService.cancelAllNotifications();

      final now = DateTime.now();
      int restoredCount = 0;
      int skippedCount = 0;

      for (final reminder in reminders) {
        if (!reminder.enabled) {
          print('⏭️ Пропущено (отключено): ${reminder.id}');
          skippedCount++;
          continue;
        }
        if (reminder.remindAt.isBefore(now)) {
          print('⏭️ Пропущено (в прошлом): ${reminder.remindAt}');
          skippedCount++;
          continue;
        }

        print('📅 Восстанавливаю напоминание: ${reminder.remindAt}');
        await _notificationService.scheduleNotification(
          id: reminder.id.hashCode,
          title: 'Напоминание о задаче',
          body: 'У вас запланировано напоминание',
          scheduledDate: reminder.remindAt,
          payload: reminder.taskId,
        );
        restoredCount++;
      }

      await _notificationService.markNotificationsScheduled();
      print('✅ Восстановлено: $restoredCount, пропущено: $skippedCount');
    } catch (e, stack) {
      print('❌ Ошибка при восстановлении напоминаний: $e');
      print('Stack: $stack');
    }
  }

  Future<void> rescheduleAllReminders() async {
    print('🔄 Пересоздание всех напоминаний...');
    await _notificationService.initialize();
    await _notificationService.cancelAllNotifications();
    await _notificationService.clearNotificationsScheduledFlag();
    await restoreRemindersAfterBoot();
  }
}
