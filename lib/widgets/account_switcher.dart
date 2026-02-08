import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../providers/account_provider.dart';

class AccountSwitcher extends ConsumerWidget {
  const AccountSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(accountModeProvider);
    final isPersonal = mode == AccountMode.personal;
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: () => _showAccountSwitchSheet(context, ref, mode, s),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 50) {
          ref.read(accountModeProvider.notifier).toggle();
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPersonal
                ? [AppColors.personal, AppColors.personal.withValues(alpha: 0.7)]
                : [AppColors.business, AppColors.business.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPersonal ? AppColors.personal : AppColors.business)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isPersonal ? 'P' : 'B',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSwitchSheet(
    BuildContext context,
    WidgetRef ref,
    AccountMode currentMode,
    dynamic s,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _AccountOption(
                label: s.personal,
                subtitle: s.personalFinance,
                icon: Icons.person_outline,
                color: AppColors.personal,
                isSelected: currentMode == AccountMode.personal,
                onTap: () {
                  ref.read(accountModeProvider.notifier).setMode(AccountMode.personal);
                  Navigator.pop(context);
                },
              ),
              const Divider(indent: 56, endIndent: 16),
              _AccountOption(
                label: s.business,
                subtitle: s.businessFinance,
                icon: Icons.business_outlined,
                color: AppColors.business,
                isSelected: currentMode == AccountMode.business,
                onTap: () {
                  ref.read(accountModeProvider.notifier).setMode(AccountMode.business);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? color : color.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : color,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color, size: 20)
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
