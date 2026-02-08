import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../providers/loading_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filterType;
  bool _showRecurringOnly = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(dataLoadingProvider);
    if (isLoading) return const ListShimmer();

    final s = ref.watch(stringsProvider);
    var transactions = ref.watch(filteredTransactionsProvider);

    if (_filterType != null) {
      transactions = transactions.where((t) => t.type == _filterType).toList();
    }
    if (_showRecurringOnly) {
      transactions = transactions.where((t) => t.isRecurring).toList();
    }

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: s.all,
                  isSelected: _filterType == null && !_showRecurringOnly,
                  onTap: () => setState(() {
                    _filterType = null;
                    _showRecurringOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.income,
                  isSelected: _filterType == TransactionType.income,
                  color: AppColors.income,
                  onTap: () => setState(() {
                    _filterType = TransactionType.income;
                    _showRecurringOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.expense,
                  isSelected: _filterType == TransactionType.expense,
                  color: AppColors.expense,
                  onTap: () => setState(() {
                    _filterType = TransactionType.expense;
                    _showRecurringOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.recurring,
                  isSelected: _showRecurringOnly,
                  color: AppColors.primary,
                  onTap: () => setState(() {
                    _showRecurringOnly = !_showRecurringOnly;
                    _filterType = null;
                  }),
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: transactions.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: s.noTransactions,
                  subtitle: 'Gelir ve giderlerinizi takip etmek için\nilk işleminizi ekleyin',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 64,
                  ),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return Dismissible(
                      key: Key(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(transactionListProvider.notifier).remove(t.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.deleted(t.title)),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: TransactionTile(transaction: t),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? effectiveColor.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? effectiveColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
