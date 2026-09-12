import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:todo_sync_app/models/todo.dart';
import 'package:todo_sync_app/views/widgets/due_date_badge.dart';

void main() {
  testWidgets('DueDateBadge renders overdue task with alert styling', (WidgetTester tester) async {
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 2)));
    final todo = TodoItem(
      id: '1',
      title: 'Overdue task',
      dueDate: yesterdayStr,
      status: TodoStatus.todo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DueDateBadge(todo: todo),
        ),
      ),
    );

    expect(find.textContaining('逾期 2 天'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('DueDateBadge renders today task correctly', (WidgetTester tester) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todo = TodoItem(
      id: '2',
      title: 'Today task',
      dueDate: todayStr,
      status: TodoStatus.todo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DueDateBadge(todo: todo),
        ),
      ),
    );

    expect(find.text('⏰ 今天截止'), findsOneWidget);
    expect(find.byIcon(Icons.alarm_rounded), findsOneWidget);
  });

  testWidgets('DueDateBadge renders nothing if task has no due date', (WidgetTester tester) async {
    final todo = TodoItem(
      id: '3',
      title: 'No due date',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DueDateBadge(todo: todo),
        ),
      ),
    );

    expect(find.byType(DueDateBadge), findsOneWidget);
    expect(find.byType(Container), findsNothing);
  });
}
