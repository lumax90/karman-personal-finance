import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  RecurrenceType _recurrence = RecurrenceType.once;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _availableCategories {
    final mode = ref.read(accountModeProvider);
    final allCats = TransactionCategory.values;
    if (mode == AccountMode.personal) {
      return allCats.where((c) => c.isPersonalCategory).toList();
    }
    return allCats.where((c) => c.isBusinessCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(accountModeProvider);
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
            // Header
            Row(
              children: [
                Text(
                  s.newTransaction,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: mode == AccountMode.personal
                        ? AppColors.personalMuted
                        : AppColors.businessMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mode == AccountMode.personal ? s.personal : s.business,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mode == AccountMode.personal
                          ? AppColors.personal
                          : AppColors.business,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Type toggle
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: s.expense,
                    icon: Icons.arrow_upward,
                    isSelected: _type == TransactionType.expense,
                    color: AppColors.expense,
                    onTap: () => setState(() => _type = TransactionType.expense),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeButton(
                    label: s.income,
                    icon: Icons.arrow_downward,
                    isSelected: _type == TransactionType.income,
                    color: AppColors.income,
                    onTap: () => setState(() => _type = TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: s.title,
                hintText: s.titleHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '${s.amount} (\u20ba)',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<TransactionCategory>(
              initialValue: _availableCategories.contains(_category) ? _category : _availableCategories.first,
              decoration: InputDecoration(labelText: s.category),
              items: _availableCategories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.iconData, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(s.categoryName(c.name), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
              isDense: true,
            ),
            const SizedBox(height: 12),

            // Recurrence
            DropdownButtonFormField<RecurrenceType>(
              initialValue: _recurrence,
              decoration: InputDecoration(labelText: s.recurrence),
              items: [
                DropdownMenuItem(value: RecurrenceType.once, child: Text(s.once, style: const TextStyle(fontSize: 13))),
                DropdownMenuItem(value: RecurrenceType.daily, child: Text(s.daily, style: const TextStyle(fontSize: 13))),
                DropdownMenuItem(value: RecurrenceType.weekly, child: Text(s.weekly, style: const TextStyle(fontSize: 13))),
                DropdownMenuItem(value: RecurrenceType.monthly, child: Text(s.monthlyRecurrence, style: const TextStyle(fontSize: 13))),
                DropdownMenuItem(value: RecurrenceType.yearly, child: Text(s.yearly, style: const TextStyle(fontSize: 13))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _recurrence = v);
              },
              isDense: true,
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(6),
              child: InputDecorator(
                decoration: InputDecoration(labelText: s.date),
                child: Text(
                  DateFormat('d MMMM yyyy', 'tr').format(_date),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: s.noteOptional,
                hintText: s.noteHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Submit
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
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (title.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    final mode = ref.read(accountModeProvider);

    try {
      await ref.read(transactionListProvider.notifier).add(
        Transaction(
          id: '',
          title: title,
          amount: amount,
          type: _type,
          category: _category,
          recurrence: _recurrence,
          date: _date,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          accountMode: mode,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt eklenemedi'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
