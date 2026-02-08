import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../services/api_client.dart';

class ContactListNotifier extends StateNotifier<List<Contact>> {
  ContactListNotifier() : super([]);

  bool _loaded = false;

  Future<void> fetchAll() async {
    try {
      final response = await ApiClient.get('/contacts');
      final list = (response['data'] as List)
          .map((j) => Contact.fromJson(j as Map<String, dynamic>))
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

  Future<void> add(Contact contact) async {
    try {
      final response = await ApiClient.post('/contacts', body: contact.toJson());
      final created = Contact.fromJson(response['data'] as Map<String, dynamic>);
      state = [...state, created];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> update(Contact contact) async {
    try {
      final response = await ApiClient.put('/contacts/${contact.id}', body: contact.toJson());
      final updated = Contact.fromJson(response['data'] as Map<String, dynamic>);
      state = [for (final c in state) if (c.id == updated.id) updated else c];
    } on ApiException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/contacts/$id');
      state = state.where((c) => c.id != id).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> updateStatus(String id, ContactStatus status) async {
    final contact = state.firstWhere((c) => c.id == id);
    await update(contact.copyWith(status: status));
  }

  Future<void> convertToClient(String id) async {
    final contact = state.firstWhere((c) => c.id == id);
    await update(contact.copyWith(type: ContactType.client, status: ContactStatus.won));
  }

  void clear() {
    state = [];
    _loaded = false;
  }
}

final contactListProvider =
    StateNotifierProvider<ContactListNotifier, List<Contact>>(
  (ref) => ContactListNotifier(),
);

// Filtered providers
final leadsProvider = Provider<List<Contact>>((ref) {
  return ref.watch(contactListProvider).where((c) => c.type == ContactType.lead).toList();
});

final clientsProvider = Provider<List<Contact>>((ref) {
  return ref.watch(contactListProvider).where((c) => c.type == ContactType.client).toList();
});

final activeContactsProvider = Provider<List<Contact>>((ref) {
  return ref.watch(contactListProvider).where((c) => c.status.isActive).toList();
});

final contactByIdProvider = Provider.family<Contact?, String>((ref, id) {
  final contacts = ref.watch(contactListProvider);
  try {
    return contacts.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

// Stats
final totalLeadsCountProvider = Provider<int>((ref) {
  return ref.watch(leadsProvider).length;
});

final totalClientsCountProvider = Provider<int>((ref) {
  return ref.watch(clientsProvider).length;
});

final totalContactRevenueProvider = Provider<double>((ref) {
  return ref.watch(clientsProvider).fold(0.0, (sum, c) => sum + c.totalRevenue);
});
