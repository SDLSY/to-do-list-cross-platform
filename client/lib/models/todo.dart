import 'package:pocketbase/pocketbase.dart';

enum TodoStatus {
  todo('todo', '待办'),
  inProgress('in_progress', '进行中'),
  done('done', '已完成');

  final String value;
  final String label;
  const TodoStatus(this.value, this.label);

  static TodoStatus fromString(String val) {
    return TodoStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TodoStatus.todo,
    );
  }
}

enum TodoPriority {
  low(0, '低', 0xFF9E9E9E),
  medium(1, '中', 0xFFFF9800),
  high(2, '高', 0xFFF44336);

  final int value;
  final String label;
  final int colorHex;
  const TodoPriority(this.value, this.label, this.colorHex);

  static TodoPriority fromInt(int val) {
    return TodoPriority.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TodoPriority.medium,
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  final String description;
  final TodoStatus status;
  final TodoPriority priority;
  final double order;
  final String? dueDate;
  final DateTime? created;
  final DateTime? updated;

  TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TodoStatus.todo,
    this.priority = TodoPriority.medium,
    this.order = 1000.0,
    this.dueDate,
    this.created,
    this.updated,
  });

  bool get isCompleted => status == TodoStatus.done;

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    TodoStatus? status,
    TodoPriority? priority,
    double? order,
    String? dueDate,
    DateTime? created,
    DateTime? updated,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      order: order ?? this.order,
      dueDate: dueDate ?? this.dueDate,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  factory TodoItem.fromRecord(RecordModel record) {
    return TodoItem(
      id: record.id,
      title: record.getStringValue('title'),
      description: record.getStringValue('description'),
      status: TodoStatus.fromString(record.getStringValue('status')),
      priority: TodoPriority.fromInt(record.getIntValue('priority', 1)),
      order: (record.data['order'] is num)
          ? (record.data['order'] as num).toDouble()
          : 1000.0,
      dueDate: record.getStringValue('due_date').isEmpty
          ? null
          : record.getStringValue('due_date'),
      created: DateTime.tryParse(record.created),
      updated: DateTime.tryParse(record.updated),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'order': order,
      'due_date': dueDate ?? '',
    };
  }
}
