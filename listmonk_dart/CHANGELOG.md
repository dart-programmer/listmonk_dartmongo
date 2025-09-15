# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release of Listmonk Dart package
- Core models for subscribers, campaigns, lists, templates, and bounces
- Service classes for CRUD operations
- MongoDB integration instead of PostgreSQL
- Comprehensive example usage
- Unit tests for core functionality
- Full translation of Go backend logic to Dart

### Features
- **Subscriber Management**: Create, read, update, delete subscribers with attributes and list subscriptions
- **Campaign Management**: Create, schedule, and manage email campaigns with analytics
- **List Management**: Manage mailing lists with opt-in/opt-out functionality
- **Template Management**: Handle reusable email templates
- **Analytics**: Track campaign views, clicks, and bounces
- **MongoDB Support**: Built specifically for MongoDB collections

### Models
- `Subscriber`: Email subscriber with attributes and list subscriptions
- `Campaign`: Email campaign with content and metadata
- `List`: Mailing list with opt-in settings
- `Template`: Reusable email templates
- `Bounce`: Bounce tracking and management
- `Message`: Message structure for email sending
- `TxMessage`: Transactional message structure

### Services
- `SubscriberService`: CRUD operations for subscribers
- `CampaignService`: Campaign management and sending
- `ListService`: List management operations
- `TemplateService`: Template management
- `AnalyticsService`: Campaign analytics and tracking

### Constants
- All status constants from original Go implementation
- Campaign types, content types, and list types
- Email headers and template names