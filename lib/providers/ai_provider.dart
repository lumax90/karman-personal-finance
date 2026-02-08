import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_mode.dart';
import '../models/subscription_tier.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';
import 'subscription_provider.dart';
import 'goal_provider.dart';

// Subscription tier
final subscriptionTierProvider = StateProvider<SubscriptionTier>((ref) => SubscriptionTier.free);

// Selected AI model
final selectedAiModelProvider = StateProvider<AiModel>((ref) => AiModel.grok);

// API key providers (per model)
final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, Map<AiModel, String>>(
  (ref) => ApiKeyNotifier(),
);

class ApiKeyNotifier extends StateNotifier<Map<AiModel, String>> {
  ApiKeyNotifier() : super({}) {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = <AiModel, String>{};
    for (final model in AiModel.values) {
      final key = prefs.getString('api_key_${model.name}');
      if (key != null && key.isNotEmpty) {
        keys[model] = key;
      }
    }
    state = keys;
  }

  Future<void> setKey(AiModel model, String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await prefs.remove('api_key_${model.name}');
      state = {...state}..remove(model);
    } else {
      await prefs.setString('api_key_${model.name}', key);
      state = {...state, model: key};
    }
  }

  String? getKey(AiModel model) => state[model];
}

// Whether the selected model is accessible
final canUseSelectedModelProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  final model = ref.watch(selectedAiModelProvider);
  final keys = ref.watch(apiKeyProvider);

  if (tier == SubscriptionTier.premium) {
    return keys.containsKey(model);
  }
  // Free tier: only Grok with own API key
  return model == AiModel.grok && keys.containsKey(AiModel.grok);
});

// Available models based on tier
final availableModelsProvider = Provider<List<AiModel>>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  if (tier == SubscriptionTier.premium) {
    return AiModel.values.toList();
  }
  return [AiModel.grok]; // Free tier: only Grok
});

// AI Chat state
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(ref),
);

class AiChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;

  AiChatNotifier(this._ref) : super(const AiChatState());

  String _buildSystemPrompt() {
    final fmt = NumberFormat('#,##0.00', 'tr_TR');
    final mode = _ref.read(accountModeProvider);
    final isPersonal = mode == AccountMode.personal;
    final modeLabel = isPersonal ? 'Kişisel (Personal)' : 'İşletme (Business)';

    // Financial data
    final totalIncome = _ref.read(totalIncomeProvider);
    final totalExpense = _ref.read(totalExpenseProvider);
    final netBalance = _ref.read(netBalanceProvider);
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1)
        : '0';

    // Transactions breakdown by category
    final transactions = _ref.read(filteredTransactionsProvider);
    final expenseByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};
    for (final t in transactions) {
      final catName = t.category.name;
      if (t.type == TransactionType.expense) {
        expenseByCategory[catName] = (expenseByCategory[catName] ?? 0) + t.amount;
      } else {
        incomeByCategory[catName] = (incomeByCategory[catName] ?? 0) + t.amount;
      }
    }
    final topExpenses = (expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '  - ${e.key}: ₺${fmt.format(e.value)}')
        .join('\n');
    final topIncomes = (incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '  - ${e.key}: ₺${fmt.format(e.value)}')
        .join('\n');

    // Subscriptions
    final activeSubs = _ref.read(activeSubscriptionsProvider);
    final monthlySubCost = _ref.read(totalMonthlySubscriptionCostProvider);
    final subList = activeSubs
        .map((s) => '  - ${s.name}: ₺${fmt.format(s.monthlyAmount)}/ay')
        .join('\n');

    // Goals
    final goals = _ref.read(activeGoalsProvider);
    final goalList = goals
        .map((g) => '  - ${g.title}: ₺${fmt.format(g.currentAmount)} / ₺${fmt.format(g.targetAmount)} (%${g.progressPercent.toStringAsFixed(0)})')
        .join('\n');

    // Recurring expenses
    final recurringExp = _ref.read(recurringExpensesProvider);
    final totalRecurring = recurringExp.fold(0.0, (sum, t) => sum + t.amount);

    return '''You are Karman AI, a smart financial assistant embedded in a personal & business finance app.
You have DIRECT ACCESS to the user's real financial data shown below. Use this data to give specific, actionable answers.

## Current Mode: $modeLabel

## Financial Summary (This Month)
- Total Income: ₺${fmt.format(totalIncome)}
- Total Expenses: ₺${fmt.format(totalExpense)}
- Net Balance: ₺${fmt.format(netBalance)}
- Savings Rate: $savingsRate%
- Recurring Expenses: ₺${fmt.format(totalRecurring)}

## Top Income Sources:
$topIncomes

## Top Expense Categories:
$topExpenses

## Active Subscriptions (₺${fmt.format(monthlySubCost)}/month total):
$subList

## Financial Goals:
${goalList.isEmpty ? '  No active goals set.' : goalList}

## Rules:
- Use ₺ (Turkish Lira) for all amounts.
- Keep responses concise (3-5 sentences) unless user asks for detail.
- Reference ACTUAL numbers from the data above — never invent amounts.
- If asked about data you don't have, say so honestly.
- Respond in the same language the user writes in (Turkish or English).
- Be friendly but professional. Give actionable advice, not generic tips.''';
  }

  Future<void> sendMessage(String content) async {
    final model = _ref.read(selectedAiModelProvider);
    final keys = _ref.read(apiKeyProvider);
    final apiKey = keys[model];

    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(error: 'API key required for ${model.label}');
      return;
    }

    final userMsg = AiMessage(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await AiService.chat(
        model: model,
        apiKey: apiKey,
        messages: state.messages,
        systemPrompt: _buildSystemPrompt(),
      );

      final assistantMsg = AiMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } on AiServiceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = const AiChatState();
  }
}
