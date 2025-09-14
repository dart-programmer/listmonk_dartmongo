import 'package:mongo_dart/mongo_dart.dart';
import '../models/subscriber.dart';
import '../models/list.dart';
import '../models/constants.dart';
import '../utils/validation.dart';
import '../utils/logger.dart';
import '../utils/performance.dart';
import '../exceptions/listmonk_exceptions.dart';

/// Read-only subscriber service for querying subscriber data
/// This service only has read access to the subscribers collection
/// All write operations are handled via gRPC calls to the user service
class ReadOnlySubscriberService {
  final Db _db;

  ReadOnlySubscriberService(this._db);

  /// Get a subscriber by ID, UUID, or email (READ-ONLY)
  Future<Subscriber?> getSubscriber({
    int? id,
    String? uuid,
    String? email,
  }) async {
    try {
      final query = <String, dynamic>{};
      
      if (id != null) {
        query['id'] = id;
      } else if (uuid != null) {
        query['uuid'] = uuid;
      } else if (email != null) {
        query['email'] = ValidationUtils.sanitizeEmail(email);
      } else {
        throw ValidationException('At least one of id, uuid, or email must be provided');
      }

      Logger.db('getSubscriber', data: query);

      return await PerformanceMonitor.measureAsync('get_subscriber', () async {
        final subscriberDoc = await _db.collection('subscribers').findOne(query);
        if (subscriberDoc == null) return null;

        final subscriber = Subscriber.fromJson(subscriberDoc);
        final lists = await _getSubscriberLists(subscriber.id!);
        
        return subscriber.copyWith(lists: lists);
      });
    } catch (e) {
      Logger.error('Error getting subscriber', error: e);
      throw DatabaseException('Failed to get subscriber: $e');
    }
  }

  /// Get subscribers by email addresses (READ-ONLY)
  Future<List<Subscriber>> getSubscribersByEmail(List<String> emails) async {
    try {
      if (emails.isEmpty) return [];

      // Sanitize emails
      final sanitizedEmails = emails.map(ValidationUtils.sanitizeEmail).toList();

      Logger.db('getSubscribersByEmail', data: {'emails': sanitizedEmails});

      return await PerformanceMonitor.measureAsync('get_subscribers_by_email', () async {
        final cursor = _db.collection('subscribers').find({
          'email': {'\$in': sanitizedEmails}
        });

        final subscribers = <Subscriber>[];
        await for (final doc in cursor) {
          final subscriber = Subscriber.fromJson(doc);
          final lists = await _getSubscriberLists(subscriber.id!);
          subscribers.add(subscriber.copyWith(lists: lists));
        }

        return subscribers;
      });
    } catch (e) {
      Logger.error('Error getting subscribers by email', error: e);
      throw DatabaseException('Failed to get subscribers by email: $e');
    }
  }

  /// Query subscribers with pagination and filtering (READ-ONLY)
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
    try {
      // Validate pagination
      if (!ValidationUtils.isValidPagination(offset, limit)) {
        throw ValidationException('Invalid pagination parameters');
      }

      // Validate search string
      if (searchStr != null && !ValidationUtils.isValidSearchString(searchStr)) {
        throw ValidationException('Invalid search string');
      }

      final query = <String, dynamic>{};
      
      // Apply status filter
      if (subStatus != null) {
        if (!ValidationUtils.isValidSubscriberStatus(subStatus)) {
          throw ValidationException('Invalid subscriber status: $subStatus');
        }
        query['status'] = subStatus;
      }

      // Apply list filter
      if (listIds != null && listIds.isNotEmpty) {
        if (!ValidationUtils.isValidListIds(listIds)) {
          throw ValidationException('Invalid list IDs');
        }
        query['lists.listId'] = {'\$in': listIds};
      }

      // Apply search filter
      if (searchStr != null && searchStr.isNotEmpty) {
        query['\$or'] = [
          {'email': {'\$regex': searchStr, '\$options': 'i'}},
          {'name': {'\$regex': searchStr, '\$options': 'i'}},
        ];
      }

      Logger.db('querySubscribers', data: {
        'query': query,
        'orderBy': orderBy,
        'order': order,
        'offset': offset,
        'limit': limit,
      });

      return await PerformanceMonitor.measureAsync('query_subscribers', () async {
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
      });
    } catch (e) {
      Logger.error('Error querying subscribers', error: e);
      if (e is ValidationException) rethrow;
      throw DatabaseException('Failed to query subscribers: $e');
    }
  }

  /// Get subscriber lists (READ-ONLY)
  Future<List<Subscription>> getSubscriberLists(int subscriberId) async {
    try {
      Logger.db('getSubscriberLists', data: {'subscriber_id': subscriberId});
      return await _getSubscriberLists(subscriberId);
    } catch (e) {
      Logger.error('Error getting subscriber lists', error: e);
      throw DatabaseException('Failed to get subscriber lists: $e');
    }
  }

  /// Get subscriber profile for export (READ-ONLY)
  Future<SubscriberExportProfile> getSubscriberProfileForExport({
    int? id,
    String? uuid,
  }) async {
    try {
      final subscriber = await getSubscriber(id: id, uuid: uuid);
      if (subscriber == null) {
        throw NotFoundException('Subscriber not found');
      }

      Logger.db('getSubscriberProfileForExport', data: {
        'subscriber_id': subscriber.id,
        'subscriber_uuid': subscriber.uuid,
      });

      return await PerformanceMonitor.measureAsync('get_subscriber_profile_export', () async {
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
      });
    } catch (e) {
      Logger.error('Error getting subscriber profile for export', error: e);
      if (e is NotFoundException) rethrow;
      throw DatabaseException('Failed to get subscriber profile for export: $e');
    }
  }

  /// Check if subscribers have specific lists (READ-ONLY)
  Future<Map<int, bool>> hasSubscriberLists(List<int> subIds, List<int> listIds) async {
    try {
      if (subIds.isEmpty || listIds.isEmpty) return {};

      Logger.db('hasSubscriberLists', data: {
        'subscriber_ids': subIds,
        'list_ids': listIds,
      });

      return await PerformanceMonitor.measureAsync('has_subscriber_lists', () async {
        final pipeline = [
          {
            '\$match': {
              'subscriber_id': {'\$in': subIds},
              'list_id': {'\$in': listIds},
            }
          },
          {
            '\$group': {
              '_id': '\$subscriber_id',
              'has': {'\$sum': 1}
            }
          }
        ];

        final cursor = _db.collection('subscriptions').aggregate(pipeline);
        
        final result = <int, bool>{};
        await for (final doc in cursor) {
          result[doc['_id']] = doc['has'] > 0;
        }

        return result;
      });
    } catch (e) {
      Logger.error('Error checking subscriber lists', error: e);
      throw DatabaseException('Failed to check subscriber lists: $e');
    }
  }

  /// Get subscriber count by status (READ-ONLY)
  Future<Map<String, int>> getSubscriberCountByStatus() async {
    try {
      Logger.db('getSubscriberCountByStatus');

      return await PerformanceMonitor.measureAsync('get_subscriber_count_by_status', () async {
        final pipeline = [
          {
            '\$group': {
              '_id': '\$status',
              'count': {'\$sum': 1}
            }
          }
        ];

        final cursor = _db.collection('subscribers').aggregate(pipeline);
        
        final result = <String, int>{};
        await for (final doc in cursor) {
          result[doc['_id']] = doc['count'];
        }

        return result;
      });
    } catch (e) {
      Logger.error('Error getting subscriber count by status', error: e);
      throw DatabaseException('Failed to get subscriber count by status: $e');
    }
  }

  /// Get subscriber lists (internal helper)
  Future<List<Subscription>> _getSubscriberLists(int subscriberId) async {
    final cursor = _db.collection('subscriptions').find({'subscriber_id': subscriberId});
    
    final subscriptions = <Subscription>[];
    await for (final doc in cursor) {
      subscriptions.add(Subscription.fromJson(doc));
    }

    return subscriptions;
  }
}