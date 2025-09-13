import 'package:mongo_dart/mongo_dart.dart';
import '../models/campaign.dart';
import '../models/constants.dart';

/// Service for managing analytics and tracking
class AnalyticsService {
  final Db _db;

  AnalyticsService(this._db);

  /// Get campaign analytics counts
  Future<List<CampaignAnalyticsCount>> getCampaignAnalyticsCounts({
    required List<int> campaignIds,
    required String type,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    if (!_isValidAnalyticsType(type)) {
      throw ArgumentError('Invalid analytics type: $type');
    }

    final collection = _getAnalyticsCollection(type);
    
    final cursor = _db.collection(collection).find({
      'campaign_id': {'\$in': campaignIds},
      'created_at': {
        '\$gte': fromDate,
        '\$lte': toDate,
      }
    });

    final counts = <CampaignAnalyticsCount>[];
    await for (final doc in cursor) {
      counts.add(CampaignAnalyticsCount.fromJson(doc));
    }

    return counts;
  }

  /// Get campaign analytics links
  Future<List<CampaignAnalyticsLink>> getCampaignAnalyticsLinks({
    required List<int> campaignIds,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pipeline = [
      {
        '\$match': {
          'campaign_id': {'\$in': campaignIds},
          'created_at': {
            '\$gte': fromDate,
            '\$lte': toDate,
          }
        }
      },
      {
        '\$group': {
          '_id': '\$url',
          'count': {'\$sum': 1}
        }
      },
      {
        '\$sort': {'count': -1}
      }
    ];

    final cursor = _db.collection('link_clicks').aggregate(pipeline);
    
    final links = <CampaignAnalyticsLink>[];
    await for (final doc in cursor) {
      links.add(CampaignAnalyticsLink(
        url: doc['_id'],
        count: doc['count'],
      ));
    }

    return links;
  }

  /// Register campaign view
  Future<void> registerCampaignView({
    required String campaignUuid,
    required String subscriberUuid,
  }) async {
    await _db.collection('campaign_views').insertOne({
      'campaign_uuid': campaignUuid,
      'subscriber_uuid': subscriberUuid,
      'created_at': DateTime.now(),
    });
  }

  /// Register link click
  Future<void> registerLinkClick({
    required String linkUuid,
    required String campaignUuid,
    required String subscriberUuid,
    required String url,
  }) async {
    await _db.collection('link_clicks').insertOne({
      'link_uuid': linkUuid,
      'campaign_uuid': campaignUuid,
      'subscriber_uuid': subscriberUuid,
      'url': url,
      'created_at': DateTime.now(),
    });
  }

  /// Record bounce
  Future<void> recordBounce({
    required String type,
    required String source,
    required Map<String, dynamic> meta,
    String? email,
    String? subscriberUuid,
    int? subscriberId,
    String? campaignUuid,
  }) async {
    await _db.collection('bounces').insertOne({
      'type': type,
      'source': source,
      'meta': meta,
      'email': email,
      'subscriber_uuid': subscriberUuid,
      'subscriber_id': subscriberId,
      'campaign_uuid': campaignUuid,
      'created_at': DateTime.now(),
    });
  }

  /// Get bounce statistics
  Future<Map<String, int>> getBounceStats({
    List<int>? campaignIds,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, dynamic>{};

    if (campaignIds != null && campaignIds.isNotEmpty) {
      query['campaign_id'] = {'\$in': campaignIds};
    }

    if (fromDate != null) {
      query['created_at'] = {'\$gte': fromDate};
    }

    if (toDate != null) {
      query['created_at'] = {
        ...query['created_at'] ?? {},
        '\$lte': toDate,
      };
    }

    final pipeline = [
      {'\$match': query},
      {
        '\$group': {
          '_id': '\$type',
          'count': {'\$sum': 1}
        }
      }
    ];

    final cursor = _db.collection('bounces').aggregate(pipeline);
    
    final stats = <String, int>{};
    await for (final doc in cursor) {
      stats[doc['_id']] = doc['count'];
    }

    return stats;
  }

  /// Delete old analytics data
  Future<void> deleteOldAnalyticsData({
    required DateTime beforeDate,
    String? type,
  }) async {
    final query = <String, dynamic>{
      'created_at': {'\$lt': beforeDate}
    };

    if (type != null) {
      query['type'] = type;
    }

    if (type == null || type == CampaignAnalytics.views) {
      await _db.collection('campaign_views').deleteMany(query);
    }

    if (type == null || type == CampaignAnalytics.clicks) {
      await _db.collection('link_clicks').deleteMany(query);
    }

    if (type == null || type == CampaignAnalytics.bounces) {
      await _db.collection('bounces').deleteMany(query);
    }
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final stats = <String, dynamic>{};

    // Get total subscribers
    final totalSubscribers = await _db.collection('subscribers').count();
    stats['total_subscribers'] = totalSubscribers;

    // Get total lists
    final totalLists = await _db.collection('lists').count();
    stats['total_lists'] = totalLists;

    // Get total campaigns
    final totalCampaigns = await _db.collection('campaigns').count();
    stats['total_campaigns'] = totalCampaigns;

    // Get active campaigns
    final activeCampaigns = await _db.collection('campaigns').count({
      'status': {'\$in': [CampaignStatus.running, CampaignStatus.scheduled]}
    });
    stats['active_campaigns'] = activeCampaigns;

    // Get total views
    final totalViews = await _db.collection('campaign_views').count();
    stats['total_views'] = totalViews;

    // Get total clicks
    final totalClicks = await _db.collection('link_clicks').count();
    stats['total_clicks'] = totalClicks;

    // Get total bounces
    final totalBounces = await _db.collection('bounces').count();
    stats['total_bounces'] = totalBounces;

    return stats;
  }

  /// Get collection name for analytics type
  String _getAnalyticsCollection(String type) {
    switch (type) {
      case CampaignAnalytics.views:
        return 'campaign_views';
      case CampaignAnalytics.clicks:
        return 'link_clicks';
      case CampaignAnalytics.bounces:
        return 'bounces';
      default:
        throw ArgumentError('Invalid analytics type: $type');
    }
  }

  /// Validate analytics type
  bool _isValidAnalyticsType(String type) {
    return [
      CampaignAnalytics.views,
      CampaignAnalytics.clicks,
      CampaignAnalytics.bounces,
    ].contains(type);
  }
}