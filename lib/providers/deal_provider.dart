import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deal.dart';
import '../services/api_client.dart';

class DealListNotifier extends StateNotifier<List<Deal>> {
  DealListNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/deals');
      final list = (response['data'] as List)
          .map((j) => Deal.fromJson(j as Map<String, dynamic>))
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

  Future<void> add(Deal deal) async {
    try {
      final response = await ApiClient.post('/deals', body: deal.toJson());
      final created = Deal.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> update(Deal deal) async {
    try {
      final response = await ApiClient.put('/deals/${deal.id}', body: deal.toJson());
      final updated = Deal.fromJson(response['data'] as Map<String, dynamic>);
      state = [for (final d in state) if (d.id == updated.id) updated else d];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/deals/$id');
      state = state.where((d) => d.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> updateStage(String id, DealStage stage) async {
    try {
      final response = await ApiClient.patch('/deals/$id/stage', body: {'stage': stage.name});
      final updated = Deal.fromJson(response['data'] as Map<String, dynamic>);
      state = [for (final d in state) if (d.id == updated.id) updated else d];
    } on ApiException {
      rethrow;
    }
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final dealListProvider =
    StateNotifierProvider<DealListNotifier, List<Deal>>(
  (ref) => DealListNotifier(),
);

// Filtered
final openDealsProvider = Provider<List<Deal>>((ref) {
  return ref.watch(dealListProvider).where((d) => d.stage.isOpen).toList();
});

final wonDealsProvider = Provider<List<Deal>>((ref) {
  return ref.watch(dealListProvider).where((d) => d.stage == DealStage.closedWon).toList();
});

final lostDealsProvider = Provider<List<Deal>>((ref) {
  return ref.watch(dealListProvider).where((d) => d.stage == DealStage.closedLost).toList();
});

final dealsByContactProvider = Provider.family<List<Deal>, String>((ref, contactId) {
  return ref.watch(dealListProvider).where((d) => d.contactId == contactId).toList();
});

final dealsByStageProvider = Provider.family<List<Deal>, DealStage>((ref, stage) {
  return ref.watch(dealListProvider).where((d) => d.stage == stage).toList();
});

// Stats
final totalPipelineValueProvider = Provider<double>((ref) {
  return ref.watch(openDealsProvider).fold(0.0, (sum, d) => sum + d.amount);
});

final weightedPipelineValueProvider = Provider<double>((ref) {
  return ref.watch(openDealsProvider).fold(0.0, (sum, d) => sum + d.weightedAmount);
});

final totalWonValueProvider = Provider<double>((ref) {
  return ref.watch(wonDealsProvider).fold(0.0, (sum, d) => sum + d.amount);
});

final winRateProvider = Provider<double>((ref) {
  final won = ref.watch(wonDealsProvider).length;
  final lost = ref.watch(lostDealsProvider).length;
  final total = won + lost;
  if (total == 0) return 0;
  return won / total * 100;
});
