import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../providers/account_provider.dart';
import 'add_transaction_sheet.dart';
import '../screens/subscriptions_screen.dart';

class QuickActionsFab extends ConsumerStatefulWidget {
  const QuickActionsFab({super.key});

  @override
  ConsumerState<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends ConsumerState<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final mode = ref.watch(accountModeProvider);
    final isBusiness = mode == AccountMode.business;

    final actions = <_QuickAction>[
      _QuickAction(
        label: s.addIncome,
        icon: Icons.trending_up,
        color: AppColors.income,
        onTap: () {
          _toggle();
          _showSheet(context, const AddTransactionSheet());
        },
      ),
      _QuickAction(
        label: s.addExpense,
        icon: Icons.trending_down,
        color: AppColors.expense,
        onTap: () {
          _toggle();
          _showSheet(context, const AddTransactionSheet());
        },
      ),
      if (isBusiness)
        _QuickAction(
          label: s.addContact,
          icon: Icons.person_add_outlined,
          color: AppColors.primary,
          onTap: () {
            _toggle();
          },
        ),
      if (!isBusiness)
        _QuickAction(
          label: s.navSubscriptions,
          icon: Icons.autorenew,
          color: AppColors.warning,
          onTap: () {
            _toggle();
            _showSheet(context, const AddSubscriptionSheet());
          },
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action items
        if (_isOpen) ...[
          ...actions.reversed.map((action) => FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_animation),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        action.label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: action.label,
                      onPressed: action.onTap,
                      backgroundColor: action.color,
                      elevation: 2,
                      child: Icon(action.icon, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: _isOpen ? AppColors.zinc700 : AppColors.primary,
          elevation: 4,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
