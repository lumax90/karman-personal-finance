import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';

final _dateFormat = DateFormat('d MMM yyyy');

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final allReminders = ref.watch(reminderListProvider);
    final overdue = allReminders.where((r) => r.isOverdue).toList();
    final todayList = allReminders.where((r) => r.isDueToday && !r.isCompleted).toList();
    final upcoming = allReminders
        .where((r) => !r.isCompleted && !r.isOverdue && !r.isDueToday)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completed = allReminders.where((r) => r.isCompleted).toList();

    if (allReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(s.noReminders, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Overdue section
        if (overdue.isNotEmpty) ...[
          _SectionLabel(label: s.overdueTasks, color: AppColors.expense, count: overdue.length),
          const SizedBox(height: 6),
          ...overdue.map((r) => _ReminderTile(
            reminder: r,
            s: s,
            onToggle: () => ref.read(reminderListProvider.notifier).toggleComplete(r.id),
            onDismiss: () => ref.read(reminderListProvider.notifier).remove(r.id),
          )),
          const SizedBox(height: 12),
        ],

        // Today section
        if (todayList.isNotEmpty) ...[
          _SectionLabel(label: s.today, color: AppColors.warning, count: todayList.length),
          const SizedBox(height: 6),
          ...todayList.map((r) => _ReminderTile(
            reminder: r,
            s: s,
            onToggle: () => ref.read(reminderListProvider.notifier).toggleComplete(r.id),
            onDismiss: () => ref.read(reminderListProvider.notifier).remove(r.id),
          )),
          const SizedBox(height: 12),
        ],

        // Upcoming section
        if (upcoming.isNotEmpty) ...[
          _SectionLabel(label: s.upcoming, color: AppColors.primary, count: upcoming.length),
          const SizedBox(height: 6),
          ...upcoming.map((r) => _ReminderTile(
            reminder: r,
            s: s,
            onToggle: () => ref.read(reminderListProvider.notifier).toggleComplete(r.id),
            onDismiss: () => ref.read(reminderListProvider.notifier).remove(r.id),
          )),
          const SizedBox(height: 12),
        ],

        // Completed section
        if (completed.isNotEmpty) ...[
          _SectionLabel(label: s.completed, color: AppColors.textTertiary, count: completed.length),
          const SizedBox(height: 6),
          ...completed.map((r) => _ReminderTile(
            reminder: r,
            s: s,
            onToggle: () => ref.read(reminderListProvider.notifier).toggleComplete(r.id),
            onDismiss: () => ref.read(reminderListProvider.notifier).remove(r.id),
          )),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _SectionLabel({required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final dynamic s;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  const _ReminderTile({
    required this.reminder,
    required this.s,
    required this.onToggle,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = reminder.isOverdue;
    final isDone = reminder.isCompleted;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDone ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOverdue
                ? AppColors.expense.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDone
                        ? AppColors.income
                        : isOverdue
                            ? AppColors.expense
                            : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Icon
            Icon(
              reminder.icon,
              size: 18,
              color: isDone
                  ? AppColors.textTertiary
                  : isOverdue
                      ? AppColors.expense
                      : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppColors.textTertiary : null,
                    ),
                  ),
                  if (reminder.subtitle != null)
                    Text(
                      reminder.subtitle!,
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _dateFormat.format(reminder.dueDate),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isOverdue ? AppColors.expense : AppColors.textTertiary,
                  ),
                ),
                if (reminder.isDueSoon && !isDone)
                  Text(
                    '${reminder.dueDate.difference(DateTime.now()).inDays}d',
                    style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
