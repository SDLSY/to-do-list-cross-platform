import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../widgets/due_date_badge.dart';
import '../widgets/todo_dialog.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({Key? key}) : super(key: key);

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  String _filter = 'all'; // 'all', 'active', 'overdue', 'today', 'completed'
  String _sortBy = 'priority'; // 'priority', 'dueDate', 'created'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    List<TodoItem> filteredList;

    if (_filter == 'active') {
      filteredList = provider.todos.where((t) => !t.isCompleted).toList();
    } else if (_filter == 'overdue') {
      filteredList = provider.todos.where((t) => t.isOverdue).toList();
    } else if (_filter == 'today') {
      filteredList = provider.todos.where((t) => !t.isCompleted && t.isDueToday).toList();
    } else if (_filter == 'completed') {
      filteredList = provider.todos.where((t) => t.isCompleted).toList();
    } else {
      filteredList = List.from(provider.todos);
    }

    // 排序逻辑
    filteredList.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (_sortBy == 'dueDate') {
        if (a.hasDueDate && b.hasDueDate) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.hasDueDate) {
          return -1;
        } else if (b.hasDueDate) {
          return 1;
        }
        return b.priority.value.compareTo(a.priority.value);
      } else if (_sortBy == 'created') {
        final aTime = a.created ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.created ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      } else {
        return b.priority.value.compareTo(a.priority.value);
      }
    });

    final overdueCount = provider.todos.where((t) => t.isOverdue).length;
    final todayCount = provider.todos.where((t) => !t.isCompleted && t.isDueToday).length;

    return Column(
      children: [
        // 筛选与排序栏 (Neo-Brutalism Filters & Sort)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL (${provider.todos.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('TODO (${provider.todos.where((t) => !t.isCompleted).length})', 'active'),
                      if (overdueCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '⚠️ 逾期 ($overdueCount)',
                          'overdue',
                          activeColor: const Color(0xFFFCA5A5),
                        ),
                      ],
                      if (todayCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '⏰ 今天 ($todayCount)',
                          'today',
                          activeColor: const Color(0xFFFDE047),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildFilterChip('DONE (${provider.todos.where((t) => t.isCompleted).length})', 'completed'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 排序下拉框
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    icon: const Icon(Icons.swap_vert, size: 16, color: Colors.black),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontFamily: 'monospace',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'priority', child: Text('排序: 优先级')),
                      DropdownMenuItem(value: 'dueDate', child: Text('排序: 截止日')),
                      DropdownMenuItem(value: 'created', child: Text('排序: 创建时间')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
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
                        border: Border.all(
                          color: item.isOverdue ? const Color(0xFFEF4444) : Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        subtitle: (item.description.isNotEmpty || item.hasDueDate)
                            ? Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.description.isNotEmpty)
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    if (item.description.isNotEmpty && item.hasDueDate)
                                      const SizedBox(height: 5),
                                    if (item.hasDueDate)
                                      DueDateBadge(todo: item, compact: true),
                                  ],
                                ),
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

  Widget _buildFilterChip(String label, String value, {Color? activeColor}) {
    final isSelected = _filter == value;
    final defaultBg = activeColor ?? const Color(0xFFFEF08A);

    return InkWell(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? defaultBg : Colors.white,
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
