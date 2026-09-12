import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';

class TodoDialog extends StatefulWidget {
  final TodoItem? existingTodo;
  final TodoStatus? initialStatus;

  const TodoDialog({Key? key, this.existingTodo, this.initialStatus}) : super(key: key);

  @override
  State<TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TodoStatus _selectedStatus;
  late TodoPriority _selectedPriority;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    final item = widget.existingTodo;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _selectedStatus = item?.status ?? widget.initialStatus ?? TodoStatus.todo;
    _selectedPriority = item?.priority ?? TodoPriority.medium;
    _dueDate = item?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dueDate != null ? (DateTime.tryParse(_dueDate!) ?? now) : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _setQuickDate(int daysFromNow) {
    final target = DateTime.now().add(Duration(days: daysFromNow));
    setState(() {
      _dueDate = DateFormat('yyyy-MM-dd').format(target);
    });
  }

  void _setNextWeekday(int targetWeekday) {
    final now = DateTime.now();
    int daysToAdd = (targetWeekday - now.weekday + 7) % 7;
    if (daysToAdd == 0) daysToAdd = 7;
    final target = now.add(Duration(days: daysToAdd));
    setState(() {
      _dueDate = DateFormat('yyyy-MM-dd').format(target);
    });
  }

  String _getDueDateDescription() {
    if (_dueDate == null) return '';
    final parsed = DateTime.tryParse(_dueDate!);
    if (parsed == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return '⚠️ 已逾期 ${-diff} 天';
    if (diff == 0) return '⏰ 今天截止';
    if (diff == 1) return '📅 明天截止';
    if (diff <= 7) return '📅 $diff 天后截止';
    return '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TodoProvider>(context, listen: false);
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (widget.existingTodo == null) {
      provider.addTodo(
        title: title,
        description: desc,
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _dueDate,
      );
    } else {
      provider.updateTaskDetails(
        id: widget.existingTodo!.id,
        title: title,
        description: desc,
        priority: _selectedPriority,
        dueDate: _dueDate,
      );
      if (widget.existingTodo!.status != _selectedStatus) {
        provider.changeTaskStatus(widget.existingTodo!.id, _selectedStatus);
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTodo != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 2.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(6, 6)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? '✎ 编辑任务事项' : '⚡ 新建待办任务',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('✕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 任务标题输入框
                const Text('任务标题 *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '输入待办核心事项...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '请输入任务标题';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 备注输入框
                const Text('备注描述 (可选)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: '补充任务细节或验收标准...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.5),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),

                // 优先级选择
                const Text('优先级', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                const SizedBox(height: 6),
                Row(
                  children: TodoPriority.values.map((p) {
                    final isSelected = _selectedPriority == p;
                    Color pBg = Colors.white;
                    Color pFg = Colors.black;
                    if (p == TodoPriority.high) {
                      pBg = const Color(0xFFF87171);
                      if (isSelected) pFg = Colors.white;
                    } else if (p == TodoPriority.medium) {
                      pBg = const Color(0xFFFEF08A);
                    } else {
                      pBg = const Color(0xFFF4F4F5);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? pBg : Colors.white,
                            border: Border.all(color: Colors.black, width: isSelected ? 2 : 1.5),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : null,
                          ),
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                              color: pFg,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 状态选择
                const Text('当前状态', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                DropdownButtonFormField<TodoStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.5),
                    ),
                  ),
                  items: TodoStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _selectedStatus = s);
                  },
                ),
                const SizedBox(height: 14),

                // 截止日期
                const Text('截止日期 (可选)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                const SizedBox(height: 6),

                // 快捷预设按钮组
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickDateChip(label: '今天', onTap: () => _setQuickDate(0)),
                    _buildQuickDateChip(label: '明天', onTap: () => _setQuickDate(1)),
                    _buildQuickDateChip(label: '本周日', onTap: () => _setNextWeekday(DateTime.sunday)),
                    _buildQuickDateChip(label: '下周一', onTap: () => _setNextWeekday(DateTime.monday)),
                    _buildQuickDateChip(
                      label: '📅 日历选择...',
                      onTap: _pickDate,
                      color: const Color(0xFFE0F2FE),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 当前截止日期详情展示与清除
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _dueDate != null ? const Color(0xFFFFFBEB) : const Color(0xFFF4F4F5),
                    border: Border.all(
                      color: _dueDate != null ? Colors.black : const Color(0xFFD4D4D8),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _dueDate != null ? Icons.event_note : Icons.calendar_today_outlined,
                        size: 16,
                        color: _dueDate != null ? Colors.black : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dueDate != null
                            ? RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: _dueDate!,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                                    ),
                                    if (_getDueDateDescription().isNotEmpty) ...[
                                      const TextSpan(text: '  '),
                                      TextSpan(
                                        text: _getDueDateDescription(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : Text(
                                '未设置截止日期',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                      ),
                      if (_dueDate != null)
                        InkWell(
                          onTap: () => setState(() => _dueDate = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(color: Colors.black, width: 1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '✕ 清除',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 底部操作栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                        ),
                        child: const Text('取消', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF08A),
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                        ),
                        child: Text(
                          isEditing ? '💾 保存修改' : '💾 立即创建',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip({
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
