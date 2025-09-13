# Listmonk Dart

A Dart package providing core listmonk functionality for subscriber and campaign management. This package translates the core backend logic from the original Go implementation to Dart, designed to work with MongoDB instead of PostgreSQL.

## Features

- **Subscriber Management**: Create, update, delete, and query subscribers
- **Campaign Management**: Create, schedule, and manage email campaigns
- **List Management**: Manage mailing lists with opt-in/opt-out functionality
- **Template Management**: Handle email templates
- **Analytics**: Track campaign views, clicks, and bounces
- **MongoDB Integration**: Built for MongoDB instead of PostgreSQL

## Core Components

### Models
- `Subscriber`: Email subscriber with attributes and list subscriptions
- `Campaign`: Email campaign with content and metadata
- `List`: Mailing list with opt-in settings
- `Template`: Reusable email templates
- `Bounce`: Bounce tracking and management

### Services
- `SubscriberService`: CRUD operations for subscribers
- `CampaignService`: Campaign management and sending
- `ListService`: List management operations
- `TemplateService`: Template management
- `AnalyticsService`: Campaign analytics and tracking

## Usage

```dart
import 'package:listmonk_dart/listmonk_dart.dart';

// Initialize the core service
final core = ListmonkCore(
  mongoUri: 'mongodb://localhost:27017/listmonk',
);

// Create a subscriber
final subscriber = Subscriber(
  email: 'user@example.com',
  name: 'John Doe',
  status: SubscriberStatus.enabled,
  attribs: {'company': 'Acme Corp'},
);

await core.subscriberService.createSubscriber(subscriber, listIds: [1, 2]);

// Create a campaign
final campaign = Campaign(
  name: 'Welcome Campaign',
  subject: 'Welcome to our newsletter!',
  fromEmail: 'noreply@example.com',
  body: '<h1>Welcome!</h1>',
  contentType: CampaignContentType.html,
  listIds: [1, 2],
);

await core.campaignService.createCampaign(campaign);
```

## Database Schema

This package uses MongoDB collections instead of PostgreSQL tables:

- `subscribers`: Subscriber data and attributes
- `campaigns`: Campaign information and content
- `lists`: Mailing list definitions
- `templates`: Email templates
- `bounces`: Bounce tracking data
- `campaign_views`: Campaign view analytics
- `link_clicks`: Link click tracking
- `subscriptions`: Subscriber-list relationships

## Status Constants

The package includes all the status constants from the original implementation:

- **Subscriber Status**: `enabled`, `disabled`, `blocklisted`
- **Subscription Status**: `unconfirmed`, `confirmed`, `unsubscribed`
- **Campaign Status**: `draft`, `scheduled`, `running`, `paused`, `finished`, `cancelled`
- **Campaign Types**: `regular`, `optin`
- **Content Types**: `richtext`, `html`, `markdown`, `plain`, `visual`
- **List Types**: `private`, `public`
- **Opt-in Types**: `single`, `double`