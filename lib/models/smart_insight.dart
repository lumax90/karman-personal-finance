import 'package:flutter/material.dart';

enum InsightType { alert, tip, achievement, warning, trend }

enum InsightPriority { high, medium, low }

class SmartInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final String? actionLabel;
  final bool isDismissed;

  const SmartInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.priority = InsightPriority.medium,
    required this.icon,
    required this.color,
    required this.createdAt,
    this.actionLabel,
    this.isDismissed = false,
  });

  SmartInsight copyWith({bool? isDismissed}) {
    return SmartInsight(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      icon: icon,
      color: color,
      createdAt: createdAt,
      actionLabel: actionLabel,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
