import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/app_locale.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/subscription_tier.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/revenuecat_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final tier = ref.watch(subscriptionTierProvider);
    final selectedModel = ref.watch(selectedAiModelProvider);
    final apiKeys = ref.watch(apiKeyProvider);
    final availableModels = ref.watch(availableModelsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile
                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            (user.name ?? user.email)[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name ?? user.email,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: user.isPremium
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.isPremium ? 'PRO' : 'FREE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: user.isPremium ? AppColors.warning : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // General section
                _SectionLabel(label: s.general),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.translate_outlined,
                        label: s.language,
                        trailing: _LanguageSelector(
                          currentLang: currentLang,
                          onChanged: (lang) {
                            ref.read(appLanguageProvider.notifier).setLanguage(lang);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Plan section
                _SectionLabel(label: s.currentPlan),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tier == SubscriptionTier.premium
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tier == SubscriptionTier.premium
                              ? Icons.workspace_premium
                              : Icons.person_outline,
                          size: 18,
                          color: tier == SubscriptionTier.premium
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier == SubscriptionTier.premium ? s.premium : s.free,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              tier == SubscriptionTier.premium
                                  ? 'Gemini + GPT-4o + Grok'
                                  : s.freeWithOwnKey,
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      if (tier != SubscriptionTier.premium)
                        InkWell(
                          onTap: () async {
                            final purchased = await showPaywall(ref);
                            if (purchased && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.premium)),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Upgrade',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // AI Settings
                _SectionLabel(label: s.aiSettings),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Model selection
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.modelSelection,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            ...AiModel.values.map((model) {
                              final isAvailable = availableModels.contains(model);
                              final isSelected = model == selectedModel;
                              final hasKey = apiKeys.containsKey(model);
                              return _ModelOption(
                                model: model,
                                isSelected: isSelected,
                                isAvailable: isAvailable,
                                hasKey: hasKey,
                                s: s,
                                onTap: isAvailable
                                    ? () => ref.read(selectedAiModelProvider.notifier).state = model
                                    : null,
                              );
                            }),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: AppColors.border),

                      // API key for selected model
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: _ApiKeyField(
                          model: selectedModel,
                          currentKey: apiKeys[selectedModel] ?? '',
                          s: s,
                          onSave: (key) {
                            ref.read(apiKeyProvider.notifier).setKey(selectedModel, key);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.apiKeySaved),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref, s),
                    icon: Icon(Icons.logout, size: 16, color: AppColors.expense),
                    label: Text(
                      s.logout,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.expense),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.expense.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // About
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Karman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(s.logoutConfirm, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(s.logout, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  final AiModel model;
  final bool isSelected;
  final bool isAvailable;
  final bool hasKey;
  final dynamic s;
  final VoidCallback? onTap;

  const _ModelOption({
    required this.model,
    required this.isSelected,
    required this.isAvailable,
    required this.hasKey,
    required this.s,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        model.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? null : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        model.provider,
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  Text(
                    model.isFreeAvailable ? s.freeWithOwnKey : s.premiumOnly,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (!isAvailable)
              Icon(Icons.lock, size: 14, color: AppColors.textTertiary),
            if (isAvailable && hasKey)
              Icon(Icons.check_circle, size: 14, color: AppColors.income),
            if (isAvailable && !hasKey)
              Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  final AiModel model;
  final String currentKey;
  final dynamic s;
  final ValueChanged<String> onSave;

  const _ApiKeyField({
    required this.model,
    required this.currentKey,
    required this.s,
    required this.onSave,
  });

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  late TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentKey);
  }

  @override
  void didUpdateWidget(covariant _ApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model || oldWidget.currentKey != widget.currentKey) {
      _controller.text = widget.currentKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.model.label} ${widget.s.apiKey}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: widget.s.apiKeyHint,
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxWidth: 32),
                  ),
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => widget.onSave(_controller.text.trim()),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.s.save,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppLanguage currentLang;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageSelector({
    required this.currentLang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'TR',
            isSelected: currentLang == AppLanguage.tr,
            onTap: () => onChanged(AppLanguage.tr),
          ),
          _LangChip(
            label: 'EN',
            isSelected: currentLang == AppLanguage.en,
            onTap: () => onChanged(AppLanguage.en),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
