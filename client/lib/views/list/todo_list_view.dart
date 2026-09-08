import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../widgets/todo_dialog.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({Key? key}) : super(key: key);

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  String _filter = 'all'; // 'all', 'active', 'completed'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    List<TodoItem> filteredList;

    if (_filter == 'active') {
      filteredList = provider.todos.where((t) => !t.isCompleted).toList();
    } else if (_filter == 'completed') {
      filteredList = provider.todos.where((t) => t.isCompleted).toList();
    } else {
      filteredList = List.from(provider.todos);
    }

    // 排序：未完成在前，高优先级在前
    filteredList.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.priority.value.compareTo(a.priority.value);
    });

    return Column(
      children: [
        // 筛选标签栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: Text('全部 (${provider.todos.length})'),
                selected: _filter == 'all',
                onSelected: (_) => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('未完成 (${provider.todos.where((t) => !t.isCompleted).length})'),
                selected: _filter == 'active',
                onSelected: (_) => setState(() => _filter = 'active'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('已完成 (${provider.todos.where((t) => t.isCompleted).length})'),
                selected: _filter == 'completed',
                onSelected: (_) => setState(() => _filter = 'completed'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 列表展示
        Expanded(
          child: filteredList.isEmpty
              ? const Center(
                  child: Text(
                    '当前无匹配任务',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final priorityColor = Color(item.priority.colorHex);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isCompleted,
                          activeColor: Colors.green,
                          shape: const CircleBorder(),
                          onChanged: (val) {
                            provider.changeTaskStatus(
                              item.id,
                              (val == true) ? TodoStatus.done : TodoStatus.todo,
                            );
                          },
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        subtitle: item.description.isNotEmpty
                            ? Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.priority.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () => provider.deleteTask(item.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => TodoDialog(existingTodo: item),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
