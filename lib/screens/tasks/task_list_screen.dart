import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/kanban_column.dart';
import '../../data/models/task_model.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = AppConstants.allStatuses[_tabController.index];
        ref.read(filterStatusProvider.notifier).state = status;
        ref.read(tasksProvider.notifier).loadTasks(status: status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    ref.read(filterStatusProvider.notifier).state = null;
    ref.read(filterPriorityProvider.notifier).state = null;
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(tasksProvider.notifier).loadTasks();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Поиск задач...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                ),
                style: const TextStyle(color: Color(0xFF1F2937)),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  ref.read(tasksProvider.notifier).searchTasks(value);
                },
              )
            : const Text('Мои задачи'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _clearFilters();
                }
              });
            },
          ),
          if (!isWideScreen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'clear') {
                  ref.read(filterPriorityProvider.notifier).state = null;
                  ref.read(tasksProvider.notifier).loadTasks(
                    status: ref.read(filterStatusProvider),
                  );
                } else {
                  ref.read(filterPriorityProvider.notifier).state = value;
                  ref.read(tasksProvider.notifier).loadTasks(
                    status: ref.read(filterStatusProvider),
                    priority: value,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'high',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                      SizedBox(width: 12),
                      Text('Высокий приоритет'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'medium',
                  child: Row(
                    children: [
                      Icon(Icons.remove, color: Colors.orange, size: 18),
                      SizedBox(width: 12),
                      Text('Средний приоритет'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'low',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                      SizedBox(width: 12),
                      Text('Низкий приоритет'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 18),
                      SizedBox(width: 12),
                      Text('Сбросить фильтр'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: !isWideScreen
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFF6366F1),
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: AppConstants.allStatuses
                    .map((status) => Tab(text: getStatusDisplayName(status)))
                    .toList(),
              )
            : null,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final tasksAsync = ref.watch(filteredTasksProvider);

          return tasksAsync.when(
            data: (tasks) {
              if (isWideScreen) {
                return _buildKanbanView(tasks);
              } else {
                return _buildListView(tasks);
              }
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(tasksProvider.notifier).loadTasks();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKanbanView(List<TaskModel> allTasks) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.05),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Вычисляем ширину колонки с учетом отступов
          final totalPadding = 24.0 * 2; // padding слева и справа
          final columnSpacing = 16.0; // отступ между колонками
          final totalSpacing = columnSpacing * (AppConstants.allStatuses.length - 1);
          final availableWidth = constraints.maxWidth - totalPadding - totalSpacing;
          final columnWidth = availableWidth / AppConstants.allStatuses.length;
          
          // Минимальная ширина колонки - 280px
          final clampedWidth = columnWidth.clamp(280.0, double.infinity);
          
          // Если колонки не помещаются, делаем горизонтальный скролл
          final needsScroll = clampedWidth * AppConstants.allStatuses.length + totalSpacing > availableWidth;
          
          final columnsRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AppConstants.allStatuses.map((status) {
              final statusTasks = allTasks.where((t) => t.status == status).toList();
              return Container(
                width: clampedWidth,
                margin: EdgeInsets.only(
                  right: status != AppConstants.allStatuses.last ? columnSpacing : 0,
                ),
                child: KanbanColumn(
                  status: status,
                  tasks: statusTasks,
                  onTaskTap: (task) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                  onStatusChanged: (taskId, newStatus) {
                    ref.read(tasksProvider.notifier).changeStatus(taskId, newStatus);
                  },
                ),
              );
            }).toList(),
          );
          
          if (needsScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(24),
              child: columnsRow,
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: columnsRow,
            );
          }
        },
      ),
    );
  }

  Widget _buildListView(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Задачи не найдены',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Нажмите "+" чтобы создать новую задачу',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(task: task),
              ),
            );
          },
          onStatusChanged: (newStatus) {
            ref
                .read(tasksProvider.notifier)
                .changeStatus(task.id, newStatus);
          },
        );
      },
    );
  }
}
