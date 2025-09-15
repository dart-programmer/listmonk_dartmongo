import 'package:json_annotation/json_annotation.dart';
import 'subscriber.dart';
import 'campaign.dart';

part 'message.g.dart';

/// Represents a message pushed to a Messenger
@JsonSerializable()
class Message {
  final String from;
  final List<String> to;
  final String subject;
  @JsonKey(name: 'content_type')
  final String contentType;
  final List<int> body;
  @JsonKey(name: 'alt_body')
  final List<int> altBody;
  final Map<String, String> headers;
  final List<Attachment> attachments;
  final Subscriber subscriber;
  final Campaign? campaign;
  final String messenger;

  const Message({
    required this.from,
    required this.to,
    required this.subject,
    required this.contentType,
    required this.body,
    required this.altBody,
    required this.headers,
    required this.attachments,
    required this.subscriber,
    this.campaign,
    required this.messenger,
  });

  factory Message.fromJson(Map<String, dynamic> json) => 
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

/// Represents a transactional email message
@JsonSerializable()
class TxMessage {
  @JsonKey(name: 'subscriber_emails')
  final List<String> subscriberEmails;
  @JsonKey(name: 'subscriber_ids')
  final List<int> subscriberIds;
  @JsonKey(name: 'subscriber_email')
  final String? subscriberEmail; // Deprecated
  @JsonKey(name: 'subscriber_id')
  final int? subscriberId; // Deprecated
  @JsonKey(name: 'template_id')
  final int templateId;
  final Map<String, dynamic> data;
  @JsonKey(name: 'from_email')
  final String fromEmail;
  final List<Map<String, String>> headers;
  @JsonKey(name: 'content_type')
  final String contentType;
  final String messenger;
  final String subject;
  final List<Attachment> attachments;
  final List<int> body;

  const TxMessage({
    required this.subscriberEmails,
    required this.subscriberIds,
    this.subscriberEmail,
    this.subscriberId,
    required this.templateId,
    required this.data,
    required this.fromEmail,
    required this.headers,
    required this.contentType,
    required this.messenger,
    required this.subject,
    required this.attachments,
    required this.body,
  });

  factory TxMessage.fromJson(Map<String, dynamic> json) => 
      _$TxMessageFromJson(json);
  Map<String, dynamic> toJson() => _$TxMessageToJson(this);
}