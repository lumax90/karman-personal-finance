import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../core/l10n/strings.dart';
import '../models/account_mode.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(accountModeProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final netBalance = ref.watch(netBalanceProvider);
    final recurringExpenses = ref.watch(recurringExpensesProvider);
    final recurringIncome = ref.watch(recurringIncomeProvider);
    final monthlySubs = ref.watch(totalMonthlySubscriptionCostProvider);
    final isPersonal = mode == AccountMode.personal;
    final s = ref.watch(stringsProvider);

    final totalRecurringExpense = recurringExpenses.fold(0.0, (s, t) => s + t.amount);
    final totalRecurringIncome = recurringIncome.fold(0.0, (s, t) => s + t.amount);

    return CustomScrollView(
      slivers: [
        // Financial Health Score
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _HealthScoreCard(
              income: totalIncome,
              expense: totalExpense,
              isPersonal: isPersonal,
              s: s,
            ),
          ),
        ),

        // Income vs Expense Bar Chart
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _IncomeExpenseBar(
              income: totalIncome,
              expense: totalExpense,
              s: s,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Key Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.keyMetrics,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: isPersonal ? s.savingsRate : s.profitMargin,
                  value: totalIncome > 0
                      ? '%${((totalIncome - totalExpense) / totalIncome * 100).clamp(0, 100).toStringAsFixed(1)}'
                      : '%0',
                  color: netBalance > 0 ? AppColors.income : AppColors.expense,
                ),
                _MetricRow(
                  label: s.recurringIncome,
                  value: _currencyFormat.format(totalRecurringIncome),
                  color: AppColors.income,
                ),
                _MetricRow(
                  label: s.recurringExpense,
                  value: _currencyFormat.format(totalRecurringExpense),
                  color: AppColors.expense,
                ),
                _MetricRow(
                  label: s.subscriptionExpenseMonthly,
                  value: _currencyFormat.format(monthlySubs),
                  color: AppColors.warning,
                ),
                _MetricRow(
                  label: s.netCashFlow,
                  value: _currencyFormat.format(netBalance),
                  color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                  isBold: true,
                ),
                if (isPersonal) ...[
                  const SizedBox(height: 4),
                  _MetricRow(
                    label: s.mandatoryExpenseRatio,
                    value: totalExpense > 0
                        ? '%${(totalRecurringExpense / totalExpense * 100).toStringAsFixed(0)}'
                        : '%0',
                    color: AppColors.zinc600,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Tips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TipsCard(
              isPersonal: isPersonal,
              savingsRate: totalIncome > 0
                  ? (totalIncome - totalExpense) / totalIncome * 100
                  : 0,
              monthlySubs: monthlySubs,
              s: s,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final double income;
  final double expense;
  final bool isPersonal;
  final S s;

  const _HealthScoreCard({
    required this.income,
    required this.expense,
    required this.isPersonal,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = income > 0 ? (income - expense) / income : 0.0;
    final score = (ratio * 100).clamp(0, 100).toInt();

    Color scoreColor;
    String scoreLabel;
    if (score >= 30) {
      scoreColor = AppColors.income;
      scoreLabel = s.excellent;
    } else if (score >= 15) {
      scoreColor = AppColors.warning;
      scoreLabel = s.good;
    } else if (score > 0) {
      scoreColor = const Color(0xFFF97316);
      scoreLabel = s.caution;
    } else {
      scoreColor = AppColors.expense;
      scoreLabel = s.critical;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Score circle
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPersonal ? s.financialHealth : s.businessHealth,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPersonal
                      ? s.savingsMessage(score)
                      : s.profitMessage(score),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseBar extends StatelessWidget {
  final double income;
  final double expense;
  final S s;

  const _IncomeExpenseBar({
    required this.income,
    required this.expense,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final incomeRatio = total > 0 ? income / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.incomeVsExpense,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  Flexible(
                    flex: (incomeRatio * 100).round(),
                    child: Container(color: AppColors.income),
                  ),
                  Flexible(
                    flex: ((1 - incomeRatio) * 100).round(),
                    child: Container(color: AppColors.expense),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BarLegend(
                color: AppColors.income,
                label: s.income,
                value: _currencyFormat.format(income),
              ),
              const Spacer(),
              _BarLegend(
                color: AppColors.expense,
                label: s.expense,
                value: _currencyFormat.format(expense),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _BarLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final bool isPersonal;
  final double savingsRate;
  final double monthlySubs;
  final S s;

  const _TipsCard({
    required this.isPersonal,
    required this.savingsRate,
    required this.monthlySubs,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final tips = <String>[];

    if (isPersonal) {
      if (savingsRate < 20) {
        tips.add(s.tipSavingsLow);
      }
      if (monthlySubs > 500) {
        tips.add(s.tipSubsHigh(_currencyFormat.format(monthlySubs)));
      }
      tips.add(s.tipEmergencyFund);
    } else {
      if (savingsRate < 15) {
        tips.add(s.tipProfitLow);
      }
      tips.add(s.tipRecurringRevenue);
      if (monthlySubs > 2000) {
        tips.add(s.tipOptimizeSoftware);
      }
    }

    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                s.suggestions,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
