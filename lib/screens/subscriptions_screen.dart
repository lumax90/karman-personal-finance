import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../core/l10n/strings.dart';
import '../models/subscription_model.dart';
import '../providers/account_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/loading_provider.dart';
import '../widgets/shimmer_loading.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(dataLoadingProvider);
    if (isLoading) return const ListShimmer();

    final subs = ref.watch(filteredSubscriptionsProvider);
    final activeSubs = subs.where((s) => s.isActive).toList();
    final inactiveSubs = subs.where((s) => !s.isActive).toList();
    final totalMonthly = ref.watch(totalMonthlySubscriptionCostProvider);
    final totalYearly = totalMonthly * 12;
    final s = ref.watch(stringsProvider);

    return CustomScrollView(
      slivers: [
        // Summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.monthlyTotal,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(totalMonthly),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.yearlyTotal,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(totalYearly),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(
                        label: s.active,
                        value: '${activeSubs.length}',
                        color: AppColors.income,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        label: s.inactive,
                        value: '${inactiveSubs.length}',
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        label: s.total,
                        value: '${subs.length}',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Active subscriptions header
        if (activeSubs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.activeSubscriptions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sub = activeSubs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: _SubscriptionCard(sub: sub, ref: ref, s: s),
                );
              },
              childCount: activeSubs.length,
            ),
          ),
        ],

        // Inactive subscriptions
        if (inactiveSubs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                s.inactiveSubscriptions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sub = inactiveSubs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  child: Opacity(
                    opacity: 0.5,
                    child: _SubscriptionCard(sub: sub, ref: ref, s: s),
                  ),
                );
              },
              childCount: inactiveSubs.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;
  final WidgetRef ref;
  final S s;

  const _SubscriptionCard({required this.sub, required this.ref, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                sub.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (sub.category != null) ...[
                      Text(
                        sub.category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        sub.cycleLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount & toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(sub.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub.cycle != BillingCycle.monthly)
                Text(
                  '${_currencyFormat.format(sub.monthlyAmount)}/ay',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 24,
            child: FittedBox(
              child: Switch(
                value: sub.isActive,
                onChanged: (_) {
                  ref.read(subscriptionListProvider.notifier).toggleActive(sub.id);
                },
                activeThumbColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Add subscription bottom sheet
class AddSubscriptionSheet extends ConsumerStatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  ConsumerState<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  BillingCycle _cycle = BillingCycle.monthly;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.newSubscription,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.subscriptionName,
                hintText: s.subscriptionNameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '${s.amount} (\u20ba)',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: s.categoryLabel,
                hintText: s.categoryHint,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BillingCycle>(
              initialValue: _cycle,
              decoration: InputDecoration(labelText: s.billingCycle),
              items: [
                DropdownMenuItem(
                  value: BillingCycle.weekly,
                  child: Text(s.weekly, style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: BillingCycle.monthly,
                  child: Text(s.monthlyRecurrence, style: const TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: BillingCycle.yearly,
                  child: Text(s.yearly, style: const TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _cycle = v);
              },
              isDense: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(s.save),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    if (name.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    final mode = ref.read(accountModeProvider);

    try {
      await ref.read(subscriptionListProvider.notifier).add(
        SubscriptionModel(
          id: '',
          name: name,
          amount: amount,
          cycle: _cycle,
          startDate: DateTime.now(),
          nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          accountMode: mode,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonelik eklenemedi'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
