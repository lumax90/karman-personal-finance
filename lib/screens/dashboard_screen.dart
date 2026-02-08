import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../core/l10n/strings.dart';
import '../models/account_mode.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/shimmer_loading.dart';
import '../providers/loading_provider.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(transactionListProvider.notifier).fetchAll(),
      ref.read(subscriptionListProvider.notifier).fetchAll(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(dataLoadingProvider);
    if (isLoading) return const DashboardShimmer();

    final mode = ref.watch(accountModeProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final netBalance = ref.watch(netBalanceProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final monthlySubs = ref.watch(totalMonthlySubscriptionCostProvider);
    final recurringExpenses = ref.watch(recurringExpensesProvider);
    final isPersonal = mode == AccountMode.personal;
    final s = ref.watch(stringsProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primary,
      child: CustomScrollView(
      slivers: [
        // Balance card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _BalanceCard(
              netBalance: netBalance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              isPersonal: isPersonal,
              s: s,
            ),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: s.income,
                    amount: totalIncome,
                    icon: Icons.arrow_downward,
                    color: AppColors.income,
                    bgColor: AppColors.incomeMuted,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: s.expense,
                    amount: totalExpense,
                    icon: Icons.arrow_upward,
                    color: AppColors.expense,
                    bgColor: AppColors.expenseMuted,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Subscriptions & Recurring row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: s.subscriptionsLabel,
                    amount: monthlySubs,
                    icon: Icons.autorenew,
                    color: AppColors.warning,
                    bgColor: AppColors.warningMuted,
                    subtitle: s.monthly,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: s.recurring,
                    amount: recurringExpenses.fold(0.0, (s, t) => s + t.amount),
                    icon: Icons.repeat,
                    color: AppColors.zinc600,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Expense breakdown chart
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ExpenseChart(
              transactions: transactions
                  .where((t) => t.type == TransactionType.expense)
                  .toList(),
              s: s,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Recent transactions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  s.recentTransactions,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
                ),
                const Spacer(),
                Text(
                  s.transactionCount(transactions.length),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 4)),

        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ...transactions.take(8).map((t) => TransactionTile(transaction: t)),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double netBalance;
  final double totalIncome;
  final double totalExpense;
  final bool isPersonal;
  final S s;

  const _BalanceCard({
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.isPersonal,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome * 100).clamp(0, 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPersonal
              ? [
                  const Color(0xFF1E1B4B),
                  const Color(0xFF312E81),
                ]
              : [
                  const Color(0xFF0C4A6E),
                  const Color(0xFF075985),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPersonal ? s.personalBalance : s.businessBalance,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.currentMonth,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(netBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          if (isPersonal) ...[
            Row(
              children: [
                Text(
                  s.savingsRate,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '%${savingsRate.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: savingsRate / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  savingsRate > 20
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFBBF24),
                ),
                minHeight: 4,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Text(
                  s.profitMargin,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '%${savingsRate.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: savingsRate / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  final List<Transaction> transactions;
  final S s;

  const _ExpenseChart({required this.transactions, required this.s});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    // Group by category
    final categoryTotals = <TransactionCategory, double>{};
    for (final t in transactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold(0.0, (s, e) => s + e.value);
    final colors = [
      AppColors.primary,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
      AppColors.zinc400,
    ];

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
            s.expenseBreakdown,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 1.5,
                      centerSpaceRadius: 30,
                      sections: sorted.take(6).toList().asMap().entries.map((e) {
                        final idx = e.key;
                        final entry = e.value;
                        return PieChartSectionData(
                          value: entry.value,
                          color: colors[idx % colors.length],
                          radius: 28,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sorted.take(5).toList().asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final pct = (entry.value / total * 100).toStringAsFixed(0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[idx % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.categoryName(entry.key.name),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '%$pct',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
