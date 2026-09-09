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
    final provider = Provider.of<TodoProvider>(context, listen: false);

    return Draggable<TodoItem>(
      data: todo,
      feedback: Material(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4)),
            ],
          ),
          child: Text(
            todo.title,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildCardContent(context, provider),
      ),
      child: _buildCardContent(context, provider),
    );
  }

  Widget _buildCardContent(BuildContext context, TodoProvider provider) {
    Color pBg = const Color(0xFFF4F4F5);
    Color pFg = Colors.black;
    String pLabel = 'P3 低优';
    if (todo.priority == TodoPriority.high) {
      pBg = const Color(0xFFF87171);
      pFg = Colors.white;
      pLabel = 'P1 高优';
    } else if (todo.priority == TodoPriority.medium) {
      pBg = const Color(0xFFFEF08A);
      pFg = Colors.black;
      pLabel = 'P2 中优';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
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
              // 顶部行：优先级徽章 + 快捷状态步进 + 编辑/删除
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pBg,
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      pLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: pFg,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildQuickActionBtn(context, provider),
                  const SizedBox(width: 6),
                  // 编辑
                  _buildSmallBtn(
                    label: '✎',
                    tooltip: '编辑',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => TodoDialog(existingTodo: todo),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 删除
                  _buildSmallBtn(
                    label: '✕',
                    tooltip: '删除',
                    onTap: () => _confirmDelete(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 标题
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey.shade500 : Colors.black,
                  height: 1.35,
                ),
              ),

              // 描述
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    todo.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
              ],

              // 截止日期
              if (todo.dueDate != null && todo.dueDate!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      todo.dueDate!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.black54,
                      ),
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

  Widget _buildQuickActionBtn(BuildContext context, TodoProvider provider) {
    if (todo.status == TodoStatus.todo) {
      return _buildSmallBtn(
        label: '▶ 开始',
        color: const Color(0xFFBAE6FD),
        tooltip: '推进至进行中',
        onTap: () => provider.changeTaskStatus(todo.id, TodoStatus.inProgress),
      );
    } else if (todo.status == TodoStatus.inProgress) {
      return _buildSmallBtn(
        label: '✓ 搞定',
        color: const Color(0xFFBBF7D0),
        tooltip: '标记为完成',
        onTap: () => provider.changeTaskStatus(todo.id, TodoStatus.done),
      );
    } else {
      return _buildSmallBtn(
        label: '↺ 重开',
        color: const Color(0xFFFEF08A),
        tooltip: '重新开启任务',
        onTap: () => provider.changeTaskStatus(todo.id, TodoStatus.todo),
      );
    }
  }

  Widget _buildSmallBtn({
    required String label,
    Color color = Colors.white,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(1, 1)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TodoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💥 确认删除', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('确定要删除任务「${todo.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteTask(todo.id);
            },
            child: const Text('确认删除', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
