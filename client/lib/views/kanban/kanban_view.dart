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
        final isNarrow = constraints.maxWidth < 768;

        if (isNarrow) {
          // 移动端：横向滚动浏览各个泳道
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                KanbanColumn(
                  status: TodoStatus.todo,
                  columnWidth: 280,
                  accentColor: Colors.blue,
                ),
                SizedBox(width: 12),
                KanbanColumn(
                  status: TodoStatus.inProgress,
                  columnWidth: 280,
                  accentColor: Colors.orange,
                ),
                SizedBox(width: 12),
                KanbanColumn(
                  status: TodoStatus.done,
                  columnWidth: 280,
                  accentColor: Colors.green,
                ),
              ],
            ),
          );
        } else {
          // 桌面端宽屏：等比平铺三列
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.todo,
                    accentColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.inProgress,
                    accentColor: Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: KanbanColumn(
                    status: TodoStatus.done,
                    accentColor: Colors.green,
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
  final Color accentColor;

  const KanbanColumn({
    Key? key,
    required this.status,
    this.columnWidth,
    required this.accentColor,
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
    final theme = Theme.of(context);

    return DragTarget<TodoItem>(
      onWillAccept: (item) => item != null && item.status != widget.status,
      onAccept: (item) {
        setState(() => _isDragHovered = false);
        provider.changeTaskStatus(item.id, widget.status);
      },
      onLeave: (_) => setState(() => _isDragHovered = false),
      onMove: (_) {
        if (!_isDragHovered) setState(() => _isDragHovered = true);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: widget.columnWidth,
          decoration: BoxDecoration(
            color: _isDragHovered
                ? widget.accentColor.withOpacity(0.08)
                : theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDragHovered ? widget.accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 泳道头部
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.status.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      splashRadius: 18,
                      tooltip: '向${widget.status.label}添加任务',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => TodoDialog(initialStatus: widget.status),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 任务列表
              Flexible(
                child: items.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        alignment: Alignment.center,
                        child: Text(
                          _isDragHovered ? '松开以移至此处' : '暂无任务\n可拖拽卡片至此',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(8),
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
