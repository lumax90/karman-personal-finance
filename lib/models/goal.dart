enum GoalType { income, expense, savings, revenue, profit }

enum GoalPeriod { monthly, yearly }

class FinancialGoal {
  final String id;
  final String title;
  final GoalType type;
  final GoalPeriod period;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const FinancialGoal({
    required this.id,
    required this.title,
    required this.type,
    this.period = GoalPeriod.monthly,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      type: GoalType.values.firstWhere((e) => e.name == json['type']),
      period: GoalPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => GoalPeriod.monthly,
      ),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'period': period.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.5) : 0;
  double get progressPercent => (progress * 100);
  bool get isCompleted => currentAmount >= targetAmount;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  FinancialGoal copyWith({
    String? title,
    GoalType? type,
    GoalPeriod? period,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return FinancialGoal(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      period: period ?? this.period,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
