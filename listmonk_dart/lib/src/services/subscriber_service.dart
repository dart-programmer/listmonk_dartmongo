import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import '../models/subscriber.dart';
import '../models/list.dart';
import '../models/constants.dart';
import '../core/listmonk_core.dart';

/// Service for managing subscribers
class SubscriberService {
  final Db _db;
  final Uuid _uuid = const Uuid();

  SubscriberService(this._db);

  /// Get a subscriber by ID, UUID, or email
  Future<Subscriber?> getSubscriber({
    int? id,
    String? uuid,
    String? email,
  }) async {
    final query = <String, dynamic>{};
    
    if (id != null) {
      query['id'] = id;
    } else if (uuid != null) {
      query['uuid'] = uuid;
    } else if (email != null) {
      query['email'] = email;
    } else {
      throw ArgumentError('At least one of id, uuid, or email must be provided');
    }

    final subscriberDoc = await _db.collection('subscribers').findOne(query);
    if (subscriberDoc == null) return null;

    final subscriber = Subscriber.fromJson(subscriberDoc);
    final lists = await _getSubscriberLists(subscriber.id!);
    
    return subscriber.copyWith(lists: lists);
  }

  /// Get subscribers by email addresses
  Future<List<Subscriber>> getSubscribersByEmail(List<String> emails) async {
    final cursor = _db.collection('subscribers').find({
      'email': {'\$in': emails}
    });

    final subscribers = <Subscriber>[];
    await for (final doc in cursor) {
      final subscriber = Subscriber.fromJson(doc);
      final lists = await _getSubscriberLists(subscriber.id!);
      subscribers.add(subscriber.copyWith(lists: lists));
    }

    return subscribers;
  }

  /// Query subscribers with pagination and filtering
  Future<PageResults<Subscriber>> querySubscribers({
    String? searchStr,
    String? queryExp,
    List<int>? listIds,
    String? subStatus,
    String orderBy = 'id',
    String order = SortOrder.desc,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{};
    
    // Apply status filter
    if (subStatus != null) {
      query['status'] = subStatus;
    }

    // Apply list filter
    if (listIds != null && listIds.isNotEmpty) {
      query['lists.listId'] = {'\$in': listIds};
    }

    // Apply search filter
    if (searchStr != null && searchStr.isNotEmpty) {
      query['\$or'] = [
        {'email': {'\$regex': searchStr, '\$options': 'i'}},
        {'name': {'\$regex': searchStr, '\$options': 'i'}},
      ];
    }

    // Apply custom query expression
    if (queryExp != null && queryExp.isNotEmpty) {
      // This would need to be parsed and converted to MongoDB query
      // For now, we'll skip this complex feature
    }

    final total = await _db.collection('subscribers').count(query);
    
    final cursor = _db.collection('subscribers')
        .find(query)
        .sort({orderBy: order == SortOrder.asc ? 1 : -1})
        .skip(offset)
        .limit(limit);

    final subscribers = <Subscriber>[];
    await for (final doc in cursor) {
      final subscriber = Subscriber.fromJson(doc);
      final lists = await _getSubscriberLists(subscriber.id!);
      subscribers.add(subscriber.copyWith(lists: lists));
    }

    return PageResults<Subscriber>(
      results: subscribers,
      search: searchStr ?? '',
      query: queryExp ?? '',
      total: total,
      perPage: limit,
      page: (offset / limit).floor() + 1,
    );
  }

  /// Create a new subscriber
  Future<Subscriber> createSubscriber(
    Subscriber subscriber, {
    List<int>? listIds,
    List<String>? listUuids,
    bool preconfirm = false,
    bool assertOptin = false,
  }) async {
    final uuid = _uuid.v4();
    final now = DateTime.now();
    
    final subStatus = preconfirm 
        ? SubscriptionStatus.confirmed 
        : SubscriptionStatus.unconfirmed;

    final newSubscriber = subscriber.copyWith(
      uuid: uuid,
      status: subscriber.status.isEmpty ? SubscriberStatus.enabled : subscriber.status,
      createdAt: now,
      updatedAt: now,
    );

    // Insert subscriber
    final result = await _db.collection('subscribers').insertOne({
      ...newSubscriber.toJson(),
      'id': null, // Will be set by MongoDB
    });

    final subscriberId = result.id;
    
    // Add to lists if provided
    if (listIds != null && listIds.isNotEmpty) {
      await _addSubscriberToLists(subscriberId, listIds, subStatus);
    }

    // Get the created subscriber with lists
    final createdSubscriber = await getSubscriber(id: subscriberId);
    if (createdSubscriber == null) {
      throw Exception('Failed to create subscriber');
    }

    return createdSubscriber;
  }

  /// Update a subscriber
  Future<Subscriber> updateSubscriber(int id, Subscriber subscriber) async {
    final now = DateTime.now();
    
    await _db.collection('subscribers').updateOne(
      {'id': id},
      {
        '\$set': {
          'email': subscriber.email,
          'name': subscriber.name.trim(),
          'status': subscriber.status,
          'attribs': subscriber.attribs,
          'updated_at': now,
        }
      },
    );

    final updatedSubscriber = await getSubscriber(id: id);
    if (updatedSubscriber == null) {
      throw Exception('Subscriber not found');
    }

    return updatedSubscriber;
  }

  /// Update subscriber with lists
  Future<Subscriber> updateSubscriberWithLists(
    int id,
    Subscriber subscriber, {
    List<int>? listIds,
    List<String>? listUuids,
    bool preconfirm = false,
    bool deleteLists = false,
    bool assertOptin = false,
  }) async {
    final now = DateTime.now();
    final subStatus = preconfirm 
        ? SubscriptionStatus.confirmed 
        : SubscriptionStatus.unconfirmed;

    // Update subscriber
    await _db.collection('subscribers').updateOne(
      {'id': id},
      {
        '\$set': {
          'email': subscriber.email,
          'name': subscriber.name.trim(),
          'status': subscriber.status,
          'attribs': subscriber.attribs,
          'updated_at': now,
        }
      },
    );

    // Handle list subscriptions
    if (deleteLists) {
      await _db.collection('subscriptions').deleteMany({'subscriber_id': id});
    }

    if (listIds != null && listIds.isNotEmpty) {
      await _addSubscriberToLists(id, listIds, subStatus);
    }

    final updatedSubscriber = await getSubscriber(id: id);
    if (updatedSubscriber == null) {
      throw Exception('Subscriber not found');
    }

    return updatedSubscriber;
  }

  /// Blocklist subscribers
  Future<void> blocklistSubscribers(List<int> subIds) async {
    await _db.collection('subscribers').updateMany(
      {'id': {'\$in': subIds}},
      {'\$set': {'status': SubscriberStatus.blocklisted}},
    );
  }

  /// Delete subscribers
  Future<void> deleteSubscribers({
    List<int>? subIds,
    List<String>? subUuids,
  }) async {
    final query = <String, dynamic>{};
    
    if (subIds != null && subIds.isNotEmpty) {
      query['id'] = {'\$in': subIds};
    }
    if (subUuids != null && subUuids.isNotEmpty) {
      query['uuid'] = {'\$in': subUuids};
    }

    if (query.isNotEmpty) {
      await _db.collection('subscribers').deleteMany(query);
      await _db.collection('subscriptions').deleteMany(query);
    }
  }

  /// Unsubscribe by campaign
  Future<void> unsubscribeByCampaign(
    String subUuid,
    String campUuid, {
    bool blocklist = false,
  }) async {
    // Get campaign lists
    final campaign = await _db.collection('campaigns').findOne({'uuid': campUuid});
    if (campaign == null) return;

    final listIds = List<int>.from(campaign['lists'] ?? []);

    // Update subscription status
    await _db.collection('subscriptions').updateMany(
      {
        'subscriber_uuid': subUuid,
        'list_id': {'\$in': listIds},
      },
      {'\$set': {'subscription_status': SubscriptionStatus.unsubscribed}},
    );

    // Blocklist if requested
    if (blocklist) {
      await _db.collection('subscribers').updateOne(
        {'uuid': subUuid},
        {'\$set': {'status': SubscriberStatus.blocklisted}},
      );
    }
  }

  /// Confirm opt-in subscription
  Future<void> confirmOptinSubscription(
    String subUuid,
    List<String> listUuids, {
    Map<String, dynamic>? meta,
  }) async {
    await _db.collection('subscriptions').updateMany(
      {
        'subscriber_uuid': subUuid,
        'list_uuid': {'\$in': listUuids},
      },
      {
        '\$set': {
          'subscription_status': SubscriptionStatus.confirmed,
          'meta': meta ?? {},
        }
      },
    );
  }

  /// Get subscriber lists
  Future<List<Subscription>> _getSubscriberLists(int subscriberId) async {
    final cursor = _db.collection('subscriptions').find({'subscriber_id': subscriberId});
    
    final subscriptions = <Subscription>[];
    await for (final doc in cursor) {
      subscriptions.add(Subscription.fromJson(doc));
    }

    return subscriptions;
  }

  /// Add subscriber to lists
  Future<void> _addSubscriberToLists(int subscriberId, List<int> listIds, String status) async {
    final subscriptions = listIds.map((listId) => {
      'subscriber_id': subscriberId,
      'list_id': listId,
      'subscription_status': status,
      'created_at': DateTime.now(),
    }).toList();

    await _db.collection('subscriptions').insertMany(subscriptions);
  }

  /// Export subscriber data
  Future<SubscriberExportProfile> getSubscriberProfileForExport({
    int? id,
    String? uuid,
  }) async {
    final subscriber = await getSubscriber(id: id, uuid: uuid);
    if (subscriber == null) {
      throw Exception('Subscriber not found');
    }

    // Get campaign views
    final campaignViews = await _db.collection('campaign_views')
        .find({'subscriber_id': subscriber.id})
        .toList();

    // Get link clicks
    final linkClicks = await _db.collection('link_clicks')
        .find({'subscriber_id': subscriber.id})
        .toList();

    return SubscriberExportProfile(
      email: subscriber.email,
      profile: subscriber.toJson(),
      subscriptions: {'lists': subscriber.lists.map((l) => l.toJson()).toList()},
      campaignViews: {'views': campaignViews},
      linkClicks: {'clicks': linkClicks},
    );
  }
}