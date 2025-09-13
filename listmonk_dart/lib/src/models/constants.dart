/// Enum values for various statuses and types used throughout the application

/// Subscriber status constants
class SubscriberStatus {
  static const String enabled = 'enabled';
  static const String disabled = 'disabled';
  static const String blocklisted = 'blocklisted';
}

/// Subscription status constants
class SubscriptionStatus {
  static const String unconfirmed = 'unconfirmed';
  static const String confirmed = 'confirmed';
  static const String unsubscribed = 'unsubscribed';
}

/// Campaign status constants
class CampaignStatus {
  static const String draft = 'draft';
  static const String scheduled = 'scheduled';
  static const String running = 'running';
  static const String paused = 'paused';
  static const String finished = 'finished';
  static const String cancelled = 'cancelled';
}

/// Campaign type constants
class CampaignType {
  static const String regular = 'regular';
  static const String optin = 'optin';
}

/// Campaign content type constants
class CampaignContentType {
  static const String richtext = 'richtext';
  static const String html = 'html';
  static const String markdown = 'markdown';
  static const String plain = 'plain';
  static const String visual = 'visual';
}

/// List type constants
class ListType {
  static const String private = 'private';
  static const String public = 'public';
}

/// List opt-in type constants
class ListOptin {
  static const String single = 'single';
  static const String double = 'double';
}

/// Bounce type constants
class BounceType {
  static const String hard = 'hard';
  static const String soft = 'soft';
  static const String complaint = 'complaint';
}

/// Template type constants
class TemplateType {
  static const String campaign = 'campaign';
  static const String campaignVisual = 'campaign_visual';
  static const String tx = 'tx';
}

/// Base template names
class BaseTemplate {
  static const String base = 'base';
  static const String content = 'content';
}

/// Email header constants
class EmailHeader {
  static const String subscriberUuid = 'X-Listmonk-Subscriber';
  static const String campaignUuid = 'X-Listmonk-Campaign';
  static const String date = 'Date';
  static const String from = 'From';
  static const String subject = 'Subject';
  static const String messageId = 'Message-Id';
  static const String deliveredTo = 'Delivered-To';
  static const String received = 'Received';
}

/// Campaign analytics types
class CampaignAnalytics {
  static const String views = 'views';
  static const String clicks = 'clicks';
  static const String bounces = 'bounces';
}

/// Sort order constants
class SortOrder {
  static const String asc = 'asc';
  static const String desc = 'desc';
}