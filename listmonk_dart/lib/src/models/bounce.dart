import 'package:json_annotation/json_annotation.dart';
import 'base.dart';
import 'constants.dart';

part 'bounce.g.dart';

/// Represents a single bounce event
@JsonSerializable()
class Bounce extends Base {
  final String type;
  final String source;
  final JsonMap meta;
  final String? email;
  @JsonKey(name: 'subscriber_uuid')
  final String? subscriberUuid;
  @JsonKey(name: 'subscriber_id')
  final int? subscriberId;
  @JsonKey(name: 'subscriber_status')
  final String subscriberStatus;
  @JsonKey(name: 'campaign_uuid')
  final String? campaignUuid;
  final JsonMap? campaign;
  final int total;

  const Bounce({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.type,
    required this.source,
    required this.meta,
    this.email,
    this.subscriberUuid,
    this.subscriberId,
    required this.subscriberStatus,
    this.campaignUuid,
    this.campaign,
    required this.total,
  });

  factory Bounce.fromJson(Map<String, dynamic> json) => 
      _$BounceFromJson(json);
  Map<String, dynamic> toJson() => _$BounceToJson(this);

  /// Creates a copy with updated fields
  Bounce copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    String? source,
    JsonMap? meta,
    String? email,
    String? subscriberUuid,
    int? subscriberId,
    String? subscriberStatus,
    String? campaignUuid,
    JsonMap? campaign,
    int? total,
  }) {
    return Bounce(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      source: source ?? this.source,
      meta: meta ?? this.meta,
      email: email ?? this.email,
      subscriberUuid: subscriberUuid ?? this.subscriberUuid,
      subscriberId: subscriberId ?? this.subscriberId,
      subscriberStatus: subscriberStatus ?? this.subscriberStatus,
      campaignUuid: campaignUuid ?? this.campaignUuid,
      campaign: campaign ?? this.campaign,
      total: total ?? this.total,
    );
  }
}