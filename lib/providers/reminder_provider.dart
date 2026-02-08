import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../services/api_client.dart';

class ReminderListNotifier extends StateNotifier<List<Reminder>> {
  ReminderListNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/reminders');
      final list = (response['data'] as List)
          .map((j) => Reminder.fromJson(j as Map<String, dynamic>))
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

  Future<void> add(Reminder reminder) async {
    try {
      final response = await ApiClient.post('/reminders', body: reminder.toJson());
      final created = Reminder.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/reminders/$id');
      state = state.where((r) => r.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> toggleComplete(String id) async {
    try {
      final response = await ApiClient.patch('/reminders/$id/toggle');
      final updated = Reminder.fromJson(response['data'] as Map<String, dynamic>);
      state = [
        for (final r in state)
          if (r.id == updated.id) updated else r,
      ];
    } on ApiException {
      rethrow;
    }
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final reminderListProvider =
    StateNotifierProvider<ReminderListNotifier, List<Reminder>>(
  (ref) => ReminderListNotifier(),
);

final pendingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(reminderListProvider)
      .where((r) => !r.isCompleted)
      .toList();
  reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return reminders;
});

final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(reminderListProvider)
      .where((r) => r.isOverdue)
      .toList();
});

final todayRemindersProvider = Provider<List<Reminder>>((ref) {
  return ref.watch(reminderListProvider)
      .where((r) => r.isDueToday && !r.isCompleted)
      .toList();
});

final urgentReminderCountProvider = Provider<int>((ref) {
  return ref.watch(reminderListProvider)
      .where((r) => !r.isCompleted && (r.isOverdue || r.isDueToday || r.isDueSoon))
      .length;
});
