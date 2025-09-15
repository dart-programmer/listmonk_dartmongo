import 'package:json_annotation/json_annotation.dart';

part 'email_recipient.g.dart';

/// Unified email recipient model that can represent data from both users and subscribers collections
@JsonSerializable()
class EmailRecipient {
  /// Unique identifier (could be from either collection)
  final String id;
  
  /// UUID (preferred identifier)
  final String uuid;
  
  /// Email address
  final String email;
  
  /// Display name
  final String? name;
  
  /// Status of the recipient
  final String status;
  
  /// Source collection (users or subscribers)
  final String source;
  
  /// Additional attributes/metadata
  final Map<String, dynamic>? attributes;
  
  /// List subscriptions (if from subscribers collection)
  final List<Subscription>? subscriptions;
  
  /// User profile data (if from users collection)
  final Map<String, dynamic>? profile;
  
  /// Created timestamp
  final DateTime? createdAt;
  
  /// Updated timestamp
  final DateTime? updatedAt;
  
  /// Last activity timestamp
  final DateTime? lastActivityAt;

  const EmailRecipient({
    required this.id,
    required this.uuid,
    required this.email,
    this.name,
    required this.status,
    required this.source,
    this.attributes,
    this.subscriptions,
    this.profile,
    this.createdAt,
    this.updatedAt,
    this.lastActivityAt,
  });

  factory EmailRecipient.fromJson(Map<String, dynamic> json) => _$EmailRecipientFromJson(json);
  Map<String, dynamic> toJson() => _$EmailRecipientToJson(this);

  /// Create EmailRecipient from subscribers collection data
  factory EmailRecipient.fromSubscriber(Map<String, dynamic> subscriberData) {
    return EmailRecipient(
      id: subscriberData['id']?.toString() ?? '',
      uuid: subscriberData['uuid'] ?? '',
      email: subscriberData['email'] ?? '',
      name: subscriberData['name'],
      status: subscriberData['status'] ?? 'unknown',
      source: 'subscribers',
      attributes: subscriberData['attributes'],
      subscriptions: (subscriberData['lists'] as List?)
          ?.map((l) => Subscription.fromJson(l))
          .toList(),
      createdAt: subscriberData['created_at'] != null 
          ? DateTime.tryParse(subscriberData['created_at'].toString())
          : null,
      updatedAt: subscriberData['updated_at'] != null 
          ? DateTime.tryParse(subscriberData['updated_at'].toString())
          : null,
      lastActivityAt: subscriberData['last_activity_at'] != null 
          ? DateTime.tryParse(subscriberData['last_activity_at'].toString())
          : null,
    );
  }

  /// Create EmailRecipient from users collection data
  factory EmailRecipient.fromUser(Map<String, dynamic> userData) {
    return EmailRecipient(
      id: userData['_id']?.toString() ?? userData['id']?.toString() ?? '',
      uuid: userData['uuid'] ?? '',
      email: userData['email'] ?? '',
      name: userData['name'] ?? userData['displayName'],
      status: userData['status'] ?? userData['isActive'] == true ? 'active' : 'inactive',
      source: 'users',
      profile: userData['profile'],
      attributes: userData['attributes'] ?? userData['metadata'],
      createdAt: userData['createdAt'] != null 
          ? DateTime.tryParse(userData['createdAt'].toString())
          : null,
      updatedAt: userData['updatedAt'] != null 
          ? DateTime.tryParse(userData['updatedAt'].toString())
          : null,
      lastActivityAt: userData['lastLoginAt'] != null 
          ? DateTime.tryParse(userData['lastLoginAt'].toString())
          : null,
    );
  }

  /// Check if recipient is active
  bool get isActive => status == 'active' || status == 'enabled';

  /// Check if recipient is subscribed to any lists
  bool get hasSubscriptions => subscriptions?.isNotEmpty ?? false;

  /// Get display name or email as fallback
  String get displayName => name ?? email;

  /// Get primary identifier (prefer UUID)
  String get primaryId => uuid.isNotEmpty ? uuid : id;

  /// Copy with updated fields
  EmailRecipient copyWith({
    String? id,
    String? uuid,
    String? email,
    String? name,
    String? status,
    String? source,
    Map<String, dynamic>? attributes,
    List<Subscription>? subscriptions,
    Map<String, dynamic>? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
  }) {
    return EmailRecipient(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      name: name ?? this.name,
      status: status ?? this.status,
      source: source ?? this.source,
      attributes: attributes ?? this.attributes,
      subscriptions: subscriptions ?? this.subscriptions,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  String toString() {
    return 'EmailRecipient(id: $id, uuid: $uuid, email: $email, name: $name, status: $status, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailRecipient &&
        other.uuid == uuid &&
        other.email == email &&
        other.source == source;
  }

  @override
  int get hashCode => uuid.hashCode ^ email.hashCode ^ source.hashCode;
}

/// Email recipient status constants
class EmailRecipientStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String enabled = 'enabled';
  static const String disabled = 'disabled';
  static const String blocklisted = 'blocklisted';
  static const String unsubscribed = 'unsubscribed';
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
}

/// Email recipient source constants
class EmailRecipientSource {
  static const String subscribers = 'subscribers';
  static const String users = 'users';
}