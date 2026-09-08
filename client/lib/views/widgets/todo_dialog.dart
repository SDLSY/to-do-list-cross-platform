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

    return AlertDialog(
      title: Text(isEditing ? '编辑任务' : '新建任务'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题',
                    hintText: '如：完成跨平台待办调研',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '请输入任务标题';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 描述输入
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: '详细备注 (可选)',
                    hintText: '补充任务细节...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // 优先级选择
                const Text('优先级', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: TodoPriority.values.map((p) {
                    final isSelected = _selectedPriority == p;
                    final color = Color(p.colorHex);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: isSelected,
                        selectedColor: color.withOpacity(0.25),
                        labelStyle: TextStyle(
                          color: isSelected ? color : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPriority = p);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 状态选择
                const Text('状态', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<TodoStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: TodoStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    );
                  }).toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _selectedStatus = s);
                  },
                ),
                const SizedBox(height: 16),
                // 截止日期
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_dueDate == null ? '设置截止日期' : '日期: $_dueDate'),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? '保存修改' : '立即创建'),
        ),
      ],
    );
  }
}
