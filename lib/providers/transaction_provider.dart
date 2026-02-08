import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/api_client.dart';
import 'account_provider.dart';

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/transactions', queryParams: {'limit': '500'});
      final list = (response['data'] as List)
          .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
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

  Future<void> add(Transaction transaction) async {
    try {
      final response = await ApiClient.post('/transactions', body: transaction.toJson());
      final created = Transaction.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/transactions/$id');
      state = state.where((t) => t.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> update(Transaction transaction) async {
    try {
      final response = await ApiClient.put(
        '/transactions/${transaction.id}',
        body: transaction.toJson(),
      );
      final updated = Transaction.fromJson(response['data'] as Map<String, dynamic>);
      state = state.map((t) => t.id == updated.id ? updated : t).toList();
    } on ApiException {
      rethrow;
    }
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>(
  (ref) => TransactionNotifier(),
);

// Filtered providers
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final mode = ref.watch(accountModeProvider);
  final transactions = ref.watch(transactionListProvider);
  return transactions.where((t) => t.accountMode == mode).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final netBalanceProvider = Provider<double>((ref) {
  return ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider);
});

final recurringExpensesProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((t) => t.isRecurring && t.type == TransactionType.expense)
      .toList();
});

final recurringIncomeProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((t) => t.isRecurring && t.type == TransactionType.income)
      .toList();
});

