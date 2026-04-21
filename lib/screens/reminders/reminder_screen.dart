import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants.dart';
import '../../data/models/task_reminder_model.dart';
import '../../providers/reminder_providers.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_restore_service.dart';
import '../../widgets/ios_time_picker.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String taskTitle;

  const ReminderScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  final String _reminderType = AppConstants.reminderTypeNotification;

  @override
  void initState() {
    super.initState();
    // Загружаем напоминания после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remindersProvider.notifier).loadRemindersForTask(widget.taskId);
    });
  }

  Future<void> _addReminder() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (selectedDate == null) return;

    final selectedTime = await showIOSTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (!mounted) return;
    if (selectedTime == null) return;

    final remindAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      // Получаем ID пользователя из Supabase auth
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка: пользователь не авторизован'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userId = user.id;
      final now = DateTime.now();
      final reminder = TaskReminderModel(
        id: const Uuid().v4(),
        taskId: widget.taskId,
        userId: userId,
        remindAt: remindAt,
        type: _reminderType,
        enabled: true,
        createdAt: now,
      );

      await ref.read(remindersProvider.notifier).addReminder(reminder);

      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: widget.taskTitle,
        body: widget.taskTitle,
        scheduledDate: remindAt,
        payload: widget.taskId,
      );
      if (mounted) {
        await NotificationService().showSystemAlarmDialog(
          context,
          scheduledDate: remindAt,
          taskTitle: widget.taskTitle,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Напоминание успешно создано'),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(TaskReminderModel reminder) async {
    await NotificationService().cancelNotification(reminder.id.hashCode);
    await ref
        .read(remindersProvider.notifier)
        .deleteReminder(reminder.id, widget.taskId);
  }

  Future<void> _toggleReminder(TaskReminderModel reminder) async {
    if (reminder.enabled) {
      await NotificationService().cancelNotification(reminder.id.hashCode);
    } else {
      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: widget.taskTitle,
        body: widget.taskTitle,
        scheduledDate: reminder.remindAt,
        payload: widget.taskId,
      );
      if (mounted) {
        await NotificationService().showSystemAlarmDialog(
          context,
          scheduledDate: reminder.remindAt,
          taskTitle: widget.taskTitle,
        );
      }
    }
    await ref
        .read(remindersProvider.notifier)
        .toggleReminder(reminder.id, !reminder.enabled, widget.taskId);
  }

  Future<void> _syncReminders() async {
    if (!mounted) return;

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text('Синхронизация напоминаний...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ReminderRestoreService().rescheduleAllReminders();

      if (mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Напоминания синхронизированы'),
            backgroundColor: Color(0xFF6366F1),
          ),
        );

        // Перезагружаем список
        ref
            .read(remindersProvider.notifier)
            .loadRemindersForTask(widget.taskId);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    final notificationService = NotificationService();
    String statusText = '';

    if (kIsWeb) {
      statusText = 'Веб-уведомления';
    } else if (Platform.isAndroid) {
      final hasExactAlarm = await notificationService.hasExactAlarmPermission();
      final areEnabled = await notificationService.areNotificationsEnabled();

      statusText = 'Android:\n';
      statusText += '• Уведомления: ${areEnabled ? "Включены" : "Выключены"}\n';
      statusText += '• Точные будильники: ';
      if (hasExactAlarm == true) {
        statusText += 'Разрешены';
      } else if (hasExactAlarm == false) {
        statusText += 'Запрещены (напоминания могут не работать!)';
      } else {
        statusText += 'Неизвестно';
      }
    } else if (Platform.isIOS) {
      statusText = 'iOS: локальные уведомления';
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статус уведомлений'),
        content: SingleChildScrollView(child: Text(statusText)),
        actions: [
          if (Platform.isAndroid)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await notificationService.requestExactAlarmPermission();
              },
              child: const Text('Открыть настройки'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!kIsWeb && Platform.isAndroid) ...[
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Синхронизировать напоминания',
              onPressed: _syncReminders,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Проверить разрешения',
              onPressed: _checkPermissions,
            ),
          ],
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final remindersAsync = ref.watch(remindersProvider);

          return remindersAsync.when(
            data: (reminders) {
              final taskReminders = reminders
                  .where((r) => r.taskId == widget.taskId)
                  .toList();

              if (taskReminders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Напоминания не установлены',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Нажмите "+" чтобы добавить напоминание',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: taskReminders.length,
                itemBuilder: (context, index) {
                  final reminder = taskReminders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: reminder.enabled
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          reminder.enabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: reminder.enabled
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                        ),
                      ),
                      title: Builder(
                        builder: (context) {
                          final remindAt = reminder.remindAt.isUtc
                              ? reminder.remindAt.toLocal()
                              : reminder.remindAt;
                          return Text(
                            '${remindAt.day}.${remindAt.month}.${remindAt.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                      subtitle: Builder(
                        builder: (context) {
                          final remindAt = reminder.remindAt.isUtc
                              ? reminder.remindAt.toLocal()
                              : reminder.remindAt;
                          return Text(
                            '${remindAt.hour}:${remindAt.minute.toString().padLeft(2, '0')} - ${reminder.type}',
                            style: TextStyle(color: Colors.grey[600]),
                          );
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: reminder.enabled,
                            onChanged: (_) => _toggleReminder(reminder),
                            activeColor: const Color(0xFF6366F1),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteReminder(reminder),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: $error'),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}
