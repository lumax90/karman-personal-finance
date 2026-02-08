import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../providers/account_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/account_switcher.dart';
import '../widgets/add_transaction_sheet.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'subscriptions_screen.dart';
import 'settings_screen.dart';
import 'contacts_screen.dart';
import 'pipeline_screen.dart';
import 'hub_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final mode = ref.watch(accountModeProvider);
    final s = ref.watch(stringsProvider);
    final isPersonal = mode == AccountMode.personal;
    final isBusiness = !isPersonal;

    // Different titles for each mode
    final titles = isPersonal
        ? [s.navDashboard, s.navTransactions, s.navSubscriptions, 'Hub', s.settings]
        : [s.navDashboard, s.navContacts, s.navPipeline, 'Hub', s.settings];

    final urgentReminders = ref.watch(urgentReminderCountProvider);

    final safeTab = selectedTab.clamp(0, 4);
    final isSettingsTab = safeTab == 4;

    return Scaffold(
      appBar: AppBar(
        leading: isSettingsTab
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(child: AccountSwitcher()),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[safeTab],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (!isSettingsTab)
              Text(
                isPersonal ? s.personal : s.business,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isPersonal ? AppColors.personal : AppColors.business,
                ),
              ),
          ],
        ),
        actions: [
          if (!isSettingsTab)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => _showAddSheet(context, safeTab, isBusiness),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: isBusiness
            ? _buildBusinessScreen(safeTab)
            : _buildPersonalScreen(safeTab),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: safeTab,
          onTap: (i) => ref.read(selectedTabProvider.notifier).state = i,
          items: isPersonal
              ? [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined, size: 22),
                    activeIcon: const Icon(Icons.dashboard, size: 22),
                    label: s.navDashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.swap_horiz_outlined, size: 22),
                    activeIcon: const Icon(Icons.swap_horiz, size: 22),
                    label: s.navTransactions,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.autorenew_outlined, size: 22),
                    activeIcon: const Icon(Icons.autorenew, size: 22),
                    label: s.navSubscriptions,
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: urgentReminders > 0,
                      label: Text('$urgentReminders', style: const TextStyle(fontSize: 9)),
                      child: const Icon(Icons.hub_outlined, size: 22),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: urgentReminders > 0,
                      label: Text('$urgentReminders', style: const TextStyle(fontSize: 9)),
                      child: const Icon(Icons.hub, size: 22),
                    ),
                    label: 'Hub',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined, size: 22),
                    activeIcon: const Icon(Icons.settings, size: 22),
                    label: s.settings,
                  ),
                ]
              : [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined, size: 22),
                    activeIcon: const Icon(Icons.dashboard, size: 22),
                    label: s.navDashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people_outline, size: 22),
                    activeIcon: const Icon(Icons.people, size: 22),
                    label: s.navContacts,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.filter_list_outlined, size: 22),
                    activeIcon: const Icon(Icons.filter_list, size: 22),
                    label: s.navPipeline,
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: urgentReminders > 0,
                      label: Text('$urgentReminders', style: const TextStyle(fontSize: 9)),
                      child: const Icon(Icons.hub_outlined, size: 22),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: urgentReminders > 0,
                      label: Text('$urgentReminders', style: const TextStyle(fontSize: 9)),
                      child: const Icon(Icons.hub, size: 22),
                    ),
                    label: 'Hub',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined, size: 22),
                    activeIcon: const Icon(Icons.settings, size: 22),
                    label: s.settings,
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildPersonalScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen(key: ValueKey('dashboard'));
      case 1:
        return const TransactionsScreen(key: ValueKey('transactions'));
      case 2:
        return const SubscriptionsScreen(key: ValueKey('subscriptions'));
      case 3:
        return const HubScreen(showInsightsTab: true, key: ValueKey('hub'));
      case 4:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildBusinessScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen(key: ValueKey('biz-dashboard'));
      case 1:
        return const ContactsScreen(key: ValueKey('contacts'));
      case 2:
        return const PipelineScreen(key: ValueKey('pipeline'));
      case 3:
        return const HubScreen(showInsightsTab: false, key: ValueKey('biz-hub'));
      case 4:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const DashboardScreen();
    }
  }

  void _showAddSheet(BuildContext context, int currentTab, bool isBusiness) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (context) {
        if (!isBusiness && currentTab == 2) {
          return const AddSubscriptionSheet();
        }
        return const AddTransactionSheet();
      },
    );
  }
}
