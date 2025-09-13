import 'package:json_annotation/json_annotation.dart';
import 'base.dart';
import 'constants.dart';

part 'template.g.dart';

/// Represents a reusable email template
@JsonSerializable()
class Template extends Base {
  final String name;
  final String subject;
  final String type;
  final String body;
  @JsonKey(name: 'body_source')
  final String? bodySource;
  @JsonKey(name: 'is_default')
  final bool isDefault;

  const Template({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.name,
    required this.subject,
    required this.type,
    required this.body,
    this.bodySource,
    required this.isDefault,
  });

  factory Template.fromJson(Map<String, dynamic> json) => 
      _$TemplateFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateToJson(this);

  /// Creates a copy with updated fields
  Template copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? subject,
    String? type,
    String? body,
    String? bodySource,
    bool? isDefault,
  }) {
    return Template(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      body: body ?? this.body,
      bodySource: bodySource ?? this.bodySource,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}