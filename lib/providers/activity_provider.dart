import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../services/api_client.dart';

final activityListProvider =
    NotifierProvider<ActivityListNotifier, List<Activity>>(ActivityListNotifier.new);

class ActivityListNotifier extends Notifier<List<Activity>> {
  @override
  List<Activity> build() => [];

  Future<void> fetchAll() async {
    try {
      final data = await ApiClient.get('/activities');
      final list = (data['data'] as List)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> add(Activity activity) async {
    try {
      final data = await ApiClient.post('/activities', body: activity.toJson());
      final created = Activity.fromJson(data['data'] as Map<String, dynamic>);
      state = [...state, created];
    } catch (_) {}
  }

  Future<void> update(Activity activity) async {
    try {
      final data = await ApiClient.put('/activities/${activity.id}', body: activity.toJson());
      final updated = Activity.fromJson(data['data'] as Map<String, dynamic>);
      state = [for (final a in state) if (a.id == updated.id) updated else a];
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/activities/$id');
      state = state.where((a) => a.id != id).toList();
    } catch (_) {}
  }

  Future<void> toggleComplete(String id) async {
    try {
      final data = await ApiClient.patch('/activities/$id/toggle');
      final updated = Activity.fromJson(data['data'] as Map<String, dynamic>);
      state = [for (final a in state) if (a.id == id) updated else a];
    } catch (_) {}
  }

  void clear() => state = [];
}

final activitiesByContactProvider = Provider.family<List<Activity>, String>((ref, contactId) {
  final activities = ref.watch(activityListProvider)
      .where((a) => a.contactId == contactId)
      .toList();
  activities.sort((a, b) => b.date.compareTo(a.date));
  return activities;
});

final upcomingActivitiesProvider = Provider<List<Activity>>((ref) {
  final now = DateTime.now();
  final activities = ref.watch(activityListProvider)
      .where((a) => !a.isCompleted && a.date.isAfter(now.subtract(const Duration(days: 1))))
      .toList();
  activities.sort((a, b) => a.date.compareTo(b.date));
  return activities;
});

final overdueActivitiesProvider = Provider<List<Activity>>((ref) {
  final now = DateTime.now();
  return ref.watch(activityListProvider)
      .where((a) => !a.isCompleted && a.date.isBefore(now))
      .toList();
});
