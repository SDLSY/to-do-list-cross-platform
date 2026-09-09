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
        // 筛选标签栏 (Neo-Brutalism Filters)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          child: Row(
            children: [
              _buildFilterChip('ALL (${provider.todos.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('TODO (${provider.todos.where((t) => !t.isCompleted).length})', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('DONE (${provider.todos.where((t) => t.isCompleted).length})', 'completed'),
            ],
          ),
        ),

        // 列表展示
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📂', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        '当前分类暂无任务',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    Color pBg = const Color(0xFFF4F4F5);
                    Color pFg = Colors.black;
                    String pText = 'P3 低优';
                    if (item.priority == TodoPriority.high) {
                      pBg = const Color(0xFFF87171);
                      pFg = Colors.white;
                      pText = 'P1 高优';
                    } else if (item.priority == TodoPriority.medium) {
                      pBg = const Color(0xFFFEF08A);
                      pFg = Colors.black;
                      pText = 'P2 中优';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: InkWell(
                          onTap: () {
                            provider.changeTaskStatus(
                              item.id,
                              item.isCompleted ? TodoStatus.todo : TodoStatus.done,
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: item.isCompleted ? const Color(0xFF4ADE80) : Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(1, 1)),
                              ],
                            ),
                            child: item.isCompleted
                                ? const Center(
                                    child: Text(
                                      '✓',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? Colors.grey.shade500 : Colors.black,
                          ),
                        ),
                        subtitle: item.description.isNotEmpty
                            ? Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: pBg,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                pText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: pFg,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => TodoDialog(existingTodo: item),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('✎', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => provider.deleteTask(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('✕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF08A) : Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: Colors.black,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
