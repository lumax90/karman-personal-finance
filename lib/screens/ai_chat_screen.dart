import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/smart_insight.dart';
import '../models/subscription_tier.dart';
import '../providers/ai_provider.dart';
import '../providers/smart_insights_provider.dart';
import '../services/ai_service.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _insightsExpanded = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final chatState = ref.watch(aiChatProvider);
    final selectedModel = ref.watch(selectedAiModelProvider);
    final canUse = ref.watch(canUseSelectedModelProvider);
    final availableModels = ref.watch(availableModelsProvider);
    final insights = ref.watch(smartInsightsProvider);

    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Column(
      children: [
        // Model selector bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              ...AiModel.values.map((model) {
                final isAvailable = availableModels.contains(model);
                final isSelected = model == selectedModel;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _ModelChip(
                    model: model,
                    isSelected: isSelected,
                    isLocked: !isAvailable,
                    onTap: isAvailable
                        ? () => ref.read(selectedAiModelProvider.notifier).state = model
                        : () => _showPremiumDialog(context, s),
                  ),
                );
              }),
              const Spacer(),
              if (chatState.messages.isNotEmpty)
                IconButton(
                  onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Clear chat',
                ),
            ],
          ),
        ),

        // Main content area
        Expanded(
          child: chatState.messages.isEmpty
              ? _buildEmptyStateWithInsights(s, selectedModel, insights, canUse)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatState.messages.length && chatState.isLoading) {
                      return _TypingIndicator(modelName: selectedModel.label);
                    }
                    return _ChatBubble(message: chatState.messages[index]);
                  },
                ),
        ),

        // Error banner
        if (chatState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.expenseMuted,
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: AppColors.expense),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chatState.error!,
                    style: TextStyle(fontSize: 12, color: AppColors.expense),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Input bar
        _buildInputBar(s, canUse, chatState.isLoading),
      ],
    );
  }

  Widget _buildEmptyStateWithInsights(
    dynamic s,
    AiModel selectedModel,
    List<SmartInsight> insights,
    bool canUse,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        // Smart Insights section
        if (insights.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _insightsExpanded = !_insightsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.business.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.aiInsights,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${insights.length} ${s.aiInsights.toString().toLowerCase()}',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _insightsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_insightsExpanded) ...[
            const SizedBox(height: 8),
            ...insights.take(5).map((insight) => _CompactInsightCard(insight: insight)),
            if (insights.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  '+${insights.length - 5} more',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          const SizedBox(height: 16),
        ],

        // AI welcome + quick prompts
        Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Karman AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.aiPoweredBy} ${selectedModel.label}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              if (!canUse) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    s.aiApiKeyRequired,
                    style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _PromptChip(label: s.aiPrompt1, onTap: canUse ? () => _sendPrompt(s.aiPrompt1) : null),
                  _PromptChip(label: s.aiPrompt2, onTap: canUse ? () => _sendPrompt(s.aiPrompt2) : null),
                  _PromptChip(label: s.aiPrompt3, onTap: canUse ? () => _sendPrompt(s.aiPrompt3) : null),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(dynamic s, bool canUse, bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: canUse && !isLoading,
                decoration: InputDecoration(
                  hintText: canUse ? s.aiChatHint : s.aiApiKeyRequired,
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: canUse ? (_) => _send() : null,
                textInputAction: TextInputAction.send,
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: canUse && !isLoading ? _send : null,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: canUse ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.send,
                  size: 18,
                  color: canUse ? Colors.white : AppColors.textTertiary,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
  }

  void _sendPrompt(String prompt) {
    ref.read(aiChatProvider.notifier).sendMessage(prompt);
  }

  void _showPremiumDialog(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Text(s.premiumRequired, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          s.premiumDesc,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }
}

// --- Compact insight card for the unified AI screen ---
class _CompactInsightCard extends StatelessWidget {
  final SmartInsight insight;
  const _CompactInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(insight.icon, size: 14, color: insight.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  insight.description,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _TypeDot(type: insight.type),
        ],
      ),
    );
  }
}

class _TypeDot extends StatelessWidget {
  final InsightType type;
  const _TypeDot({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      InsightType.alert => AppColors.expense,
      InsightType.warning => AppColors.warning,
      InsightType.achievement => AppColors.income,
      InsightType.tip => AppColors.primary,
      InsightType.trend => const Color(0xFFF97316),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// --- Shared widgets ---
class _ModelChip extends StatelessWidget {
  final AiModel model;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _ModelChip({
    required this.model,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : isLocked
                        ? AppColors.textTertiary
                        : AppColors.textSecondary,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 3),
              Icon(Icons.lock, size: 10, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PromptChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 12),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final String modelName;
  const _TypingIndicator({required this.modelName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$modelName...',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
