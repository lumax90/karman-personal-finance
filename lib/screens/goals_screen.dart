import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';

final _cf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final goals = ref.watch(activeGoalsProvider);

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(s.noGoals, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: goals.length,
      itemBuilder: (context, index) => _GoalCard(goal: goals[index], s: s),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  final dynamic s;
  const _GoalCard({required this.goal, required this.s});

  @override
  Widget build(BuildContext context) {
    final isExpenseGoal = goal.type == GoalType.expense;
    final progress = goal.progress;
    final pct = goal.progressPercent;

    Color progressColor;
    if (isExpenseGoal) {
      // For expense goals, over budget = bad
      progressColor = progress > 1.0
          ? AppColors.expense
          : progress > 0.8
              ? AppColors.warning
              : AppColors.income;
    } else {
      progressColor = goal.isCompleted
          ? AppColors.income
          : progress > 0.6
              ? AppColors.primary
              : AppColors.warning;
    }

    final typeLabel = _typeLabel(goal.type);
    final typeIcon = _typeIcon(goal.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: goal.isCompleted && !isExpenseGoal
              ? AppColors.income.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, size: 16, color: progressColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      typeLabel,
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted && !isExpenseGoal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppColors.income),
                      const SizedBox(width: 3),
                      Text(
                        s.goalCompleted,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.income),
                      ),
                    ],
                  ),
                ),
              if (isExpenseGoal && progress > 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.overdue,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.expense),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 10),

          // Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpenseGoal ? s.expense : s.goalProgress,
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                    Text(
                      _cf.format(goal.currentAmount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '%',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isExpenseGoal ? s.goalExpenseLimit : s.targetAmount,
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                    Text(
                      _cf.format(goal.targetAmount),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isExpenseGoal && goal.remaining > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${s.goalRemaining}: ${_cf.format(goal.remaining)}',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(GoalType type) {
    switch (type) {
      case GoalType.income: return s.income;
      case GoalType.expense: return s.goalExpenseLimit;
      case GoalType.savings: return s.goalSavings;
      case GoalType.revenue: return s.goalRevenue;
      case GoalType.profit: return s.goalProfit;
    }
  }

  IconData _typeIcon(GoalType type) {
    switch (type) {
      case GoalType.income: return Icons.trending_up;
      case GoalType.expense: return Icons.shield_outlined;
      case GoalType.savings: return Icons.savings_outlined;
      case GoalType.revenue: return Icons.attach_money;
      case GoalType.profit: return Icons.show_chart;
    }
  }
}
