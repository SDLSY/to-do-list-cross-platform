import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import 'todo_dialog.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;

  const TodoCard({Key? key, required this.todo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TodoProvider>(context, listen: false);

    return Draggable<TodoItem>(
      data: todo,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.primaryColor.withOpacity(0.5), width: 2),
          ),
          child: Text(
            todo.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(context, provider),
      ),
      child: _buildCardContent(context, provider),
    );
  }

  Widget _buildCardContent(BuildContext context, TodoProvider provider) {
    final priorityColor = Color(todo.priority.colorHex);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: todo.isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => TodoDialog(existingTodo: todo),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部行：优先级标签 + 快捷操作按钮
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          todo.priority.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 移动端/快捷状态流转按钮
                  _buildQuickActionButton(context, provider),
                  // 删除按钮
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 标题
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey : null,
                ),
              ),
              // 描述
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  todo.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              // 底部状态信息
              if (todo.dueDate != null && todo.dueDate!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      todo.dueDate!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, TodoProvider provider) {
    if (todo.status == TodoStatus.todo) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.blue),
        label: const Text('开始', style: TextStyle(fontSize: 12, color: Colors.blue)),
        onPressed: () => provider.changeTaskStatus(todo.id, TodoStatus.inProgress),
      );
    } else if (todo.status == TodoStatus.inProgress) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
        label: const Text('完成', style: TextStyle(fontSize: 12, color: Colors.green)),
        onPressed: () => provider.changeTaskStatus(todo.id, TodoStatus.done),
      );
    } else {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.orange),
        label: const Text('重开', style: TextStyle(fontSize: 12, color: Colors.orange)),
        onPressed: () => provider.changeTaskStatus(todo.id, TodoStatus.todo),
      );
    }
  }

  void _confirmDelete(BuildContext context, TodoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除任务「${todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteTask(todo.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
