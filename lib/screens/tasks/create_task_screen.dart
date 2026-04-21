import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_reminder_model.dart';
import '../../providers/task_providers.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/ios_time_picker.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = AppConstants.statusPending;
  String _priority = AppConstants.priorityMedium;
  DateTime? _dueDate;
  String? _selectedUserId; // ID выбранного пользователя
  bool _isLoading = false;

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.pending_outlined;
      case AppConstants.statusAccepted:
        return Icons.play_circle_outline;
      case AppConstants.statusPostponed:
        return Icons.pause_circle_outline;
      case AppConstants.statusArchived:
        return Icons.archive_outlined;
      default:
        return Icons.task_alt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showIOSTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
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

      // Используем выбранного пользователя или текущего
      final assignedUserId = _selectedUserId ?? currentUserId;

      final now = DateTime.now();
      final task = TaskModel(
        id: const Uuid().v4(),
        userId: assignedUserId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _status,
        priority: _priority,
        dueAt: _dueDate,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(tasksProvider.notifier).addTask(task);

      // Если установлен срок выполнения, создаём напоминание
      if (_dueDate != null && mounted) {
        try {
          print('📅 Создаём напоминание на: $_dueDate');
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            final reminder = TaskReminderModel(
              id: const Uuid().v4(),
              taskId: task.id,
              userId: user.id,
              remindAt: _dueDate!,
              type: AppConstants.reminderTypeNotification,
              enabled: true,
              createdAt: now,
            );

            print('💾 Сохраняем напоминание в БД: ${reminder.id}');
            await ref.read(remindersProvider.notifier).addReminder(reminder);

            print('🔔 Планируем уведомление');
            await NotificationService().scheduleNotification(
              id: reminder.id.hashCode,
              title: task.title,
              body: task.title,
              scheduledDate: _dueDate!,
              payload: task.id,
            );

            if (mounted) {
              await NotificationService().showSystemAlarmDialog(
                context,
                scheduledDate: _dueDate!,
                taskTitle: task.title,
              );
            }

            print('✅ Напоминание создано успешно');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Напоминание установлено на ${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year} ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (reminderError) {
          print('❌ Ошибка создания напоминания: $reminderError');
          if (mounted) {
            // Показываем предупреждение, но не останавливаем процесс
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Задача создана, но не удалось установить напоминание: $reminderError',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая задача'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Введите название задачи',
                        prefixIcon: Icon(Icons.title, color: Color(0xFF6366F1)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Название обязательно';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        hintText: 'Добавьте описание задачи',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(
                            Icons.description,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Статус',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.allStatuses
                          .where(
                            (status) => status != AppConstants.statusArchived,
                          )
                          .map((status) {
                            final statusColor = getStatusColor(status);
                            final isSelected = _status == status;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    size: 16,
                                    color: isSelected
                                        ? statusColor
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(getStatusDisplayName(status)),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _status = status);
                              },
                              selectedColor: statusColor.withValues(alpha: 0.2),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? statusColor
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? statusColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              elevation: isSelected ? 2 : 0,
                              shadowColor: statusColor.withValues(alpha: 0.3),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Приоритет',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.allPriorities.map((priority) {
                        Color priorityColor;
                        IconData priorityIcon;
                        switch (priority) {
                          case AppConstants.priorityHigh:
                            priorityColor = Colors.red;
                            priorityIcon = Icons.arrow_upward;
                            break;
                          case AppConstants.priorityMedium:
                            priorityColor = Colors.orange;
                            priorityIcon = Icons.remove;
                            break;
                          default:
                            priorityColor = Colors.green;
                            priorityIcon = Icons.arrow_downward;
                        }
                        final isSelected = _priority == priority;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                priorityIcon,
                                size: 16,
                                color: isSelected
                                    ? priorityColor
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(getPriorityDisplayName(priority)),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _priority = priority);
                          },
                          selectedColor: priorityColor.withValues(alpha: 0.2),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? priorityColor
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? priorityColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          elevation: isSelected ? 2 : 0,
                          shadowColor: priorityColor.withValues(alpha: 0.3),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Назначить на',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final usersAsync = ref.watch(allUsersProvider);
                        final currentUserAsync = ref.watch(currentUserProvider);

                        return usersAsync.when(
                          data: (users) {
                            final currentUser = currentUserAsync.value;
                            final currentUserId = currentUser?.id;

                            print(
                              '🔍 Загружено пользователей: ${users.length}',
                            );
                            print('🔍 Текущий пользователь ID: $currentUserId');
                            print(
                              '🔍 Выбранный пользователь ID: $_selectedUserId',
                            );

                            // Если список пользователей пуст, показываем предупреждение
                            if (users.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Не удалось загрузить пользователей. Задача будет назначена на вас.',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Если пользователь не выбран, выбираем текущего
                            if (_selectedUserId == null &&
                                currentUserId != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _selectedUserId = currentUserId;
                                  });
                                  print(
                                    '✅ Автоматически выбран текущий пользователь: $currentUserId',
                                  );
                                }
                              });
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUserId,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF6366F1),
                                  ),
                                  hint: const Text('Выберите пользователя'),
                                  items: users.map((user) {
                                    final isCurrentUser =
                                        user.id == currentUserId;
                                    return DropdownMenuItem<String>(
                                      value: user.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 20,
                                            color: isCurrentUser
                                                ? const Color(0xFF6366F1)
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              isCurrentUser
                                                  ? '${user.displayText} (Я)'
                                                  : user.displayText,
                                              style: TextStyle(
                                                fontWeight: isCurrentUser
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isCurrentUser
                                                    ? const Color(0xFF6366F1)
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUserId = value;
                                    });
                                    print('✅ Выбран пользователь: $value');
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Загрузка пользователей...'),
                              ],
                            ),
                          ),
                          error: (error, stack) {
                            print('❌ Ошибка в UI: $error');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Не удалось загрузить пользователей. Задача будет назначена на вас.',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Срок выполнения',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDueDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dueDate != null
                                    ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year} в ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                                    : 'Выберите дату и время',
                                style: TextStyle(
                                  color: _dueDate != null
                                      ? const Color(0xFF1F2937)
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                                color: Colors.grey[600],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveTask,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isLoading ? 'Сохранение...' : 'Сохранить задачу',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
