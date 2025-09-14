import 'package:mongo_dart/mongo_dart.dart';
import 'logger.dart';

/// Database index management utility
class DatabaseIndexes {
  final Db _db;

  DatabaseIndexes(this._db);

  /// Create all necessary indexes for optimal performance
  Future<void> createAllIndexes() async {
    Logger.info('Creating database indexes...');
    
    await _createSubscriberIndexes();
    await _createCampaignIndexes();
    await _createListIndexes();
    await _createTemplateIndexes();
    await _createBounceIndexes();
    await _createAnalyticsIndexes();
    await _createSubscriptionIndexes();
    
    Logger.info('Database indexes created successfully');
  }

  /// Create subscriber collection indexes
  Future<void> _createSubscriberIndexes() async {
    final collection = _db.collection('subscribers');
    
    // Unique email index
    await collection.createIndex({'email': 1}, unique: true);
    Logger.db('Created unique index on subscribers.email');
    
    // UUID index
    await collection.createIndex({'uuid': 1}, unique: true);
    Logger.db('Created unique index on subscribers.uuid');
    
    // Status index
    await collection.createIndex({'status': 1});
    Logger.db('Created index on subscribers.status');
    
    // Created at index
    await collection.createIndex({'created_at': 1});
    Logger.db('Created index on subscribers.created_at');
    
    // Compound index for queries
    await collection.createIndex({'status': 1, 'created_at': -1});
    Logger.db('Created compound index on subscribers.status and created_at');
  }

  /// Create campaign collection indexes
  Future<void> _createCampaignIndexes() async {
    final collection = _db.collection('campaigns');
    
    // UUID index
    await collection.createIndex({'uuid': 1}, unique: true);
    Logger.db('Created unique index on campaigns.uuid');
    
    // Status index
    await collection.createIndex({'status': 1});
    Logger.db('Created index on campaigns.status');
    
    // Type index
    await collection.createIndex({'type': 1});
    Logger.db('Created index on campaigns.type');
    
    // Created at index
    await collection.createIndex({'created_at': 1});
    Logger.db('Created index on campaigns.created_at');
    
    // Send at index
    await collection.createIndex({'send_at': 1});
    Logger.db('Created index on campaigns.send_at');
    
    // Archive slug index
    await collection.createIndex({'archive_slug': 1}, unique: true, sparse: true);
    Logger.db('Created unique sparse index on campaigns.archive_slug');
    
    // Compound index for status and send_at
    await collection.createIndex({'status': 1, 'send_at': 1});
    Logger.db('Created compound index on campaigns.status and send_at');
  }

  /// Create list collection indexes
  Future<void> _createListIndexes() async {
    final collection = _db.collection('lists');
    
    // UUID index
    await collection.createIndex({'uuid': 1}, unique: true);
    Logger.db('Created unique index on lists.uuid');
    
    // Type index
    await collection.createIndex({'type': 1});
    Logger.db('Created index on lists.type');
    
    // Optin index
    await collection.createIndex({'optin': 1});
    Logger.db('Created index on lists.optin');
    
    // Created at index
    await collection.createIndex({'created_at': 1});
    Logger.db('Created index on lists.created_at');
  }

  /// Create template collection indexes
  Future<void> _createTemplateIndexes() async {
    final collection = _db.collection('templates');
    
    // Type index
    await collection.createIndex({'type': 1});
    Logger.db('Created index on templates.type');
    
    // Is default index
    await collection.createIndex({'is_default': 1});
    Logger.db('Created index on templates.is_default');
    
    // Name index
    await collection.createIndex({'name': 1});
    Logger.db('Created index on templates.name');
  }

  /// Create bounce collection indexes
  Future<void> _createBounceIndexes() async {
    final collection = _db.collection('bounces');
    
    // Email index
    await collection.createIndex({'email': 1});
    Logger.db('Created index on bounces.email');
    
    // Subscriber UUID index
    await collection.createIndex({'subscriber_uuid': 1});
    Logger.db('Created index on bounces.subscriber_uuid');
    
    // Campaign UUID index
    await collection.createIndex({'campaign_uuid': 1});
    Logger.db('Created index on bounces.campaign_uuid');
    
    // Type index
    await collection.createIndex({'type': 1});
    Logger.db('Created index on bounces.type');
    
    // Created at index
    await collection.createIndex({'created_at': 1});
    Logger.db('Created index on bounces.created_at');
  }

  /// Create analytics collection indexes
  Future<void> _createAnalyticsIndexes() async {
    // Campaign views indexes
    final viewsCollection = _db.collection('campaign_views');
    await viewsCollection.createIndex({'campaign_uuid': 1});
    await viewsCollection.createIndex({'subscriber_uuid': 1});
    await viewsCollection.createIndex({'created_at': 1});
    await viewsCollection.createIndex({'campaign_uuid': 1, 'created_at': 1});
    Logger.db('Created indexes on campaign_views');
    
    // Link clicks indexes
    final clicksCollection = _db.collection('link_clicks');
    await clicksCollection.createIndex({'campaign_uuid': 1});
    await clicksCollection.createIndex({'subscriber_uuid': 1});
    await clicksCollection.createIndex({'link_uuid': 1});
    await clicksCollection.createIndex({'created_at': 1});
    await clicksCollection.createIndex({'campaign_uuid': 1, 'created_at': 1});
    Logger.db('Created indexes on link_clicks');
  }

  /// Create subscription collection indexes
  Future<void> _createSubscriptionIndexes() async {
    final collection = _db.collection('subscriptions');
    
    // Subscriber ID index
    await collection.createIndex({'subscriber_id': 1});
    Logger.db('Created index on subscriptions.subscriber_id');
    
    // List ID index
    await collection.createIndex({'list_id': 1});
    Logger.db('Created index on subscriptions.list_id');
    
    // Subscriber UUID index
    await collection.createIndex({'subscriber_uuid': 1});
    Logger.db('Created index on subscriptions.subscriber_uuid');
    
    // List UUID index
    await collection.createIndex({'list_uuid': 1});
    Logger.db('Created index on subscriptions.list_uuid');
    
    // Status index
    await collection.createIndex({'subscription_status': 1});
    Logger.db('Created index on subscriptions.subscription_status');
    
    // Compound index for subscriber and list
    await collection.createIndex({'subscriber_id': 1, 'list_id': 1}, unique: true);
    Logger.db('Created unique compound index on subscriptions.subscriber_id and list_id');
    
    // Compound index for subscriber UUID and list UUID
    await collection.createIndex({'subscriber_uuid': 1, 'list_uuid': 1}, unique: true);
    Logger.db('Created unique compound index on subscriptions.subscriber_uuid and list_uuid');
  }

  /// Drop all indexes (use with caution)
  Future<void> dropAllIndexes() async {
    Logger.warning('Dropping all database indexes...');
    
    final collections = ['subscribers', 'campaigns', 'lists', 'templates', 'bounces', 'campaign_views', 'link_clicks', 'subscriptions'];
    
    for (final collectionName in collections) {
      try {
        await _db.collection(collectionName).dropIndexes();
        Logger.db('Dropped indexes for collection: $collectionName');
      } catch (e) {
        Logger.warning('Failed to drop indexes for $collectionName: $e');
      }
    }
    
    Logger.info('All indexes dropped');
  }

  /// Get index information for a collection
  Future<List<Map<String, dynamic>>> getIndexes(String collectionName) async {
    try {
      final result = await _db.collection(collectionName).getIndexes();
      return result;
    } catch (e) {
      Logger.error('Failed to get indexes for $collectionName: $e');
      return [];
    }
  }
}