import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';

final _cf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final mode = ref.watch(accountModeProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final netBalance = ref.watch(netBalanceProvider);
    final monthlySubs = ref.watch(totalMonthlySubscriptionCostProvider);
    final isPersonal = mode == AccountMode.personal;

    // Category breakdown
    final expenseByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};
    for (final t in transactions) {
      final label = s.categoryName(t.category.name);
      if (t.type == TransactionType.expense) {
        expenseByCategory[label] = (expenseByCategory[label] ?? 0) + t.amount;
      } else {
        incomeByCategory[label] = (incomeByCategory[label] ?? 0) + t.amount;
      }
    }

    final sortedExpenses = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIncomes = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomScrollView(
      slivers: [
        // Report header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${s.monthlyReport} — ${s.currentMonth}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPersonal ? s.personal : s.business,
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Summary cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(child: _SumCard(label: s.income, value: _cf.format(totalIncome), color: AppColors.income)),
                const SizedBox(width: 8),
                Expanded(child: _SumCard(label: s.expense, value: _cf.format(totalExpense), color: AppColors.expense)),
                const SizedBox(width: 8),
                Expanded(child: _SumCard(
                  label: isPersonal ? s.goalSavings : s.goalProfit,
                  value: _cf.format(netBalance),
                  color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                )),
              ],
            ),
          ),
        ),

        // Key ratios
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.keyMetrics, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _RatioRow(
                    label: isPersonal ? s.savingsRate : s.profitMargin,
                    value: totalIncome > 0 ? '${((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1)}%' : '0%',
                    color: netBalance > 0 ? AppColors.income : AppColors.expense,
                  ),
                  _RatioRow(
                    label: s.subscriptionExpenseMonthly,
                    value: _cf.format(monthlySubs),
                    color: AppColors.warning,
                  ),
                  _RatioRow(
                    label: s.recurringExpense,
                    value: _cf.format(transactions.where((t) => t.isRecurring && t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount)),
                    color: AppColors.expense,
                  ),
                  _RatioRow(
                    label: s.transactionCount(transactions.length),
                    value: '${transactions.length}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Income breakdown
        if (sortedIncomes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _CategoryBreakdown(
                title: s.incomeReport,
                entries: sortedIncomes,
                total: totalIncome,
                color: AppColors.income,
              ),
            ),
          ),

        // Expense breakdown
        if (sortedExpenses.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _CategoryBreakdown(
                title: s.expenseReport,
                entries: sortedExpenses,
                total: totalExpense,
                color: AppColors.expense,
              ),
            ),
          ),

        // Export buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(child: _ExportBtn(
                  label: s.exportPdf,
                  icon: Icons.picture_as_pdf_outlined,
                  color: AppColors.expense,
                  onTap: () => _showExportSnackbar(context, 'PDF'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ExportBtn(
                  label: s.exportExcel,
                  icon: Icons.table_chart_outlined,
                  color: AppColors.income,
                  onTap: () => _showExportSnackbar(context, 'Excel'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ExportBtn(
                  label: s.shareReport,
                  icon: Icons.share_outlined,
                  color: AppColors.primary,
                  onTap: () => _showExportSnackbar(context, 'Share'),
                )),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showExportSnackbar(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type export — coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SumCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RatioRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final String title;
  final List<MapEntry<String, double>> entries;
  final double total;
  final Color color;

  const _CategoryBreakdown({
    required this.title,
    required this.entries,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_cf.format(total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ...entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      Text(_cf.format(e.value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ExportBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
