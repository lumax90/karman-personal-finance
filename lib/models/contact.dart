enum ContactType { lead, client }

enum ContactStatus {
  newLead,
  contacted,
  qualified,
  proposal,
  negotiation,
  won,
  lost,
  churned,
}

extension ContactStatusX on ContactStatus {
  String get label {
    switch (this) {
      case ContactStatus.newLead: return 'New';
      case ContactStatus.contacted: return 'Contacted';
      case ContactStatus.qualified: return 'Qualified';
      case ContactStatus.proposal: return 'Proposal';
      case ContactStatus.negotiation: return 'Negotiation';
      case ContactStatus.won: return 'Won';
      case ContactStatus.lost: return 'Lost';
      case ContactStatus.churned: return 'Churned';
    }
  }

  bool get isActive => this != ContactStatus.lost && this != ContactStatus.churned;

  bool get isLead => index <= ContactStatus.negotiation.index;
}

enum ContactSource {
  website,
  referral,
  social,
  cold,
  event,
  other,
}

class Contact {
  final String id;
  final String name;
  final String? company;
  final String? email;
  final String? phone;
  final ContactType type;
  final ContactStatus status;
  final ContactSource source;
  final List<String> tags;
  final String? notes;
  final double totalRevenue;
  final DateTime createdAt;
  final DateTime? lastContactedAt;

  const Contact({
    required this.id,
    required this.name,
    this.company,
    this.email,
    this.phone,
    required this.type,
    required this.status,
    this.source = ContactSource.other,
    this.tags = const [],
    this.notes,
    this.totalRevenue = 0,
    required this.createdAt,
    this.lastContactedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      company: json['company'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      type: ContactType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContactType.lead,
      ),
      status: ContactStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContactStatus.newLead,
      ),
      source: ContactSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ContactSource.other,
      ),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      notes: json['notes'] as String?,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastContactedAt: json['lastContactedAt'] != null
          ? DateTime.parse(json['lastContactedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'type': type.name,
      'status': status.name,
      'source': source.name,
      'tags': tags,
      'totalRevenue': totalRevenue,
    };
    if (company != null) map['company'] = company;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (notes != null) map['notes'] = notes;
    if (lastContactedAt != null) map['lastContactedAt'] = lastContactedAt!.toIso8601String();
    return map;
  }

  Contact copyWith({
    String? name,
    String? company,
    String? email,
    String? phone,
    ContactType? type,
    ContactStatus? status,
    ContactSource? source,
    List<String>? tags,
    String? notes,
    double? totalRevenue,
    DateTime? lastContactedAt,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      status: status ?? this.status,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      createdAt: createdAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
    );
  }
}
