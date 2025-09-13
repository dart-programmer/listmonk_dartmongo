import 'package:json_annotation/json_annotation.dart';
import 'base.dart';
import 'constants.dart';

part 'list.g.dart';

/// Represents a mailing list
@JsonSerializable()
class List extends Base {
  final String uuid;
  final String name;
  final String type;
  final String optin;
  final List<String> tags;
  final String description;
  @JsonKey(name: 'subscriber_count')
  final int subscriberCount;
  @JsonKey(name: 'subscriber_statuses')
  final StringIntMap subscriberCounts;
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;
  @JsonKey(name: 'subscription_created_at')
  final DateTime? subscriptionCreatedAt;
  @JsonKey(name: 'subscription_updated_at')
  final DateTime? subscriptionUpdatedAt;
  final int total;

  const List({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.uuid,
    required this.name,
    required this.type,
    required this.optin,
    required this.tags,
    required this.description,
    required this.subscriberCount,
    required this.subscriberCounts,
    this.subscriptionStatus,
    this.subscriptionCreatedAt,
    this.subscriptionUpdatedAt,
    required this.total,
  });

  factory List.fromJson(Map<String, dynamic> json) => _$ListFromJson(json);
  Map<String, dynamic> toJson() => _$ListToJson(this);

  /// Creates a copy with updated fields
  List copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uuid,
    String? name,
    String? type,
    String? optin,
    List<String>? tags,
    String? description,
    int? subscriberCount,
    StringIntMap? subscriberCounts,
    String? subscriptionStatus,
    DateTime? subscriptionCreatedAt,
    DateTime? subscriptionUpdatedAt,
    int? total,
  }) {
    return List(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      optin: optin ?? this.optin,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      subscriberCounts: subscriberCounts ?? this.subscriberCounts,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionCreatedAt: subscriptionCreatedAt ?? this.subscriptionCreatedAt,
      subscriptionUpdatedAt: subscriptionUpdatedAt ?? this.subscriptionUpdatedAt,
      total: total ?? this.total,
    );
  }
}

/// Internal structure for list type information
@JsonSerializable()
class ListTypeInfo {
  final int id;
  final String uuid;
  final String type;

  const ListTypeInfo({
    required this.id,
    required this.uuid,
    required this.type,
  });

  factory ListTypeInfo.fromJson(Map<String, dynamic> json) => 
      _$ListTypeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ListTypeInfoToJson(this);
}