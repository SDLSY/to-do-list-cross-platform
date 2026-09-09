import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
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
    final total = provider.todos.length;
    final doneCount = provider.todos.where((t) => t.isCompleted).length;
    final todoCount = provider.todos.where((t) => t.status == TodoStatus.todo).length;
    final progCount = provider.todos.where((t) => t.status == TodoStatus.inProgress).length;
    final double pct = total == 0 ? 0.0 : (doneCount / total);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 2.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 复古 Neo-Brutalism LOGO
                  Transform.rotate(
                    angle: -0.02,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: const Text(
                        '⚡ RETRO TASK',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 实时同步胶囊
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: provider.isConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.isConnected ? 'LIVE' : 'OFFLINE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 宽屏模式下显示统计仪表盘 (Windows / 桌面端)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 460) return const SizedBox.shrink();
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatChip('ALL', '$total', Colors.black),
                                const SizedBox(width: 8),
                                _buildStatChip('TODO', '$todoCount', const Color(0xFFD97706)),
                                const SizedBox(width: 8),
                                _buildStatChip('PROG', '$progCount', const Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                _buildStatChip('DONE', '$doneCount', const Color(0xFF16A34A)),
                                const SizedBox(width: 12),
                                // 进度条
                                SizedBox(
                                  width: 90,
                                  height: 12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F5),
                                        border: Border.all(color: Colors.black, width: 1.5),
                                      ),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.transparent,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(pct * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 视图模式切换 (看板 / 清单)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewBtn(
                          icon: Icons.view_column_rounded,
                          tooltip: '看板',
                          selected: _viewMode == ViewMode.kanban,
                          onTap: () => setState(() => _viewMode = ViewMode.kanban),
                        ),
                        Container(width: 1.5, height: 26, color: Colors.black),
                        _buildViewBtn(
                          icon: Icons.format_list_bulleted_rounded,
                          tooltip: '清单',
                          selected: _viewMode == ViewMode.list,
                          onTap: () => setState(() => _viewMode = ViewMode.list),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 刷新
                  _buildIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: '刷新',
                    onTap: () => provider.loadTodos(),
                  ),
                  const SizedBox(width: 6),

                  // 同步配置
                  _buildIconButton(
                    icon: Icons.cloud_sync_outlined,
                    tooltip: '连接设置',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : _viewMode == ViewMode.kanban
              ? const KanbanView()
              : const TodoListView(),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(4, 4)),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFEF08A),
          foregroundColor: Colors.black,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Colors.black, width: 2.5),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const TodoDialog(),
            );
          },
          icon: const Icon(Icons.add, weight: 800),
          label: const Text(
            '新建任务',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildViewBtn({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: selected ? const Color(0xFFFEF08A) : Colors.transparent,
          child: Icon(icon, size: 18, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.black),
        ),
      ),
    );
  }
}
