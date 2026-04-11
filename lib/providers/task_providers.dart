import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
      return TasksNotifier(ref.watch(taskRepositoryProvider));
    });

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks({String? status, String? priority}) async {
    try {
      final tasks = await _repository.getTasks(
        status: status,
        priority: priority,
      );
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchTasks(String query) async {
    if (query.isEmpty) {
      await loadTasks();
      return;
    }
    try {
      state = const AsyncValue.loading();
      final tasks = await _repository.searchTasks(query);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _repository.createTask(task);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _repository.updateTask(task);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> changeStatus(String taskId, String newStatus) async {
    try {
      await _repository.changeStatus(taskId, newStatus);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final filterStatus = ref.watch(filterStatusProvider);
  final filterPriority = ref.watch(filterPriorityProvider);
  ref.watch(searchQueryProvider);

  return tasksAsync.when(
    data: (tasks) {
      var filtered = tasks;
      if (filterStatus != null) {
        filtered = filtered.where((t) => t.status == filterStatus).toList();
      }
      if (filterPriority != null) {
        filtered = filtered.where((t) => t.priority == filterPriority).toList();
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

final filterStatusProvider = StateProvider<String?>((ref) => null);
final filterPriorityProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final userNameProvider = StateProvider<String>((ref) => '');
