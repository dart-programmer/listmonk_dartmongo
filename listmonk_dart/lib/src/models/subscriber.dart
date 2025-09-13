import 'package:json_annotation/json_annotation.dart';
import 'base.dart';
import 'constants.dart';

part 'subscriber.g.dart';

/// Represents an email subscriber
@JsonSerializable()
class Subscriber extends Base {
  final String uuid;
  final String email;
  final String name;
  final JsonMap attribs;
  final String status;
  final List<Subscription> lists;

  const Subscriber({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.uuid,
    required this.email,
    required this.name,
    required this.attribs,
    required this.status,
    required this.lists,
  });

  factory Subscriber.fromJson(Map<String, dynamic> json) => 
      _$SubscriberFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriberToJson(this);

  /// Returns the first name from the full name
  String get firstName {
    final nameParts = name.split(' ');
    for (final part in nameParts) {
      if (part.length > 2) {
        return part;
      }
    }
    return name;
  }

  /// Returns the last name from the full name
  String get lastName {
    final nameParts = name.split(' ');
    for (int i = nameParts.length - 1; i >= 0; i--) {
      final part = nameParts[i];
      if (part.length > 2) {
        return part;
      }
    }
    return name;
  }

  /// Creates a copy with updated fields
  Subscriber copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uuid,
    String? email,
    String? name,
    JsonMap? attribs,
    String? status,
    List<Subscription>? lists,
  }) {
    return Subscriber(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      name: name ?? this.name,
      attribs: attribs ?? this.attribs,
      status: status ?? this.status,
      lists: lists ?? this.lists,
    );
  }
}

/// Represents a subscription relationship between a subscriber and a list
@JsonSerializable()
class Subscription {
  final int listId;
  final String listUuid;
  final String listName;
  final String listType;
  final String listOptin;
  final String? description;
  final List<String> tags;
  final String subscriptionStatus;
  @JsonKey(name: 'subscription_created_at')
  final DateTime? subscriptionCreatedAt;
  @JsonKey(name: 'subscription_updated_at')
  final DateTime? subscriptionUpdatedAt;
  final JsonMap meta;

  const Subscription({
    required this.listId,
    required this.listUuid,
    required this.listName,
    required this.listType,
    required this.listOptin,
    this.description,
    required this.tags,
    required this.subscriptionStatus,
    this.subscriptionCreatedAt,
    this.subscriptionUpdatedAt,
    required this.meta,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => 
      _$SubscriptionFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

/// Represents a subscriber export profile for data export
@JsonSerializable()
class SubscriberExportProfile {
  final String email;
  final JsonMap? profile;
  final JsonMap? subscriptions;
  final JsonMap? campaignViews;
  final JsonMap? linkClicks;

  const SubscriberExportProfile({
    required this.email,
    this.profile,
    this.subscriptions,
    this.campaignViews,
    this.linkClicks,
  });

  factory SubscriberExportProfile.fromJson(Map<String, dynamic> json) => 
      _$SubscriberExportProfileFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriberExportProfileToJson(this);
}

/// Represents a subscriber record for export
@JsonSerializable()
class SubscriberExport extends Base {
  final String uuid;
  final String email;
  final String name;
  final String attribs;
  final String status;

  const SubscriberExport({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.uuid,
    required this.email,
    required this.name,
    required this.attribs,
    required this.status,
  });

  factory SubscriberExport.fromJson(Map<String, dynamic> json) => 
      _$SubscriberExportFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriberExportToJson(this);
}

/// Internal structure for subscriber lists
@JsonSerializable()
class SubLists {
  @JsonKey(name: 'subscriber_id')
  final int subscriberId;
  final List<Subscription> lists;

  const SubLists({
    required this.subscriberId,
    required this.lists,
  });

  factory SubLists.fromJson(Map<String, dynamic> json) => 
      _$SubListsFromJson(json);
  Map<String, dynamic> toJson() => _$SubListsToJson(this);
}