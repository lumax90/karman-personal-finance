import 'package:flutter/material.dart';

enum ReminderType { invoiceDue, followUp, subscriptionRenewal, goalDeadline, custom }

class Reminder {
  final String id;
  final String title;
  final String? subtitle;
  final ReminderType type;
  final DateTime dueDate;
  final bool isCompleted;
  final String? linkedId;
  final IconData icon;

  const Reminder({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
    this.linkedId,
    this.icon = Icons.notifications_outlined,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final type = ReminderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ReminderType.custom,
    );
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      type: type,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      linkedId: json['linkedId'] as String?,
      icon: _iconForType(type),
    );
  }

  static IconData _iconForType(ReminderType type) {
    switch (type) {
      case ReminderType.invoiceDue:
        return Icons.receipt_long_outlined;
      case ReminderType.followUp:
        return Icons.people_outline;
      case ReminderType.subscriptionRenewal:
        return Icons.autorenew;
      case ReminderType.goalDeadline:
        return Icons.flag_outlined;
      case ReminderType.custom:
        return Icons.notifications_outlined;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'dueDate': dueDate.toIso8601String(),
      'type': type.name,
      'isCompleted': isCompleted,
      'linkedId': linkedId,
    };
  }

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueDate);
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
  }
  bool get isDueSoon => !isCompleted && dueDate.difference(DateTime.now()).inDays <= 3 && dueDate.isAfter(DateTime.now());

  Reminder copyWith({
    String? title,
    String? subtitle,
    ReminderType? type,
    DateTime? dueDate,
    bool? isCompleted,
    String? linkedId,
    IconData? icon,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedId: linkedId ?? this.linkedId,
      icon: icon ?? this.icon,
    );
  }
}
