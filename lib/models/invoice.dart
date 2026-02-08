enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft: return 'Draft';
      case InvoiceStatus.sent: return 'Sent';
      case InvoiceStatus.paid: return 'Paid';
      case InvoiceStatus.overdue: return 'Overdue';
      case InvoiceStatus.cancelled: return 'Cancelled';
    }
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String? contactId;
  final String contactName;
  final List<InvoiceItem> items;
  final double taxRate;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? notes;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.contactId,
    required this.contactName,
    required this.items,
    this.taxRate = 20.0,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get totalAmount => subtotal + taxAmount;

  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      DateTime.now().isAfter(dueDate);

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<InvoiceItem> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      contactId: json['contactId'] as String?,
      contactName: json['contactName'] as String,
      items: items,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 20.0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'invoiceNumber': invoiceNumber,
      'contactName': contactName,
      'items': items.map((e) => e.toJson()).toList(),
      'taxRate': taxRate,
      'status': status.name,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
    };
    if (contactId != null) map['contactId'] = contactId;
    if (paidDate != null) map['paidDate'] = paidDate!.toIso8601String();
    if (notes != null) map['notes'] = notes;
    return map;
  }

  Invoice copyWith({
    String? invoiceNumber,
    String? contactId,
    String? contactName,
    List<InvoiceItem>? items,
    double? taxRate,
    InvoiceStatus? status,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    String? notes,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
    );
  }
}
