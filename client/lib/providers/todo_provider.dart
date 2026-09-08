import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/todo.dart';
import '../services/pocketbase_service.dart';

class TodoProvider with ChangeNotifier {
  final PocketBaseService _apiService;

  List<TodoItem> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;

  TodoProvider(this._apiService);

  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _apiService.isConnected;
  String get serverUrl => _apiService.serverUrl;

  List<TodoItem> getListByStatus(TodoStatus status) {
    return _todos.where((item) => item.status == status).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // 初始化并开启实时订阅
  Future<void> initialize() async {
    await _apiService.init();
    await loadTodos();
    _setupSubscription();
  }

  // 更新服务器地址
  Future<bool> updateServerUrl(String newUrl) async {
    final success = await _apiService.setServerUrl(newUrl);
    if (success) {
      await loadTodos();
      _setupSubscription();
    }
    notifyListeners();
    return success;
  }

  // 从服务端拉取完整列表
  Future<void> loadTodos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todos = await _apiService.fetchTodos();
    } catch (e) {
      _errorMessage = '连接服务器失败，请检查后端运行状态或服务器地址';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 设置实时订阅
  void _setupSubscription() {
    _apiService.subscribeToChanges((RecordSubscriptionEvent event) {
      if (event.record == null) return;
      final updatedItem = TodoItem.fromRecord(event.record!);

      if (event.action == 'create') {
        final existingIndex = _todos.indexWhere((t) => t.id == updatedItem.id);
        if (existingIndex == -1) {
          _todos.add(updatedItem);
        } else {
          _todos[existingIndex] = updatedItem;
        }
      } else if (event.action == 'update') {
        final index = _todos.indexWhere((t) => t.id == updatedItem.id);
        if (index != -1) {
          _todos[index] = updatedItem;
        } else {
          _todos.add(updatedItem);
        }
      } else if (event.action == 'delete') {
        _todos.removeWhere((t) => t.id == updatedItem.id);
      }
      notifyListeners();
    });
  }

  // 创建新任务
  Future<void> addTodo({
    required String title,
    String description = '',
    TodoStatus status = TodoStatus.todo,
    TodoPriority priority = TodoPriority.medium,
    String? dueDate,
  }) async {
    // 计算新 order（当前状态列表中最大的 order + 1000）
    final currentList = getListByStatus(status);
    final double nextOrder = currentList.isEmpty
        ? 1000.0
        : (currentList.last.order + 1000.0);

    try {
      final created = await _apiService.createTodo(
        title: title,
        description: description,
        status: status,
        priority: priority,
        order: nextOrder,
        dueDate: dueDate,
      );
      if (!_todos.any((t) => t.id == created.id)) {
        _todos.add(created);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '创建任务失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 乐观更新任务状态（快速流转，零延迟响应）
  Future<void> changeTaskStatus(String id, TodoStatus newStatus) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final oldItem = _todos[index];
    if (oldItem.status == newStatus) return;

    // 1. 乐观更新本地数据
    final targetList = getListByStatus(newStatus);
    final newOrder = targetList.isEmpty
        ? 1000.0
        : (targetList.last.order + 1000.0);

    final updatedLocal = oldItem.copyWith(status: newStatus, order: newOrder);
    _todos[index] = updatedLocal;
    notifyListeners();

    // 2. 异步同步到后端
    try {
      await _apiService.updateTodo(id, {
        'status': newStatus.value,
        'order': newOrder,
      });
    } catch (e) {
      // 失败回滚
      _todos[index] = oldItem;
      _errorMessage = '更新失败，已还原';
      notifyListeners();
    }
  }

  // 拖拽排序/换列
  Future<void> moveTask(String id, TodoStatus newStatus, int newIndex) async {
    final taskIndex = _todos.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final task = _todos[taskIndex];
    final targetList = getListByStatus(newStatus).where((t) => t.id != id).toList();

    double calculatedOrder = 1000.0;
    if (targetList.isEmpty) {
      calculatedOrder = 1000.0;
    } else if (newIndex <= 0) {
      calculatedOrder = targetList.first.order - 500.0;
    } else if (newIndex >= targetList.length) {
      calculatedOrder = targetList.last.order + 500.0;
    } else {
      calculatedOrder = (targetList[newIndex - 1].order + targetList[newIndex].order) / 2.0;
    }

    final updatedTask = task.copyWith(status: newStatus, order: calculatedOrder);
    _todos[taskIndex] = updatedTask;
    notifyListeners();

    try {
      await _apiService.updateTodo(id, {
        'status': newStatus.value,
        'order': calculatedOrder,
      });
    } catch (e) {
      _todos[taskIndex] = task;
      _errorMessage = '拖拽保存失败';
      notifyListeners();
    }
  }

  // 编辑任务详情
  Future<void> updateTaskDetails({
    required String id,
    required String title,
    required String description,
    required TodoPriority priority,
    String? dueDate,
  }) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final oldItem = _todos[index];
    final updated = oldItem.copyWith(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    _todos[index] = updated;
    notifyListeners();

    try {
      await _apiService.updateTodo(id, {
        'title': title,
        'description': description,
        'priority': priority.value,
        'due_date': dueDate ?? '',
      });
    } catch (e) {
      _todos[index] = oldItem;
      notifyListeners();
      rethrow;
    }
  }

  // 删除任务
  Future<void> deleteTask(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final removed = _todos.removeAt(index);
    notifyListeners();

    try {
      await _apiService.deleteTodo(id);
    } catch (e) {
      _todos.insert(index, removed);
      _errorMessage = '删除失败';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _apiService.unsubscribe();
    super.dispose();
  }
}
