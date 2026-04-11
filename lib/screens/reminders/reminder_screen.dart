import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../data/models/task_reminder_model.dart';
import '../../providers/reminder_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/ios_time_picker.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  final String taskId;

  const ReminderScreen({super.key, required this.taskId});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  final String _reminderType = AppConstants.reminderTypeNotification;

  @override
  void initState() {
    super.initState();
    ref.read(remindersProvider.notifier).loadRemindersForTask(widget.taskId);
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

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyUserId);
    if (userId == null) return;

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
      title: 'Напоминание о задаче',
      body:
          'У вас запланировано напоминание на ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
      scheduledDate: remindAt,
      payload: widget.taskId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Напоминание успешно создано'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
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
        title: 'Напоминание о задаче',
        body: 'У вас запланировано напоминание',
        scheduledDate: reminder.remindAt,
        payload: widget.taskId,
      );
    }
    await ref
        .read(remindersProvider.notifier)
        .toggleReminder(reminder.id, !reminder.enabled, widget.taskId);
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
                      title: Text(
                        '${reminder.remindAt.day}.${reminder.remindAt.month}.${reminder.remindAt.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${reminder.remindAt.hour}:${reminder.remindAt.minute.toString().padLeft(2, '0')} - ${reminder.type}',
                        style: TextStyle(color: Colors.grey[600]),
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
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
