import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_dialog.dart';

class KanbanView extends StatelessWidget {
  const KanbanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          // 移动端 (Android 等)：横向滚动泳道
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                KanbanColumn(
                  status: TodoStatus.todo,
                  columnWidth: 300,
                  headerColor: Color(0xFFFEF08A),
                  title: '📌 待办 (TODO)',
                ),
                SizedBox(width: 16),
                KanbanColumn(
                  status: TodoStatus.inProgress,
                  columnWidth: 300,
                  headerColor: Color(0xFFBAE6FD),
                  title: '⚡ 进行中 (IN PROGRESS)',
                ),
                SizedBox(width: 16),
                KanbanColumn(
                  status: TodoStatus.done,
                  columnWidth: 300,
                  headerColor: Color(0xFFBBF7D0),
                  title: '🎉 已完成 (DONE)',
                ),
              ],
            ),
          );
        } else {
          // 桌面端宽屏 (Windows / Linux)：三列均分完全铺满屏幕！
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.todo,
                    headerColor: Color(0xFFFEF08A),
                    title: '📌 待办 (TODO)',
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.inProgress,
                    headerColor: Color(0xFFBAE6FD),
                    title: '⚡ 进行中 (IN PROGRESS)',
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.done,
                    headerColor: Color(0xFFBBF7D0),
                    title: '🎉 已完成 (DONE)',
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class KanbanColumn extends StatefulWidget {
  final TodoStatus status;
  final double? columnWidth;
  final Color headerColor;
  final String title;

  const KanbanColumn({
    Key? key,
    required this.status,
    this.columnWidth,
    required this.headerColor,
    required this.title,
  }) : super(key: key);

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isDragHovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    final items = provider.getListByStatus(widget.status);

    return DragTarget<TodoItem>(
      onWillAcceptWithDetails: (details) => details.data.status != widget.status,
      onAcceptWithDetails: (details) {
        setState(() => _isDragHovered = false);
        provider.changeTaskStatus(details.data.id, widget.status);
      },
      onLeave: (_) => setState(() => _isDragHovered = false),
      onMove: (_) {
        if (!_isDragHovered) setState(() => _isDragHovered = true);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: widget.columnWidth,
          decoration: BoxDecoration(
            color: _isDragHovered ? const Color(0xFFFEFCE8) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.black,
              width: 2.5,
              style: _isDragHovered ? BorderStyle.solid : BorderStyle.solid,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 泳道头部 (Neo-Brutalism 糖果色标题栏)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.headerColor,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black, width: 2.5),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5.5),
                    topRight: Radius.circular(5.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 计数徽章
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 新增按钮
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => TodoDialog(initialStatus: widget.status),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              // 任务卡片列表
              Flexible(
                child: items.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.status == TodoStatus.done ? '🎯' : '📦',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isDragHovered ? '松开卡片以移入' : '暂无任务\n可拖拽卡片至此',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return TodoCard(
                            key: ValueKey(items[index].id),
                            todo: items[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
