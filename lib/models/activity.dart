import 'package:flutter/material.dart';

enum ActivityType { call, email, meeting, task, note }

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.call: return 'Call';
      case ActivityType.email: return 'Email';
      case ActivityType.meeting: return 'Meeting';
      case ActivityType.task: return 'Task';
      case ActivityType.note: return 'Note';
    }
  }

  IconData get iconData {
    switch (this) {
      case ActivityType.call: return Icons.phone_outlined;
      case ActivityType.email: return Icons.email_outlined;
      case ActivityType.meeting: return Icons.groups_outlined;
      case ActivityType.task: return Icons.check_circle_outline;
      case ActivityType.note: return Icons.note_outlined;
    }
  }
}

class Activity {
  final String id;
  final String? contactId;
  final ActivityType type;
  final String title;
  final String? description;
  final DateTime date;
  final bool isCompleted;
  final String? dealId;

  const Activity({
    required this.id,
    this.contactId,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.isCompleted = false,
    this.dealId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      contactId: json['contactId'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.note,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      dealId: json['dealId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type.name,
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
    if (contactId != null) map['contactId'] = contactId;
    if (description != null) map['description'] = description;
    if (dealId != null) map['dealId'] = dealId;
    return map;
  }

  Activity copyWith({
    String? contactId,
    ActivityType? type,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    String? dealId,
  }) {
    return Activity(
      id: id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      dealId: dealId ?? this.dealId,
    );
  }
}
