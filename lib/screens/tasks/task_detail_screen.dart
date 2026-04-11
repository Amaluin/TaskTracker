import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_reminder_model.dart';
import '../../providers/task_providers.dart';
import '../../providers/reminder_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/ios_time_picker.dart';
import '../../widgets/assign_user_dialog.dart';
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

  Future<void> _assignUser() async {
    final result = await showAssignUserDialog(
      context,
      currentAssignedName: widget.task.assignedToUserName,
    );

    if (result != null) {
      if (result == 'remove') {
        // Снять ответственного
        final updatedTask = widget.task.copyWith(
          assignedToUserId: '',
          assignedToUserName: '',
        );
        await ref.read(tasksProvider.notifier).updateTask(updatedTask);
      } else {
        // Назначить ответственного
        final assignedUserId = const Uuid().v4(); // В реальном приложении это ID из базы
        
        final updatedTask = widget.task.copyWith(
          assignedToUserId: assignedUserId,
          assignedToUserName: result,
        );
        await ref.read(tasksProvider.notifier).updateTask(updatedTask);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Задача назначена пользователю $result'),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        }
      }
    }
  }

  Future<void> _acceptTask() async {
    // Принять задачу и создать напоминание
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(AppConstants.keyUserId);
    
    if (currentUserId == null) return;

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
        userId: currentUserId,
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
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(AppConstants.keyUserId);
      
      if (currentUserId == null) return;

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
        userId: currentUserId,
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
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: _openReminders,
              tooltip: 'Напоминания',
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTask,
              tooltip: 'Удалить',
              color: Colors.red,
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
            final isSelected = _status == status;
            return ChoiceChip(
              label: Text(getStatusDisplayName(status)),
              selected: isSelected,
              onSelected: _isEditing
                  ? (selected) => setState(() => _status = status)
                  : null,
              selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
              ),
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
            switch (priority) {
              case AppConstants.priorityHigh:
                priorityColor = Colors.red;
                break;
              case AppConstants.priorityMedium:
                priorityColor = Colors.orange;
                break;
              default:
                priorityColor = Colors.green;
            }
            return ChoiceChip(
              label: Text(getPriorityDisplayName(priority)),
              selected: isSelected,
              onSelected: _isEditing
                  ? (selected) => setState(() => _priority = priority)
                  : null,
              selectedColor: priorityColor.withOpacity(0.2),
              side: BorderSide(
                color: isSelected ? priorityColor : Colors.grey.shade300,
              ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.task.assignedToUserName ?? 'Не назначен',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.task.assignedToUserName != null
                        ? const Color(0xFF1F2937)
                        : Colors.grey[600],
                  ),
                ),
              ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _assignUser,
                  color: const Color(0xFF6366F1),
                  tooltip: 'Изменить ответственного',
                ),
            ],
          ),
        ),
        if (widget.task.postponedUntil != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
              label: const Text('Добавить'),
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
                    .toList();
                if (taskReminders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_none, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          'Напоминания не установлены',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: taskReminders.map((reminder) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            reminder.enabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: reminder.enabled
                                ? const Color(0xFF6366F1)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${reminder.remindAt.day}.${reminder.remindAt.month}.${reminder.remindAt.year} в ${reminder.remindAt.hour}:${reminder.remindAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  reminder.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
              error: (e, s) => Text('Ошибка: $e'),
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
