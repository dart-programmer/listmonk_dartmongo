import 'package:mongo_dart/mongo_dart.dart';
import '../models/template.dart';
import '../models/constants.dart';

/// Service for managing email templates
class TemplateService {
  final Db _db;

  TemplateService(this._db);

  /// Get all templates
  Future<List<Template>> getTemplates() async {
    final cursor = _db.collection('templates').find({}).sort({'name': 1});
    
    final templates = <Template>[];
    await for (final doc in cursor) {
      templates.add(Template.fromJson(doc));
    }

    return templates;
  }

  /// Get a template by ID
  Future<Template?> getTemplate(int id) async {
    final doc = await _db.collection('templates').findOne({'id': id});
    if (doc == null) return null;

    return Template.fromJson(doc);
  }

  /// Create a new template
  Future<Template> createTemplate(Template template) async {
    final now = DateTime.now();

    final newTemplate = template.copyWith(
      createdAt: now,
      updatedAt: now,
    );

    // Insert template
    final result = await _db.collection('templates').insertOne({
      ...newTemplate.toJson(),
      'id': null, // Will be set by MongoDB
    });

    final templateId = result.id;

    // Get the created template
    final createdTemplate = await getTemplate(templateId);
    if (createdTemplate == null) {
      throw Exception('Failed to create template');
    }

    return createdTemplate;
  }

  /// Update a template
  Future<Template> updateTemplate(int id, Template template) async {
    final now = DateTime.now();
    
    await _db.collection('templates').updateOne(
      {'id': id},
      {
        '\$set': {
          'name': template.name,
          'subject': template.subject,
          'type': template.type,
          'body': template.body,
          'body_source': template.bodySource,
          'is_default': template.isDefault,
          'updated_at': now,
        }
      },
    );

    final updatedTemplate = await getTemplate(id);
    if (updatedTemplate == null) {
      throw Exception('Template not found');
    }

    return updatedTemplate;
  }

  /// Set a template as default
  Future<void> setDefaultTemplate(int id) async {
    // First, unset all other defaults
    await _db.collection('templates').updateMany(
      {'is_default': true},
      {'\$set': {'is_default': false}},
    );

    // Set this template as default
    await _db.collection('templates').updateOne(
      {'id': id},
      {'\$set': {'is_default': true}},
    );
  }

  /// Delete a template
  Future<void> deleteTemplate(int id) async {
    final result = await _db.collection('templates').deleteOne({'id': id});
    if (result.n == 0) {
      throw Exception('Template not found');
    }
  }

  /// Get default template
  Future<Template?> getDefaultTemplate() async {
    final doc = await _db.collection('templates').findOne({'is_default': true});
    if (doc == null) return null;

    return Template.fromJson(doc);
  }

  /// Get templates by type
  Future<List<Template>> getTemplatesByType(String type) async {
    final cursor = _db.collection('templates')
        .find({'type': type})
        .sort({'name': 1});
    
    final templates = <Template>[];
    await for (final doc in cursor) {
      templates.add(Template.fromJson(doc));
    }

    return templates;
  }
}