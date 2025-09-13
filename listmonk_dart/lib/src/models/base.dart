import 'package:json_annotation/json_annotation.dart';

part 'base.g.dart';

/// Base model with common fields shared across all models
@JsonSerializable()
class Base {
  final int? id;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Base({
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  factory Base.fromJson(Map<String, dynamic> json) => _$BaseFromJson(json);
  Map<String, dynamic> toJson() => _$BaseToJson(this);
}

/// Generic paginated results container
@JsonSerializable()
class PageResults<T> {
  final List<T> results;
  final String search;
  final String query;
  final int total;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int page;

  const PageResults({
    required this.results,
    required this.search,
    required this.query,
    required this.total,
    required this.perPage,
    required this.page,
  });

  factory PageResults.fromJson(Map<String, dynamic> json) => 
      _$PageResultsFromJson(json);
  Map<String, dynamic> toJson() => _$PageResultsToJson(this);
}

/// JSON wrapper for arbitrary JSONB fields
typedef JsonMap = Map<String, dynamic>;

/// String to int map for DB operations
typedef StringIntMap = Map<String, int>;

/// Headers represents an array of string maps used for SMTP, HTTP headers etc.
typedef Headers = List<Map<String, String>>;