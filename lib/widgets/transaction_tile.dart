import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/strings.dart';
import '../models/transaction.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('d MMM', 'tr');

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final S? strings;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDismissed,
    this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.incomeMuted
                    : AppColors.expenseMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                transaction.category.iconData,
                size: 18,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            // Title & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        strings?.categoryName(transaction.category.name) ?? transaction.category.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (transaction.isRecurring) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _recurrenceLabel(transaction.recurrence),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount & date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${_currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(transaction.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(RecurrenceType type) {
    if (strings != null) {
      switch (type) {
        case RecurrenceType.once: return strings!.once;
        case RecurrenceType.daily: return strings!.daily;
        case RecurrenceType.weekly: return strings!.weekly;
        case RecurrenceType.monthly: return strings!.monthlyRecurrence;
        case RecurrenceType.yearly: return strings!.yearly;
      }
    }
    switch (type) {
      case RecurrenceType.once: return '';
      case RecurrenceType.daily: return 'Daily';
      case RecurrenceType.weekly: return 'Weekly';
      case RecurrenceType.monthly: return 'Monthly';
      case RecurrenceType.yearly: return 'Yearly';
    }
  }
}
