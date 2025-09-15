import 'package:json_annotation/json_annotation.dart';
import 'base.dart';
import 'constants.dart';

part 'campaign.g.dart';

/// Represents an email campaign
@JsonSerializable()
class Campaign extends Base {
  final String uuid;
  final String type;
  final String name;
  final String subject;
  @JsonKey(name: 'from_email')
  final String fromEmail;
  final String body;
  @JsonKey(name: 'body_source')
  final String? bodySource;
  final String? altBody;
  @JsonKey(name: 'send_at')
  final DateTime? sendAt;
  final String status;
  @JsonKey(name: 'content_type')
  final String contentType;
  final List<String> tags;
  final Headers headers;
  @JsonKey(name: 'template_id')
  final int? templateId;
  final String messenger;
  final bool archive;
  @JsonKey(name: 'archive_slug')
  final String? archiveSlug;
  @JsonKey(name: 'archive_template_id')
  final int? archiveTemplateId;
  @JsonKey(name: 'archive_meta')
  final JsonMap archiveMeta;
  @JsonKey(name: 'template_body')
  final String? templateBody;
  @JsonKey(name: 'archive_template_body')
  final String? archiveTemplateBody;
  @JsonKey(name: 'media_id')
  final List<int> mediaIds;
  final List<Attachment> attachments;
  final CampaignMeta meta;
  final int total;

  const Campaign({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.uuid,
    required this.type,
    required this.name,
    required this.subject,
    required this.fromEmail,
    required this.body,
    this.bodySource,
    this.altBody,
    this.sendAt,
    required this.status,
    required this.contentType,
    required this.tags,
    required this.headers,
    this.templateId,
    required this.messenger,
    required this.archive,
    this.archiveSlug,
    this.archiveTemplateId,
    required this.archiveMeta,
    this.templateBody,
    this.archiveTemplateBody,
    required this.mediaIds,
    required this.attachments,
    required this.meta,
    required this.total,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => 
      _$CampaignFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignToJson(this);

  /// Creates a copy with updated fields
  Campaign copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uuid,
    String? type,
    String? name,
    String? subject,
    String? fromEmail,
    String? body,
    String? bodySource,
    String? altBody,
    DateTime? sendAt,
    String? status,
    String? contentType,
    List<String>? tags,
    Headers? headers,
    int? templateId,
    String? messenger,
    bool? archive,
    String? archiveSlug,
    int? archiveTemplateId,
    JsonMap? archiveMeta,
    String? templateBody,
    String? archiveTemplateBody,
    List<int>? mediaIds,
    List<Attachment>? attachments,
    CampaignMeta? meta,
    int? total,
  }) {
    return Campaign(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      fromEmail: fromEmail ?? this.fromEmail,
      body: body ?? this.body,
      bodySource: bodySource ?? this.bodySource,
      altBody: altBody ?? this.altBody,
      sendAt: sendAt ?? this.sendAt,
      status: status ?? this.status,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      headers: headers ?? this.headers,
      templateId: templateId ?? this.templateId,
      messenger: messenger ?? this.messenger,
      archive: archive ?? this.archive,
      archiveSlug: archiveSlug ?? this.archiveSlug,
      archiveTemplateId: archiveTemplateId ?? this.archiveTemplateId,
      archiveMeta: archiveMeta ?? this.archiveMeta,
      templateBody: templateBody ?? this.templateBody,
      archiveTemplateBody: archiveTemplateBody ?? this.archiveTemplateBody,
      mediaIds: mediaIds ?? this.mediaIds,
      attachments: attachments ?? this.attachments,
      meta: meta ?? this.meta,
      total: total ?? this.total,
    );
  }
}

/// Contains fields tracking a campaign's progress
@JsonSerializable()
class CampaignMeta {
  @JsonKey(name: 'campaign_id')
  final int campaignId;
  final int views;
  final int clicks;
  final int bounces;
  final List<CampaignListInfo> lists;
  final List<MediaInfo> media;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'to_send')
  final int toSend;
  final int sent;

  const CampaignMeta({
    required this.campaignId,
    required this.views,
    required this.clicks,
    required this.bounces,
    required this.lists,
    required this.media,
    this.startedAt,
    required this.toSend,
    required this.sent,
  });

  factory CampaignMeta.fromJson(Map<String, dynamic> json) => 
      _$CampaignMetaFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignMetaToJson(this);
}

/// Campaign list information for historical records
@JsonSerializable()
class CampaignListInfo {
  @JsonKey(name: 'list_id')
  final int listId;
  final String name;

  const CampaignListInfo({
    required this.listId,
    required this.name,
  });

  factory CampaignListInfo.fromJson(Map<String, dynamic> json) => 
      _$CampaignListInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignListInfoToJson(this);
}

/// Media information for campaigns
@JsonSerializable()
class MediaInfo {
  final int id;
  final String name;
  final String filename;
  final String contentType;
  final int size;
  final String url;

  const MediaInfo({
    required this.id,
    required this.name,
    required this.filename,
    required this.contentType,
    required this.size,
    required this.url,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) => 
      _$MediaInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MediaInfoToJson(this);
}

/// Campaign statistics
@JsonSerializable()
class CampaignStats {
  final int id;
  final String status;
  @JsonKey(name: 'to_send')
  final int toSend;
  final int sent;
  final DateTime? started;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final int rate;
  @JsonKey(name: 'net_rate')
  final int netRate;

  const CampaignStats({
    required this.id,
    required this.status,
    required this.toSend,
    required this.sent,
    this.started,
    this.updatedAt,
    required this.rate,
    required this.netRate,
  });

  factory CampaignStats.fromJson(Map<String, dynamic> json) => 
      _$CampaignStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignStatsToJson(this);
}

/// Campaign analytics count data
@JsonSerializable()
class CampaignAnalyticsCount {
  @JsonKey(name: 'campaign_id')
  final int campaignId;
  final int count;
  final DateTime timestamp;

  const CampaignAnalyticsCount({
    required this.campaignId,
    required this.count,
    required this.timestamp,
  });

  factory CampaignAnalyticsCount.fromJson(Map<String, dynamic> json) => 
      _$CampaignAnalyticsCountFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignAnalyticsCountToJson(this);
}

/// Campaign analytics link data
@JsonSerializable()
class CampaignAnalyticsLink {
  final String url;
  final int count;

  const CampaignAnalyticsLink({
    required this.url,
    required this.count,
  });

  factory CampaignAnalyticsLink.fromJson(Map<String, dynamic> json) => 
      _$CampaignAnalyticsLinkFromJson(json);
  Map<String, dynamic> toJson() => _$CampaignAnalyticsLinkToJson(this);
}

/// File attachment for messages
@JsonSerializable()
class Attachment {
  final String name;
  final Map<String, String> header;
  final List<int> content;

  const Attachment({
    required this.name,
    required this.header,
    required this.content,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => 
      _$AttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}