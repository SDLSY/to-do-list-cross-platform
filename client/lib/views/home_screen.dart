import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import 'kanban/kanban_view.dart';
import 'list/todo_list_view.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/todo_dialog.dart';

enum ViewMode { kanban, list }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewMode _viewMode = ViewMode.kanban;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              '三端同步待办',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 10),
            // 在线/离线指示器
            Tooltip(
              message: provider.isConnected ? '服务已连接（实时同步中）' : '服务未连接（点击右侧设置）',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (provider.isConnected ? Colors.green : Colors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isConnected ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: provider.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.isConnected ? '实时同步' : '未连接',
                      style: TextStyle(
                        fontSize: 11,
                        color: provider.isConnected ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // 视图模式切换 (看板 / 列表)
          SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(
                value: ViewMode.kanban,
                icon: Icon(Icons.view_column_outlined, size: 18),
                tooltip: '看板视图',
              ),
              ButtonSegment(
                value: ViewMode.list,
                icon: Icon(Icons.format_list_bulleted, size: 18),
                tooltip: '清单视图',
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (set) => setState(() => _viewMode = set.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // 手动刷新
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '手动刷新',
            onPressed: () => provider.loadTodos(),
          ),
          // 服务器设置
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: '服务器设置',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _viewMode == ViewMode.kanban
              ? const KanbanView()
              : const TodoListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const TodoDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('新建任务'),
      ),
    );
  }
}
