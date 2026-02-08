import 'account_mode.dart';

enum BillingCycle { monthly, yearly, weekly }

class SubscriptionModel {
  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final DateTime startDate;
  final DateTime? nextPaymentDate;
  final bool isActive;
  final String? category;
  final String? note;
  final AccountMode accountMode;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    this.cycle = BillingCycle.monthly,
    required this.startDate,
    this.nextPaymentDate,
    this.isActive = true,
    this.category,
    this.note,
    required this.accountMode,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      cycle: BillingCycle.values.firstWhere((e) => e.name == json['cycle']),
      startDate: DateTime.parse(json['startDate'] as String),
      nextPaymentDate: json['nextPaymentDate'] != null
          ? DateTime.parse(json['nextPaymentDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      category: json['category'] as String?,
      note: json['note'] as String?,
      accountMode: AccountMode.values.firstWhere((e) => e.name == json['accountMode']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'amount': amount,
      'cycle': cycle.name,
      'startDate': startDate.toIso8601String(),
      'nextPaymentDate': (nextPaymentDate ?? startDate).toIso8601String(),
      'isActive': isActive,
      'accountMode': accountMode.name,
    };
    if (category != null) map['category'] = category;
    return map;
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    double? amount,
    BillingCycle? cycle,
    DateTime? startDate,
    DateTime? nextPaymentDate,
    bool? isActive,
    String? category,
    String? note,
    AccountMode? accountMode,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      cycle: cycle ?? this.cycle,
      startDate: startDate ?? this.startDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      note: note ?? this.note,
      accountMode: accountMode ?? this.accountMode,
    );
  }

  double get monthlyAmount {
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 4.33;
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.yearly:
        return amount / 12;
    }
  }

  String get cycleLabel {
    switch (cycle) {
      case BillingCycle.weekly: return 'Haftalık';
      case BillingCycle.monthly: return 'Aylık';
      case BillingCycle.yearly: return 'Yıllık';
    }
  }
}
