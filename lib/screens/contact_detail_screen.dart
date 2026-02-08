import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/contact.dart';
import '../models/activity.dart';
import '../models/deal.dart';
import '../models/invoice.dart';
import '../providers/contact_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/deal_provider.dart';
import '../providers/invoice_provider.dart';

final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
final _dateFormat = DateFormat('d MMM yyyy');

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final contact = ref.watch(contactByIdProvider(contactId));
    final activities = ref.watch(activitiesByContactProvider(contactId));
    final deals = ref.watch(dealsByContactProvider(contactId));
    final invoices = ref.watch(invoicesByContactProvider(contactId));

    if (contact == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Contact not found')),
      );
    }

    final isLead = contact.type == ContactType.lead;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          if (isLead)
            TextButton.icon(
              onPressed: () {
                ref.read(contactListProvider.notifier).convertToClient(contactId);
              },
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: Text(s.convertToClient, style: const TextStyle(fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact info card
          _InfoCard(contact: contact, s: s),
          const SizedBox(height: 16),

          // Tags
          if (contact.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: contact.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Deals section
          if (deals.isNotEmpty) ...[
            _SectionHeader(title: s.deals, count: deals.length),
            const SizedBox(height: 8),
            ...deals.map((deal) => _DealTile(deal: deal, s: s)),
            const SizedBox(height: 16),
          ],

          // Invoices section
          if (invoices.isNotEmpty) ...[
            _SectionHeader(title: s.invoices, count: invoices.length),
            const SizedBox(height: 8),
            ...invoices.map((inv) => _InvoiceTile(invoice: inv)),
            const SizedBox(height: 16),
          ],

          // Activity timeline
          _SectionHeader(title: s.activityHistory, count: activities.length),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  s.noActivities,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
              ),
            )
          else
            ...activities.map((a) => _ActivityTile(activity: a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Contact contact;
  final dynamic s;
  const _InfoCard({required this.contact, required this.s});

  @override
  Widget build(BuildContext context) {
    final isLead = contact.type == ContactType.lead;
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isLead
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.income.withValues(alpha: 0.15),
                child: Text(
                  contact.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isLead ? AppColors.warning : AppColors.income,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (contact.company != null)
                      Text(
                        contact.company!,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLead
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLead ? s.lead : s.client,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLead ? AppColors.warning : AppColors.income,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contact.email != null)
            _InfoRow(icon: Icons.email_outlined, text: contact.email!),
          if (contact.phone != null)
            _InfoRow(icon: Icons.phone_outlined, text: contact.phone!),
          _InfoRow(
            icon: Icons.label_outlined,
            text: '${s.status}: ${contact.status.label}',
          ),
          _InfoRow(
            icon: Icons.source_outlined,
            text: '${s.source}: ${contact.source.name}',
          ),
          if (contact.totalRevenue > 0)
            _InfoRow(
              icon: Icons.payments_outlined,
              text: '${s.totalRevenue}: ${_currencyFormat.format(contact.totalRevenue)}',
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: '${s.createdAt}: ${_dateFormat.format(contact.createdAt)}',
          ),
          if (contact.lastContactedAt != null)
            _InfoRow(
              icon: Icons.access_time,
              text: '${s.lastContacted}: ${_dateFormat.format(contact.lastContactedAt!)}',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DealTile extends StatelessWidget {
  final Deal deal;
  final dynamic s;
  const _DealTile({required this.deal, required this.s});

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(deal.stage);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        deal.stage.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stageColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${deal.stage.probability}% ${s.probability}',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(deal.amount),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _stageColor(DealStage stage) {
    switch (stage) {
      case DealStage.discovery: return AppColors.primary;
      case DealStage.qualification: return AppColors.warning;
      case DealStage.proposal: return const Color(0xFFF97316);
      case DealStage.negotiation: return AppColors.business;
      case DealStage.closedWon: return AppColors.income;
      case DealStage.closedLost: return AppColors.expense;
    }
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final statusColor = _invoiceStatusColor(invoice.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        invoice.status.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormat.format(invoice.dueDate),
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(invoice.totalAmount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: invoice.status == InvoiceStatus.paid ? AppColors.income : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _invoiceStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft: return AppColors.textTertiary;
      case InvoiceStatus.sent: return AppColors.primary;
      case InvoiceStatus.paid: return AppColors.income;
      case InvoiceStatus.overdue: return AppColors.expense;
      case InvoiceStatus.cancelled: return AppColors.textTertiary;
    }
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity.isCompleted
                  ? AppColors.income.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              activity.type.iconData,
              size: 16,
              color: activity.isCompleted ? AppColors.income : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: activity.isCompleted ? TextDecoration.lineThrough : null,
                    color: activity.isCompleted ? AppColors.textTertiary : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.type.label} · ${_dateFormat.format(activity.date)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
