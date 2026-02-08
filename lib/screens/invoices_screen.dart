import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';

final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final invoices = ref.watch(invoiceListProvider);
    final totalReceivable = ref.watch(totalReceivableProvider);
    final totalPaid = ref.watch(totalPaidProvider);
    final totalOverdue = ref.watch(totalOverdueProvider);

    List<Invoice> filtered = invoices;
    if (_filter == 'paid') {
      filtered = invoices.where((i) => i.status == InvoiceStatus.paid).toList();
    } else if (_filter == 'unpaid') {
      filtered = invoices.where((i) =>
          i.status == InvoiceStatus.sent || i.status == InvoiceStatus.overdue).toList();
    } else if (_filter == 'draft') {
      filtered = invoices.where((i) => i.status == InvoiceStatus.draft).toList();
    }

    filtered.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return CustomScrollView(
      slivers: [
        // Summary cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(child: _SummaryCard(
                  label: s.receivable,
                  value: _currencyFormat.format(totalReceivable),
                  color: AppColors.warning,
                )),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(
                  label: s.collected,
                  value: _currencyFormat.format(totalPaid),
                  color: AppColors.income,
                )),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(
                  label: s.overdue,
                  value: _currencyFormat.format(totalOverdue),
                  color: AppColors.expense,
                )),
              ],
            ),
          ),
        ),

        // Filters
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: s.all,
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.unpaid,
                  isSelected: _filter == 'unpaid',
                  onTap: () => setState(() => _filter = 'unpaid'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.paidStatus,
                  isSelected: _filter == 'paid',
                  onTap: () => setState(() => _filter = 'paid'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: s.draftStatus,
                  isSelected: _filter == 'draft',
                  onTap: () => setState(() => _filter = 'draft'),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Invoice list
        filtered.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    s.noInvoices,
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final invoice = filtered[index];
                    return _InvoiceCard(
                      invoice: invoice,
                      s: s,
                      onMarkPaid: () {
                        ref.read(invoiceListProvider.notifier).markAsPaid(invoice.id);
                      },
                      onMarkSent: () {
                        ref.read(invoiceListProvider.notifier).markAsSent(invoice.id);
                      },
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

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
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final dynamic s;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkSent;

  const _InvoiceCard({
    required this.invoice,
    required this.s,
    required this.onMarkPaid,
    required this.onMarkSent,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(invoice.status);
    final isOverdue = invoice.isOverdue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOverdue ? AppColors.expense.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.contactName,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(invoice.totalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isOverdue ? s.overdue : invoice.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppColors.expense : statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items summary
          ...invoice.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.description} ${item.quantity > 1 ? "x${item.quantity}" : ""}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  _currencyFormat.format(item.total),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          )),
          Divider(color: AppColors.border, height: 16),
          Row(
            children: [
              Text(
                '${s.subtotal}: ${_currencyFormat.format(invoice.subtotal)}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              Text(
                '${s.tax} (${invoice.taxRate.toStringAsFixed(0)}%): ${_currencyFormat.format(invoice.taxAmount)}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const Spacer(),
              // Action buttons
              if (invoice.status == InvoiceStatus.draft)
                _ActionBtn(label: s.send, icon: Icons.send_outlined, onTap: onMarkSent),
              if (invoice.status == InvoiceStatus.sent || isOverdue)
                _ActionBtn(label: s.markPaid, icon: Icons.check_circle_outline, onTap: onMarkPaid),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft: return AppColors.textTertiary;
      case InvoiceStatus.sent: return AppColors.primary;
      case InvoiceStatus.paid: return AppColors.income;
      case InvoiceStatus.overdue: return AppColors.expense;
      case InvoiceStatus.cancelled: return AppColors.textTertiary;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
