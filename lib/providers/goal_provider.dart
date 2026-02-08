import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_mode.dart';
import '../models/goal.dart';
import '../services/api_client.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';

class GoalListNotifier extends StateNotifier<List<FinancialGoal>> {
  GoalListNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/goals');
      final list = (response['data'] as List)
          .map((j) => FinancialGoal.fromJson(j as Map<String, dynamic>))
          .toList();
      state = list;
      _loaded = true;
    } on ApiException {
      // keep current state
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) await fetchAll();
  }

  Future<void> add(FinancialGoal goal) async {
    try {
      final response = await ApiClient.post('/goals', body: goal.toJson());
      final created = FinancialGoal.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> update(FinancialGoal goal) async {
    try {
      final response = await ApiClient.put('/goals/${goal.id}', body: goal.toJson());
      final updated = FinancialGoal.fromJson(response['data'] as Map<String, dynamic>);
      state = [for (final g in state) if (g.id == updated.id) updated else g];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/goals/$id');
      state = state.where((g) => g.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> toggleActive(String id) async {
    final goal = state.firstWhere((g) => g.id == id);
    final toggled = goal.copyWith(isActive: !goal.isActive);
    await update(toggled);
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final goalListProvider =
    StateNotifierProvider<GoalListNotifier, List<FinancialGoal>>(
  (ref) => GoalListNotifier(),
);

// Auto-calculated goals with current amounts from transactions
final activeGoalsProvider = Provider<List<FinancialGoal>>((ref) {
  final mode = ref.watch(accountModeProvider);
  final goals = ref.watch(goalListProvider).where((g) => g.isActive).toList();
  final totalIncome = ref.watch(totalIncomeProvider);
  final totalExpense = ref.watch(totalExpenseProvider);

  final isPersonal = mode == AccountMode.personal;

  return goals
      .where((g) {
        if (isPersonal) {
          return g.type == GoalType.income ||
              g.type == GoalType.expense ||
              g.type == GoalType.savings;
        } else {
          return g.type == GoalType.revenue ||
              g.type == GoalType.profit ||
              g.type == GoalType.income ||
              g.type == GoalType.expense;
        }
      })
      .map((g) {
        double current;
        switch (g.type) {
          case GoalType.income:
          case GoalType.revenue:
            current = totalIncome;
            break;
          case GoalType.expense:
            current = totalExpense;
            break;
          case GoalType.savings:
          case GoalType.profit:
            current = totalIncome - totalExpense;
            break;
        }
        return g.copyWith(currentAmount: current);
      })
      .toList();
});
