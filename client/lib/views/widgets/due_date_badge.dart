import 'package:flutter/material.dart';
import '../../models/todo.dart';

class DueDateBadge extends StatelessWidget {
  final TodoItem todo;
  final bool compact;

  const DueDateBadge({
    Key? key,
    required this.todo,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!todo.hasDueDate) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color fgColor;
    Color borderColor;
    IconData icon;
    String text;

    if (todo.isCompleted) {
      bgColor = const Color(0xFFF4F4F5);
      fgColor = Colors.grey.shade500;
      borderColor = const Color(0xFFE4E4E7);
      icon = Icons.event_available_outlined;
      text = todo.dueDate!;
    } else if (todo.isOverdue) {
      bgColor = const Color(0xFFFEE2E2);
      fgColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
      final days = todo.overdueDays ?? 0;
      text = days > 0 ? '⚠️ 逾期 $days 天 (${todo.dueDate})' : '⚠️ 已逾期 (${todo.dueDate})';
    } else if (todo.isDueToday) {
      bgColor = const Color(0xFFFEF3C7);
      fgColor = const Color(0xFFB45309);
      borderColor = Colors.black;
      icon = Icons.alarm_rounded;
      text = '⏰ 今天截止';
    } else if (todo.isDueTomorrow) {
      bgColor = const Color(0xFFE0F2FE);
      fgColor = const Color(0xFF0369A1);
      borderColor = Colors.black;
      icon = Icons.schedule_rounded;
      text = '📅 明天截止';
    } else {
      final daysLeft = todo.daysUntilDue;
      if (daysLeft != null && daysLeft <= 7 && daysLeft > 0) {
        bgColor = const Color(0xFFF3E8FF);
        fgColor = const Color(0xFF7E22CE);
        borderColor = Colors.black;
        icon = Icons.event_outlined;
        text = '📅 $daysLeft 天后 (${todo.dueDate})';
      } else {
        bgColor = const Color(0xFFF4F4F5);
        fgColor = Colors.black87;
        borderColor = Colors.black;
        icon = Icons.calendar_today_outlined;
        text = '📅 ${todo.dueDate}';
      }
    }

    if (compact) {
      // 紧凑模式下更简短
      if (todo.isOverdue) {
        final days = todo.overdueDays ?? 0;
        text = days > 0 ? '逾期 ${days}d' : '已逾期';
      } else if (todo.isDueToday) {
        text = '今天截止';
      } else if (todo.isDueTomorrow) {
        text = '明天截止';
      } else {
        text = todo.dueDate ?? '';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: (todo.isOverdue || todo.isDueToday) && !todo.isCompleted
            ? const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1.5, 1.5),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 11 : 13,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: fgColor,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
