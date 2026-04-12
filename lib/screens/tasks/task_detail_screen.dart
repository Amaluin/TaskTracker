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
import '../../widgets/postpone_dialog.dart';
import '../reminders/reminder_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _status;
  late String _priority;
  DateTime? _dueDate;
  bool _isEditing = false;

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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _status = widget.task.status;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueAt;
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
      initialDate: _dueDate ?? DateTime.now(),
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
    if (date != null && mounted) {
      final time = await showIOSTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
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
    if (_titleController.text.trim().isEmpty) return;

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      dueAt: _dueDate,
    );

    await ref.read(tasksProvider.notifier).updateTask(updatedTask);
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _acceptTask() async {
    // Принять задачу и создать напоминание
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

    // Обновляем статус на "В работе"
    final updatedTask = widget.task.copyWith(
      status: AppConstants.statusAccepted,
    );
    await ref.read(tasksProvider.notifier).updateTask(updatedTask);

    // Создаем напоминание на срок выполнения, если он установлен
    if (widget.task.dueAt != null) {
      final reminder = TaskReminderModel(
        id: const Uuid().v4(),
        taskId: widget.task.id,
        userId: user.id,
        remindAt: widget.task.dueAt!.subtract(const Duration(hours: 1)),
        type: AppConstants.reminderTypeNotification,
        enabled: true,
        createdAt: DateTime.now(),
      );

      await ref.read(remindersProvider.notifier).addReminder(reminder);

      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Напоминание о задаче',
        body: 'Задача "${widget.task.title}" должна быть выполнена через час',
        scheduledDate: reminder.remindAt,
        payload: widget.task.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Задача принята! Напоминание создано.'),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );
    }
  }

  Future<void> _postponeTask() async {
    final postponeUntil = await showPostponeDialog(context);

    if (postponeUntil != null) {
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

      // Обновляем задачу
      final updatedTask = widget.task.copyWith(
        status: AppConstants.statusPostponed,
        postponedUntil: postponeUntil,
      );
      await ref.read(tasksProvider.notifier).updateTask(updatedTask);

      // Создаем напоминание на время отложения
      final reminder = TaskReminderModel(
        id: const Uuid().v4(),
        taskId: widget.task.id,
        userId: user.id,
        remindAt: postponeUntil,
        type: AppConstants.reminderTypeNotification,
        enabled: true,
        createdAt: DateTime.now(),
      );

      await ref.read(remindersProvider.notifier).addReminder(reminder);

      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Отложенная задача',
        body: 'Задача "${widget.task.title}" отложена до этого времени',
        scheduledDate: postponeUntil,
        payload: widget.task.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Задача отложена до ${postponeUntil.day}.${postponeUntil.month}.${postponeUntil.year} ${postponeUntil.hour}:${postponeUntil.minute.toString().padLeft(2, '0')}',
            ),
            backgroundColor: const Color(0xFF8B5CF6),
          ),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить задачу'),
        content: const Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksProvider.notifier).deleteTask(widget.task.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderScreen(taskId: widget.task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали задачи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _openReminders,
                tooltip: 'Напоминания',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Редактировать',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteTask,
                tooltip: 'Удалить',
                color: Colors.red,
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _titleController.text = widget.task.title;
                  _descriptionController.text = widget.task.description ?? '';
                  _status = widget.task.status;
                  _priority = widget.task.priority;
                  _dueDate = widget.task.dueAt;
                });
              },
              child: const Text('Отмена'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildStatusSelector(),
                  const SizedBox(height: 24),
                  _buildPrioritySelector(),
                  const SizedBox(height: 24),
                  _buildDueDateSelector(),
                  const SizedBox(height: 24),
                  _buildAssignedUserSection(),
                  const SizedBox(height: 24),
                  if (!_isEditing) _buildActionButtons(),
                  if (!_isEditing) const SizedBox(height: 24),
                  _buildRemindersSection(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                ],
              ),
            ),
          ),
          if (_isEditing)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveTask,
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Сохранить изменения',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Название',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _isEditing
            ? TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Введите название задачи',
                  prefixIcon: Icon(Icons.title, color: Color(0xFF6366F1)),
                ),
              )
            : Text(
                widget.task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Описание',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _isEditing
            ? TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Добавьте описание задачи',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description, color: Color(0xFF6366F1)),
                  ),
                  alignLabelWithHint: true,
                ),
              )
            : Text(
                widget.task.description ?? 'Описание отсутствует',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: widget.task.description == null
                      ? Colors.grey[500]
                      : const Color(0xFF1F2937),
                ),
              ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: AppConstants.allStatuses.map((status) {
            final statusColor = getStatusColor(status);
            final isSelected = _status == status;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: isSelected ? statusColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(getStatusDisplayName(status)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected && _status != status) {
                  setState(() => _status = status);
                  // Автоматически сохраняем изменение статуса
                  final updatedTask = widget.task.copyWith(status: status);
                  await ref.read(tasksProvider.notifier).updateTask(updatedTask);
                }
              },
              selectedColor: statusColor.withValues(alpha: 0.2),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? statusColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? statusColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              elevation: isSelected ? 2 : 0,
              shadowColor: statusColor.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final isSelected = _priority == priority;
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
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    priorityIcon,
                    size: 16,
                    color: isSelected ? priorityColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(getPriorityDisplayName(priority)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected && _priority != priority) {
                  setState(() => _priority = priority);
                  // Автоматически сохраняем изменение приоритета
                  final updatedTask = widget.task.copyWith(priority: priority);
                  await ref.read(tasksProvider.notifier).updateTask(updatedTask);
                }
              },
              selectedColor: priorityColor.withValues(alpha: 0.2),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? priorityColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? priorityColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              elevation: isSelected ? 2 : 0,
              shadowColor: priorityColor.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Срок выполнения',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _isEditing
            ? InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
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
                          onPressed: () => setState(() => _dueDate = null),
                          color: Colors.grey[600],
                        ),
                    ],
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year} в ${_dueDate!.hour}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                          : 'Срок не установлен',
                      style: TextStyle(
                        color: _dueDate != null
                            ? const Color(0xFF1F2937)
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildAssignedUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ответственный',
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

                // Преобразуем пустую строку в null для дропдауна
                final assignedUserId = widget.task.assignedToUserId?.isEmpty ?? true
                    ? null
                    : widget.task.assignedToUserId;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: assignedUserId,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                      hint: const Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.grey, size: 20),
                          SizedBox(width: 12),
                          Text('Выберите ответственного'),
                        ],
                      ),
                      items: users.map((user) {
                        final isCurrentUser = user.id == currentUserId;
                        return DropdownMenuItem<String?>(
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
                      onChanged: _isEditing ? null : (String? newUserId) async {
                        if (newUserId == null) return;
                        
                        // Находим имя пользователя
                        final user = users.firstWhere((u) => u.id == newUserId);
                        final userName = user.displayText;

                        // Обновляем задачу
                        final updatedTask = widget.task.copyWith(
                          assignedToUserId: newUserId,
                          assignedToUserName: userName,
                        );
                        await ref.read(tasksProvider.notifier).updateTask(updatedTask);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Задача назначена пользователю $userName'),
                              backgroundColor: const Color(0xFF6366F1),
                            ),
                          );
                        }
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
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      widget.task.assignedToUserName ?? 'Не назначен',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.task.postponedUntil != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Отложена до ${widget.task.postponedUntil!.day}.${widget.task.postponedUntil!.month}.${widget.task.postponedUntil!.year} ${widget.task.postponedUntil!.hour}:${widget.task.postponedUntil!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Действия',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.task.assignedToUserName != null &&
            widget.task.status != AppConstants.statusAccepted)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _acceptTask,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Принять задачу',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _postponeTask,
          icon: const Icon(Icons.schedule),
          label: const Text(
            'Отложить задачу',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
            side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Напоминания',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton.icon(
              onPressed: _openReminders,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Управление'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final remindersAsync = ref.watch(remindersProvider);
            return remindersAsync.when(
              data: (reminders) {
                final taskReminders = reminders
                    .where((r) => r.taskId == widget.task.id)
                    .toList()
                  ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
                
                if (taskReminders.isEmpty) {
                  return InkWell(
                    onTap: _openReminders,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Напоминания не установлены',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Нажмите, чтобы добавить',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: taskReminders.map((reminder) {
                    final now = DateTime.now();
                    // Если remindAt в UTC, конвертируем в локальное время
                    final remindAtLocal = reminder.remindAt.isUtc
                        ? reminder.remindAt.toLocal()
                        : reminder.remindAt;
                    final isUpcoming = remindAtLocal.isAfter(now);
                    final isPast = !isUpcoming;
                    final timeUntil = remindAtLocal.difference(now);
                    
                    String timeText;
                    if (isPast) {
                      timeText = 'Прошло';
                    } else if (timeUntil.inMinutes < 1) {
                      timeText = 'Менее минуты';
                    } else if (timeUntil.inMinutes < 60) {
                      timeText = 'Через ${timeUntil.inMinutes} мин';
                    } else if (timeUntil.inHours < 24) {
                      final hours = timeUntil.inHours;
                      final minutes = timeUntil.inMinutes % 60;
                      if (minutes > 0) {
                        timeText = 'Через $hours ч $minutes мин';
                      } else {
                        timeText = 'Через $hours ч';
                      }
                    } else {
                      final days = timeUntil.inDays;
                      final hours = timeUntil.inHours % 24;
                      if (hours > 0) {
                        timeText = 'Через $days дн $hours ч';
                      } else {
                        timeText = 'Через $days дн';
                      }
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: reminder.enabled && isUpcoming
                              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                          width: reminder.enabled && isUpcoming ? 2 : 1,
                        ),
                        boxShadow: reminder.enabled && isUpcoming
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openReminders,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: reminder.enabled && isUpcoming
                                        ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    reminder.enabled
                                        ? (isUpcoming
                                            ? Icons.notifications_active
                                            : Icons.notifications)
                                        : Icons.notifications_off,
                                    color: reminder.enabled && isUpcoming
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${reminder.remindAt.day}.${reminder.remindAt.month}.${reminder.remindAt.year} в ${reminder.remindAt.hour}:${reminder.remindAt.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isPast
                                                    ? Colors.grey[600]
                                                    : const Color(0xFF1F2937),
                                                decoration: isPast
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (isUpcoming && reminder.enabled) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                timeText,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF6366F1),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            reminder.type == 'alarm'
                                                ? Icons.alarm
                                                : Icons.notifications_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            reminder.type == 'alarm'
                                                ? 'Будильник'
                                                : 'Уведомление',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (!reminder.enabled) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Выключено',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
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
                    Text('Загрузка напоминаний...'),
                  ],
                ),
              ),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ошибка загрузки: $e',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Создано', _formatDate(widget.task.createdAt)),
          _buildInfoRow('Обновлено', _formatDate(widget.task.updatedAt)),
          if (widget.task.archivedAt != null)
            _buildInfoRow('В архиве', _formatDate(widget.task.archivedAt!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
