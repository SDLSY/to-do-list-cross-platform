import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:todo_sync_app/models/todo.dart';

void main() {
  group('TodoItem DueDate Tests', () {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    final threeDaysAgoStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));
    final nextWeekStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 5)));

    test('hasDueDate returns false when null or empty', () {
      final t1 = TodoItem(id: '1', title: 'Task 1');
      final t2 = TodoItem(id: '2', title: 'Task 2', dueDate: '');
      final t3 = TodoItem(id: '3', title: 'Task 3', dueDate: '   ');
      final t4 = TodoItem(id: '4', title: 'Task 4', dueDate: todayStr);

      expect(t1.hasDueDate, isFalse);
      expect(t2.hasDueDate, isFalse);
      expect(t3.hasDueDate, isFalse);
      expect(t4.hasDueDate, isTrue);
    });

    test('isOverdue correctly detects overdue uncompleted tasks', () {
      final overdueTask = TodoItem(
        id: '1',
        title: 'Overdue task',
        dueDate: yesterdayStr,
        status: TodoStatus.todo,
      );
      final completedOverdue = TodoItem(
        id: '2',
        title: 'Done task',
        dueDate: yesterdayStr,
        status: TodoStatus.done,
      );
      final todayTask = TodoItem(
        id: '3',
        title: 'Today task',
        dueDate: todayStr,
        status: TodoStatus.todo,
      );

      expect(overdueTask.isOverdue, isTrue);
      expect(overdueTask.overdueDays, equals(1));
      expect(completedOverdue.isOverdue, isFalse); // completed tasks are not considered overdue
      expect(todayTask.isOverdue, isFalse);
    });

    test('isDueToday and isDueTomorrow', () {
      final todayTask = TodoItem(
        id: '1',
        title: 'Today task',
        dueDate: todayStr,
      );
      final tomorrowTask = TodoItem(
        id: '2',
        title: 'Tomorrow task',
        dueDate: tomorrowStr,
      );

      expect(todayTask.isDueToday, isTrue);
      expect(todayTask.isDueTomorrow, isFalse);

      expect(tomorrowTask.isDueToday, isFalse);
      expect(tomorrowTask.isDueTomorrow, isTrue);
    });

    test('dueBadgeText formatting', () {
      final overdue3Days = TodoItem(
        id: '1',
        title: 'Overdue 3 days',
        dueDate: threeDaysAgoStr,
      );
      expect(overdue3Days.dueBadgeText, contains('已逾期 3 天'));

      final todayTask = TodoItem(
        id: '2',
        title: 'Today',
        dueDate: todayStr,
      );
      expect(todayTask.dueBadgeText, equals('今天截止'));

      final tomorrowTask = TodoItem(
        id: '3',
        title: 'Tomorrow',
        dueDate: tomorrowStr,
      );
      expect(tomorrowTask.dueBadgeText, equals('明天截止'));

      final nextWeekTask = TodoItem(
        id: '4',
        title: 'Next week',
        dueDate: nextWeekStr,
      );
      expect(nextWeekTask.dueBadgeText, contains('还剩 5 天'));
    });
  });
}
