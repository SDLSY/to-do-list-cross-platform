import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class PocketBaseService {
  static const String _serverUrlKey = 'pb_server_url';
  static const String defaultServerUrl = 'http://127.0.0.1:8090';

  late PocketBase _pb;
  String _currentServerUrl = defaultServerUrl;
  bool _isConnected = false;

  PocketBase get pb => _pb;
  String get serverUrl => _currentServerUrl;
  bool get isConnected => _isConnected;

  PocketBaseService() {
    _pb = PocketBase(defaultServerUrl);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentServerUrl = prefs.getString(_serverUrlKey) ?? defaultServerUrl;
    _pb = PocketBase(_currentServerUrl);
    await testConnection();
  }

  Future<bool> setServerUrl(String newUrl) async {
    final formattedUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _currentServerUrl = formattedUrl;
    _pb = PocketBase(formattedUrl);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, formattedUrl);

    return await testConnection();
  }

  Future<bool> testConnection() async {
    try {
      final health = await _pb.health.check();
      _isConnected = (health.code == 200);
    } catch (_) {
      _isConnected = false;
    }
    return _isConnected;
  }

  // 获取所有任务
  Future<List<TodoItem>> fetchTodos() async {
    try {
      final records = await _pb.collection('todos').getFullList(
        sort: 'order,-created',
      );
      _isConnected = true;
      return records.map((r) => TodoItem.fromRecord(r)).toList();
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  // 创建任务
  Future<TodoItem> createTodo({
    required String title,
    String description = '',
    TodoStatus status = TodoStatus.todo,
    TodoPriority priority = TodoPriority.medium,
    double? order,
    String? dueDate,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'order': order ?? DateTime.now().millisecondsSinceEpoch.toDouble(),
      'due_date': dueDate ?? '',
    };
    final record = await _pb.collection('todos').create(body: body);
    return TodoItem.fromRecord(record);
  }

  // 更新任务
  Future<TodoItem> updateTodo(String id, Map<String, dynamic> data) async {
    final record = await _pb.collection('todos').update(id, body: data);
    return TodoItem.fromRecord(record);
  }

  // 删除任务
  Future<void> deleteTodo(String id) async {
    await _pb.collection('todos').delete(id);
  }

  // 订阅实时事件 (SSE / WebSocket)
  Future<void> Function()? _unsubscribeCallback;

  Future<void> subscribeToChanges(void Function(RecordSubscriptionEvent event) onEvent) async {
    try {
      await unsubscribe();
      _unsubscribeCallback = await _pb.collection('todos').subscribe('*', onEvent);
    } catch (e) {
      // 连接订阅异常记录
    }
  }

  Future<void> unsubscribe() async {
    if (_unsubscribeCallback != null) {
      await _pb.collection('todos').unsubscribe('*');
      _unsubscribeCallback = null;
    }
  }
}
