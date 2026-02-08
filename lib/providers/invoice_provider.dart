import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';

final invoiceListProvider =
    NotifierProvider<InvoiceListNotifier, List<Invoice>>(InvoiceListNotifier.new);

class InvoiceListNotifier extends Notifier<List<Invoice>> {
  @override
  List<Invoice> build() => [];

  Future<void> fetchAll() async {
    try {
      final data = await ApiClient.get('/invoices');
      final list = (data['data'] as List)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> add(Invoice invoice) async {
    try {
      final data = await ApiClient.post('/invoices', body: invoice.toJson());
      final created = Invoice.fromJson(data['data'] as Map<String, dynamic>);
      state = [...state, created];
    } catch (_) {}
  }

  Future<void> update(Invoice invoice) async {
    try {
      final data = await ApiClient.put('/invoices/${invoice.id}', body: invoice.toJson());
      final updated = Invoice.fromJson(data['data'] as Map<String, dynamic>);
      state = [for (final i in state) if (i.id == updated.id) updated else i];
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    try {
      await ApiClient.delete('/invoices/$id');
      state = state.where((i) => i.id != id).toList();
    } catch (_) {}
  }

  Future<void> markAsPaid(String id) async {
    try {
      final data = await ApiClient.patch('/invoices/$id/paid');
      final updated = Invoice.fromJson(data['data'] as Map<String, dynamic>);
      state = [for (final i in state) if (i.id == id) updated else i];
    } catch (_) {}
  }

  Future<void> markAsSent(String id) async {
    try {
      final data = await ApiClient.patch('/invoices/$id/sent');
      final updated = Invoice.fromJson(data['data'] as Map<String, dynamic>);
      state = [for (final i in state) if (i.id == id) updated else i];
    } catch (_) {}
  }

  void clear() => state = [];
}

// Filtered providers
final paidInvoicesProvider = Provider<List<Invoice>>((ref) {
  return ref.watch(invoiceListProvider).where((i) => i.status == InvoiceStatus.paid).toList();
});

final unpaidInvoicesProvider = Provider<List<Invoice>>((ref) {
  return ref.watch(invoiceListProvider).where((i) =>
      i.status == InvoiceStatus.sent || i.status == InvoiceStatus.overdue).toList();
});

final overdueInvoicesProvider = Provider<List<Invoice>>((ref) {
  return ref.watch(invoiceListProvider).where((i) => i.isOverdue).toList();
});

final invoicesByContactProvider = Provider.family<List<Invoice>, String>((ref, contactId) {
  return ref.watch(invoiceListProvider).where((i) => i.contactId == contactId).toList();
});

// Stats
final totalReceivableProvider = Provider<double>((ref) {
  return ref.watch(unpaidInvoicesProvider).fold(0.0, (sum, i) => sum + i.totalAmount);
});

final totalPaidProvider = Provider<double>((ref) {
  return ref.watch(paidInvoicesProvider).fold(0.0, (sum, i) => sum + i.totalAmount);
});

final totalOverdueProvider = Provider<double>((ref) {
  return ref.watch(overdueInvoicesProvider).fold(0.0, (sum, i) => sum + i.totalAmount);
});
