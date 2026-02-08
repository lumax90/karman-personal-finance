import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../services/api_client.dart';
import 'account_provider.dart';

class SubscriptionNotifier extends StateNotifier<List<SubscriptionModel>> {
  SubscriptionNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/subscriptions');
      final list = (response['data'] as List)
          .map((j) => SubscriptionModel.fromJson(j as Map<String, dynamic>))
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

  Future<void> add(SubscriptionModel sub) async {
    try {
      final response = await ApiClient.post('/subscriptions', body: sub.toJson());
      final created = SubscriptionModel.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/subscriptions/$id');
      state = state.where((s) => s.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> update(SubscriptionModel sub) async {
    try {
      final response = await ApiClient.put('/subscriptions/${sub.id}', body: sub.toJson());
      final updated = SubscriptionModel.fromJson(response['data'] as Map<String, dynamic>);
      state = state.map((s) => s.id == updated.id ? updated : s).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> toggleActive(String id) async {
    final sub = state.firstWhere((s) => s.id == id);
    final toggled = sub.copyWith(isActive: !sub.isActive);
    await update(toggled);
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final subscriptionListProvider =
    StateNotifierProvider<SubscriptionNotifier, List<SubscriptionModel>>(
  (ref) => SubscriptionNotifier(),
);

final filteredSubscriptionsProvider = Provider<List<SubscriptionModel>>((ref) {
  final mode = ref.watch(accountModeProvider);
  final subs = ref.watch(subscriptionListProvider);
  return subs.where((s) => s.accountMode == mode).toList();
});

final activeSubscriptionsProvider = Provider<List<SubscriptionModel>>((ref) {
  return ref.watch(filteredSubscriptionsProvider).where((s) => s.isActive).toList();
});

final totalMonthlySubscriptionCostProvider = Provider<double>((ref) {
  return ref
      .watch(activeSubscriptionsProvider)
      .fold(0.0, (sum, s) => sum + s.monthlyAmount);
});
