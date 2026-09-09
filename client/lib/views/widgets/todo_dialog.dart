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
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
                  value: _selectedStatus,
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
                Row(
                  children: [
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black),
                            const SizedBox(width: 6),
                            Text(
                              _dueDate == null ? '设置截止日期' : '截止: $_dueDate',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Text('✕ 清除', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
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
}
