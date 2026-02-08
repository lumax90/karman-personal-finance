enum DealStage {
  discovery,
  qualification,
  proposal,
  negotiation,
  closedWon,
  closedLost,
}

extension DealStageX on DealStage {
  String get label {
    switch (this) {
      case DealStage.discovery: return 'Discovery';
      case DealStage.qualification: return 'Qualification';
      case DealStage.proposal: return 'Proposal';
      case DealStage.negotiation: return 'Negotiation';
      case DealStage.closedWon: return 'Closed Won';
      case DealStage.closedLost: return 'Closed Lost';
    }
  }

  int get probability {
    switch (this) {
      case DealStage.discovery: return 10;
      case DealStage.qualification: return 25;
      case DealStage.proposal: return 50;
      case DealStage.negotiation: return 75;
      case DealStage.closedWon: return 100;
      case DealStage.closedLost: return 0;
    }
  }

  bool get isOpen => this != DealStage.closedWon && this != DealStage.closedLost;
}

class Deal {
  final String id;
  final String title;
  final String contactId;
  final String contactName;
  final double amount;
  final DealStage stage;
  final DateTime createdAt;
  final DateTime? expectedCloseDate;
  final String? notes;

  const Deal({
    required this.id,
    required this.title,
    required this.contactId,
    required this.contactName,
    required this.amount,
    required this.stage,
    required this.createdAt,
    this.expectedCloseDate,
    this.notes,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      title: json['title'] as String,
      contactId: json['contactId'] as String? ?? '',
      contactName: json['contactName'] as String? ??
          (json['contact'] != null ? json['contact']['name'] as String? ?? '' : ''),
      amount: (json['amount'] as num).toDouble(),
      stage: DealStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => DealStage.discovery,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expectedCloseDate: json['expectedCloseDate'] != null
          ? DateTime.parse(json['expectedCloseDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'contactName': contactName,
      'amount': amount,
      'stage': stage.name,
      'probability': stage.probability,
    };
    if (contactId.isNotEmpty) map['contactId'] = contactId;
    if (expectedCloseDate != null) map['expectedCloseDate'] = expectedCloseDate!.toIso8601String();
    if (notes != null) map['notes'] = notes;
    return map;
  }

  double get weightedAmount => amount * (stage.probability / 100);

  Deal copyWith({
    String? title,
    String? contactId,
    String? contactName,
    double? amount,
    DealStage? stage,
    DateTime? expectedCloseDate,
    String? notes,
  }) {
    return Deal(
      id: id,
      title: title ?? this.title,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      amount: amount ?? this.amount,
      stage: stage ?? this.stage,
      createdAt: createdAt,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      notes: notes ?? this.notes,
    );
  }
}
