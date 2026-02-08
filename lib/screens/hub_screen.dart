import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../providers/reminder_provider.dart';
import 'ai_chat_screen.dart';
import 'goals_screen.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'insights_screen.dart';

class HubScreen extends ConsumerStatefulWidget {
  final bool showInsightsTab;
  const HubScreen({super.key, this.showInsightsTab = true});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.showInsightsTab ? 5 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final urgentCount = ref.watch(urgentReminderCountProvider);

    final tabs = <Widget>[
      if (widget.showInsightsTab)
        Tab(text: s.navInsights),
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14),
            const SizedBox(width: 4),
            Text(s.aiChat),
          ],
        ),
      ),
      Tab(text: s.goals),
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.reminders),
            if (urgentCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.expense,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$urgentCount',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      Tab(text: s.reports),
    ];

    final tabViews = <Widget>[
      if (widget.showInsightsTab)
        const InsightsScreen(),
      const AiChatScreen(),
      const GoalsScreen(),
      const RemindersScreen(),
      const ReportsScreen(),
    ];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: tabs,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabViews,
          ),
        ),
      ],
    );
  }
}
