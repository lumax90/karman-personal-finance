import 'package:flutter/material.dart';
import 'account_mode.dart';

enum TransactionType { income, expense }

enum RecurrenceType { once, daily, weekly, monthly, yearly }

enum TransactionCategory {
  // Personal Income
  salary,
  freelance,
  investment,
  rental,
  otherIncome,
  // Personal Expense
  rent,
  utilities,
  groceries,
  transport,
  entertainment,
  health,
  education,
  shopping,
  food,
  // Business Income
  sales,
  service,
  consulting,
  commission,
  // Business Expense
  marketing,
  software,
  hosting,
  office,
  equipment,
  taxes,
  insurance,
  payroll,
  // Shared
  subscription,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.salary: return 'Maaş';
      case TransactionCategory.freelance: return 'Freelance';
      case TransactionCategory.investment: return 'Yatırım';
      case TransactionCategory.rental: return 'Kira Geliri';
      case TransactionCategory.otherIncome: return 'Diğer Gelir';
      case TransactionCategory.rent: return 'Kira';
      case TransactionCategory.utilities: return 'Faturalar';
      case TransactionCategory.groceries: return 'Market';
      case TransactionCategory.transport: return 'Ulaşım';
      case TransactionCategory.entertainment: return 'Eğlence';
      case TransactionCategory.health: return 'Sağlık';
      case TransactionCategory.education: return 'Eğitim';
      case TransactionCategory.shopping: return 'Alışveriş';
      case TransactionCategory.food: return 'Yemek';
      case TransactionCategory.sales: return 'Satış';
      case TransactionCategory.service: return 'Hizmet';
      case TransactionCategory.consulting: return 'Danışmanlık';
      case TransactionCategory.commission: return 'Komisyon';
      case TransactionCategory.marketing: return 'Pazarlama';
      case TransactionCategory.software: return 'Yazılım';
      case TransactionCategory.hosting: return 'Hosting';
      case TransactionCategory.office: return 'Ofis';
      case TransactionCategory.equipment: return 'Ekipman';
      case TransactionCategory.taxes: return 'Vergi';
      case TransactionCategory.insurance: return 'Sigorta';
      case TransactionCategory.payroll: return 'Maaş Ödemesi';
      case TransactionCategory.subscription: return 'Abonelik';
      case TransactionCategory.other: return 'Diğer';
    }
  }

  IconData get iconData {
    switch (this) {
      case TransactionCategory.salary: return Icons.account_balance_wallet_outlined;
      case TransactionCategory.freelance: return Icons.laptop_mac_outlined;
      case TransactionCategory.investment: return Icons.trending_up;
      case TransactionCategory.rental: return Icons.home_outlined;
      case TransactionCategory.otherIncome: return Icons.attach_money;
      case TransactionCategory.rent: return Icons.home_outlined;
      case TransactionCategory.utilities: return Icons.bolt_outlined;
      case TransactionCategory.groceries: return Icons.shopping_cart_outlined;
      case TransactionCategory.transport: return Icons.directions_car_outlined;
      case TransactionCategory.entertainment: return Icons.movie_outlined;
      case TransactionCategory.health: return Icons.local_hospital_outlined;
      case TransactionCategory.education: return Icons.menu_book_outlined;
      case TransactionCategory.shopping: return Icons.shopping_bag_outlined;
      case TransactionCategory.food: return Icons.restaurant_outlined;
      case TransactionCategory.sales: return Icons.inventory_2_outlined;
      case TransactionCategory.service: return Icons.build_outlined;
      case TransactionCategory.consulting: return Icons.handshake_outlined;
      case TransactionCategory.commission: return Icons.percent_outlined;
      case TransactionCategory.marketing: return Icons.campaign_outlined;
      case TransactionCategory.software: return Icons.code_outlined;
      case TransactionCategory.hosting: return Icons.cloud_outlined;
      case TransactionCategory.office: return Icons.business_outlined;
      case TransactionCategory.equipment: return Icons.construction_outlined;
      case TransactionCategory.taxes: return Icons.receipt_long_outlined;
      case TransactionCategory.insurance: return Icons.shield_outlined;
      case TransactionCategory.payroll: return Icons.groups_outlined;
      case TransactionCategory.subscription: return Icons.autorenew;
      case TransactionCategory.other: return Icons.more_horiz;
    }
  }

  bool get isPersonalCategory {
    return [
      TransactionCategory.salary,
      TransactionCategory.freelance,
      TransactionCategory.investment,
      TransactionCategory.rental,
      TransactionCategory.otherIncome,
      TransactionCategory.rent,
      TransactionCategory.utilities,
      TransactionCategory.groceries,
      TransactionCategory.transport,
      TransactionCategory.entertainment,
      TransactionCategory.health,
      TransactionCategory.education,
      TransactionCategory.shopping,
      TransactionCategory.food,
      TransactionCategory.subscription,
      TransactionCategory.other,
    ].contains(this);
  }

  bool get isBusinessCategory {
    return [
      TransactionCategory.sales,
      TransactionCategory.service,
      TransactionCategory.consulting,
      TransactionCategory.commission,
      TransactionCategory.otherIncome,
      TransactionCategory.marketing,
      TransactionCategory.software,
      TransactionCategory.hosting,
      TransactionCategory.office,
      TransactionCategory.equipment,
      TransactionCategory.taxes,
      TransactionCategory.insurance,
      TransactionCategory.payroll,
      TransactionCategory.subscription,
      TransactionCategory.other,
    ].contains(this);
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final RecurrenceType recurrence;
  final DateTime date;
  final DateTime? endDate;
  final String? note;
  final AccountMode accountMode;
  final bool isPaid;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.recurrence = RecurrenceType.once,
    required this.date,
    this.endDate,
    this.note,
    required this.accountMode,
    this.isPaid = true,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      category: TransactionCategory.values.firstWhere((e) => e.name == json['category']),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => RecurrenceType.once,
      ),
      date: DateTime.parse(json['date'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      note: json['notes'] as String?,
      accountMode: AccountMode.values.firstWhere((e) => e.name == json['accountMode']),
      isPaid: json['isPaid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'recurrence': recurrence.name,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
      'accountMode': accountMode.name,
    };
    if (note != null) map['notes'] = note;
    return map;
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    RecurrenceType? recurrence,
    DateTime? date,
    DateTime? endDate,
    String? note,
    AccountMode? accountMode,
    bool? isPaid,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      accountMode: accountMode ?? this.accountMode,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  bool get isRecurring => recurrence != RecurrenceType.once;
}
