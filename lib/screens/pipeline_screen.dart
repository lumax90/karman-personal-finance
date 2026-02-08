import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/deal.dart';
import '../providers/deal_provider.dart';
import '../providers/loading_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';

final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(dataLoadingProvider);
    if (isLoading) return const ListShimmer();

    final s = ref.watch(stringsProvider);
    final allDeals = ref.watch(dealListProvider);
    if (allDeals.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list,
        title: 'Henüz deal yok',
        subtitle: 'Satış sürecinizi yönetmek için\nilk deal\'inizi ekleyin',
      );
    }

    final pipelineValue = ref.watch(totalPipelineValueProvider);
    final weightedValue = ref.watch(weightedPipelineValueProvider);
    final wonValue = ref.watch(totalWonValueProvider);
    final winRate = ref.watch(winRateProvider);

    final openStages = [
      DealStage.discovery,
      DealStage.qualification,
      DealStage.proposal,
      DealStage.negotiation,
    ];

    return CustomScrollView(
      slivers: [
        // Pipeline summary
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
                  Text(
                    s.pipelineOverview,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatItem(
                        label: s.pipelineValue,
                        value: _currencyFormat.format(pipelineValue),
                        color: AppColors.primary,
                      )),
                      Expanded(child: _StatItem(
                        label: s.weightedValue,
                        value: _currencyFormat.format(weightedValue),
                        color: AppColors.warning,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatItem(
                        label: s.wonRevenue,
                        value: _currencyFormat.format(wonValue),
                        color: AppColors.income,
                      )),
                      Expanded(child: _StatItem(
                        label: s.winRate,
                        value: '${winRate.toStringAsFixed(0)}%',
                        color: winRate >= 50 ? AppColors.income : AppColors.expense,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Pipeline stages
        ...openStages.expand((stage) {
          final deals = ref.watch(dealsByStageProvider(stage));
          if (deals.isEmpty) return <Widget>[];
          return [
            SliverToBoxAdapter(
              child: _StageHeader(
                stage: stage,
                dealCount: deals.length,
                totalValue: deals.fold(0.0, (sum, d) => sum + d.amount),
                s: s,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DealCard(
                  deal: deals[index],
                  s: s,
                  onAdvance: () {
                    final nextStage = _nextStage(deals[index].stage);
                    if (nextStage != null) {
                      ref.read(dealListProvider.notifier)
                          .updateStage(deals[index].id, nextStage);
                    }
                  },
                  onWin: () {
                    ref.read(dealListProvider.notifier)
                        .updateStage(deals[index].id, DealStage.closedWon);
                  },
                  onLose: () {
                    ref.read(dealListProvider.notifier)
                        .updateStage(deals[index].id, DealStage.closedLost);
                  },
                ),
                childCount: deals.length,
              ),
            ),
          ];
        }),

        // Closed deals
        SliverToBoxAdapter(
          child: _ClosedDealsSection(ref: ref, s: s),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  DealStage? _nextStage(DealStage current) {
    switch (current) {
      case DealStage.discovery: return DealStage.qualification;
      case DealStage.qualification: return DealStage.proposal;
      case DealStage.proposal: return DealStage.negotiation;
      case DealStage.negotiation: return null;
      default: return null;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _StageHeader extends StatelessWidget {
  final DealStage stage;
  final int dealCount;
  final double totalValue;
  final dynamic s;

  const _StageHeader({
    required this.stage,
    required this.dealCount,
    required this.totalValue,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _stageColor(stage),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stage.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$dealCount',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          const Spacer(),
          Text(
            _currencyFormat.format(totalValue),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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

class _DealCard extends StatelessWidget {
  final Deal deal;
  final dynamic s;
  final VoidCallback onAdvance;
  final VoidCallback onWin;
  final VoidCallback onLose;

  const _DealCard({
    required this.deal,
    required this.s,
    required this.onAdvance,
    required this.onWin,
    required this.onLose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
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
                    Text(deal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      deal.contactName,
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(deal.amount),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${deal.stage.probability}%',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          if (deal.expectedCloseDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${s.expectedClose}: ${DateFormat('d MMM').format(deal.expectedCloseDate!)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (deal.stage != DealStage.negotiation)
                _SmallBtn(
                  label: s.advance,
                  icon: Icons.arrow_forward,
                  color: AppColors.primary,
                  onTap: onAdvance,
                ),
              if (deal.stage == DealStage.negotiation) ...[
                _SmallBtn(
                  label: s.closeWon,
                  icon: Icons.check,
                  color: AppColors.income,
                  onTap: onWin,
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              _SmallBtn(
                label: s.closeLost,
                icon: Icons.close,
                color: AppColors.expense,
                onTap: onLose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ClosedDealsSection extends StatelessWidget {
  final WidgetRef ref;
  final dynamic s;

  const _ClosedDealsSection({required this.ref, required this.s});

  @override
  Widget build(BuildContext context) {
    final won = ref.watch(wonDealsProvider);
    final lost = ref.watch(lostDealsProvider);

    if (won.isEmpty && lost.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
            Text(
              s.closedDeals,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...won.map((d) => _ClosedDealRow(deal: d, isWon: true)),
            ...lost.map((d) => _ClosedDealRow(deal: d, isWon: false)),
          ],
        ),
      ),
    );
  }
}

class _ClosedDealRow extends StatelessWidget {
  final Deal deal;
  final bool isWon;

  const _ClosedDealRow({required this.deal, required this.isWon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isWon ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isWon ? AppColors.income : AppColors.expense,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${deal.title} — ${deal.contactName}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _currencyFormat.format(deal.amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWon ? AppColors.income : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
