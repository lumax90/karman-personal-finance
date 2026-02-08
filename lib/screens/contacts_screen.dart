import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import 'contact_detail_screen.dart';
import '../providers/loading_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _filter = 'all'; // all, leads, clients
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(dataLoadingProvider);
    if (isLoading) return const ListShimmer();

    final s = ref.watch(stringsProvider);
    final contacts = ref.watch(contactListProvider);
    final leadsCount = ref.watch(totalLeadsCountProvider);
    final clientsCount = ref.watch(totalClientsCountProvider);

    List<Contact> filtered = contacts;
    if (_filter == 'leads') {
      filtered = contacts.where((c) => c.type == ContactType.lead).toList();
    } else if (_filter == 'clients') {
      filtered = contacts.where((c) => c.type == ContactType.client).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.company?.toLowerCase().contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false)).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: s.searchContacts,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: '${s.all} (${contacts.length})',
                isSelected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '${s.leads} ($leadsCount)',
                isSelected: _filter == 'leads',
                onTap: () => setState(() => _filter = 'leads'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '${s.clients} ($clientsCount)',
                isSelected: _filter == 'clients',
                onTap: () => setState(() => _filter = 'clients'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Contact list
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline,
                  title: s.noContacts,
                  subtitle: 'Müşteri ve potansiyel müşterilerinizi\nyönetmeye başlayın',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 68,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return _ContactTile(
                      contact: contact,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContactDetailScreen(contactId: contact.id),
                        ),
                      ),
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
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
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

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLead = contact.type == ContactType.lead;
    final statusColor = _statusColor(contact.status);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: isLead
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.income.withValues(alpha: 0.15),
        child: Text(
          contact.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isLead ? AppColors.warning : AppColors.income,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              contact.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              contact.status.label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
      subtitle: Text(
        contact.company ?? contact.email ?? '',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: contact.type == ContactType.client && contact.totalRevenue > 0
          ? Text(
              '₺${contact.totalRevenue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.income,
              ),
            )
          : Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
      dense: true,
    );
  }

  Color _statusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.newLead: return AppColors.primary;
      case ContactStatus.contacted: return AppColors.warning;
      case ContactStatus.qualified: return const Color(0xFFF97316);
      case ContactStatus.proposal: return AppColors.business;
      case ContactStatus.negotiation: return AppColors.business;
      case ContactStatus.won: return AppColors.income;
      case ContactStatus.lost: return AppColors.expense;
      case ContactStatus.churned: return AppColors.textTertiary;
    }
  }
}
