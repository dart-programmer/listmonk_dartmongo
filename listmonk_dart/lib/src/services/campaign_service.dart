import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import '../models/campaign.dart';
import '../models/constants.dart';

/// Service for managing campaigns
class CampaignService {
  final Db _db;
  final Uuid _uuid = const Uuid();

  CampaignService(this._db);

  /// Query campaigns with pagination and filtering
  Future<PageResults<Campaign>> queryCampaigns({
    String? searchStr,
    List<String>? statuses,
    List<String>? tags,
    String orderBy = 'created_at',
    String order = SortOrder.desc,
    bool getAll = false,
    List<int>? permittedLists,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{};

    // Apply status filter
    if (statuses != null && statuses.isNotEmpty) {
      query['status'] = {'\$in': statuses};
    }

    // Apply tags filter
    if (tags != null && tags.isNotEmpty) {
      query['tags'] = {'\$in': tags};
    }

    // Apply list permission filter
    if (permittedLists != null && permittedLists.isNotEmpty) {
      query['lists'] = {'\$in': permittedLists};
    }

    // Apply search filter
    if (searchStr != null && searchStr.isNotEmpty) {
      query['\$or'] = [
        {'name': {'\$regex': searchStr, '\$options': 'i'}},
        {'subject': {'\$regex': searchStr, '\$options': 'i'}},
      ];
    }

    final total = await _db.collection('campaigns').count(query);
    
    final cursor = _db.collection('campaigns')
        .find(query)
        .sort({orderBy: order == SortOrder.asc ? 1 : -1})
        .skip(offset)
        .limit(limit);

    final campaigns = <Campaign>[];
    await for (final doc in cursor) {
      final campaign = Campaign.fromJson(doc);
      final meta = await _getCampaignMeta(campaign.id!);
      campaigns.add(campaign.copyWith(meta: meta));
    }

    return PageResults<Campaign>(
      results: campaigns,
      search: searchStr ?? '',
      query: '',
      total: total,
      perPage: limit,
      page: (offset / limit).floor() + 1,
    );
  }

  /// Get a campaign by ID, UUID, or archive slug
  Future<Campaign?> getCampaign({
    int? id,
    String? uuid,
    String? archiveSlug,
  }) async {
    final query = <String, dynamic>{};
    
    if (id != null) {
      query['id'] = id;
    } else if (uuid != null) {
      query['uuid'] = uuid;
    } else if (archiveSlug != null) {
      query['archive_slug'] = archiveSlug;
    } else {
      throw ArgumentError('At least one of id, uuid, or archiveSlug must be provided');
    }

    final campaignDoc = await _db.collection('campaigns').findOne(query);
    if (campaignDoc == null) return null;

    final campaign = Campaign.fromJson(campaignDoc);
    final meta = await _getCampaignMeta(campaign.id!);
    
    return campaign.copyWith(meta: meta);
  }

  /// Get archived campaigns
  Future<PageResults<Campaign>> getArchivedCampaigns({
    int offset = 0,
    int limit = 20,
  }) async {
    final query = {'archive': true};
    
    final total = await _db.collection('campaigns').count(query);
    
    final cursor = _db.collection('campaigns')
        .find(query)
        .sort({'created_at': -1})
        .skip(offset)
        .limit(limit);

    final campaigns = <Campaign>[];
    await for (final doc in cursor) {
      final campaign = Campaign.fromJson(doc);
      final meta = await _getCampaignMeta(campaign.id!);
      campaigns.add(campaign.copyWith(meta: meta));
    }

    return PageResults<Campaign>(
      results: campaigns,
      search: '',
      query: '',
      total: total,
      perPage: limit,
      page: (offset / limit).floor() + 1,
    );
  }

  /// Create a new campaign
  Future<Campaign> createCampaign(
    Campaign campaign, {
    List<int>? listIds,
    List<int>? mediaIds,
  }) async {
    final uuid = _uuid.v4();
    final now = DateTime.now();

    final newCampaign = campaign.copyWith(
      uuid: uuid,
      createdAt: now,
      updatedAt: now,
      mediaIds: mediaIds ?? [],
    );

    // Insert campaign
    final result = await _db.collection('campaigns').insertOne({
      ...newCampaign.toJson(),
      'id': null, // Will be set by MongoDB
      'lists': listIds ?? [],
    });

    final campaignId = result.id;

    // Create campaign meta
    await _createCampaignMeta(campaignId, listIds ?? []);

    // Get the created campaign with meta
    final createdCampaign = await getCampaign(id: campaignId);
    if (createdCampaign == null) {
      throw Exception('Failed to create campaign');
    }

    return createdCampaign;
  }

  /// Update a campaign
  Future<Campaign> updateCampaign(
    int id,
    Campaign campaign, {
    List<int>? listIds,
    List<int>? mediaIds,
  }) async {
    final now = DateTime.now();
    
    await _db.collection('campaigns').updateOne(
      {'id': id},
      {
        '\$set': {
          'name': campaign.name,
          'subject': campaign.subject,
          'from_email': campaign.fromEmail,
          'body': campaign.body,
          'alt_body': campaign.altBody,
          'content_type': campaign.contentType,
          'send_at': campaign.sendAt,
          'headers': campaign.headers,
          'tags': campaign.tags,
          'messenger': campaign.messenger,
          'template_id': campaign.templateId,
          'archive': campaign.archive,
          'archive_slug': campaign.archiveSlug,
          'archive_template_id': campaign.archiveTemplateId,
          'archive_meta': campaign.archiveMeta,
          'body_source': campaign.bodySource,
          'media_ids': mediaIds ?? campaign.mediaIds,
          'updated_at': now,
        }
      },
    );

    // Update lists if provided
    if (listIds != null) {
      await _db.collection('campaigns').updateOne(
        {'id': id},
        {'\$set': {'lists': listIds}},
      );
    }

    final updatedCampaign = await getCampaign(id: id);
    if (updatedCampaign == null) {
      throw Exception('Campaign not found');
    }

    return updatedCampaign;
  }

  /// Update campaign status
  Future<Campaign> updateCampaignStatus(int id, String status) async {
    final campaign = await getCampaign(id: id);
    if (campaign == null) {
      throw Exception('Campaign not found');
    }

    // Validate status transition
    _validateStatusTransition(campaign.status, status);

    await _db.collection('campaigns').updateOne(
      {'id': id},
      {'\$set': {'status': status}},
    );

    return campaign.copyWith(status: status);
  }

  /// Update campaign archive settings
  Future<void> updateCampaignArchive(
    int id, {
    required bool enabled,
    int? tplId,
    Map<String, dynamic>? meta,
    String? archiveSlug,
  }) async {
    await _db.collection('campaigns').updateOne(
      {'id': id},
      {
        '\$set': {
          'archive': enabled,
          'archive_slug': archiveSlug,
          'archive_template_id': tplId,
          'archive_meta': meta ?? {},
        }
      },
    );
  }

  /// Delete a campaign
  Future<void> deleteCampaign(int id) async {
    final result = await _db.collection('campaigns').deleteOne({'id': id});
    if (result.n == 0) {
      throw Exception('Campaign not found');
    }
  }

  /// Check if campaign has any of the given list IDs
  Future<bool> campaignHasLists(int id, List<int> listIds) async {
    final campaign = await _db.collection('campaigns').findOne({'id': id});
    if (campaign == null) return false;

    final campaignLists = List<int>.from(campaign['lists'] ?? []);
    return campaignLists.any((listId) => listIds.contains(listId));
  }

  /// Get running campaign stats
  Future<List<CampaignStats>> getRunningCampaignStats() async {
    final cursor = _db.collection('campaigns').find({'status': CampaignStatus.running});
    
    final stats = <CampaignStats>[];
    await for (final doc in cursor) {
      final meta = await _getCampaignMeta(doc['id']);
      stats.add(CampaignStats(
        id: doc['id'],
        status: doc['status'],
        toSend: meta.toSend,
        sent: meta.sent,
        started: meta.startedAt,
        updatedAt: doc['updated_at'],
        rate: 0, // Calculate based on time
        netRate: 0, // Calculate based on time
      ));
    }

    return stats;
  }

  /// Register campaign view
  Future<void> registerCampaignView(String campUuid, String subUuid) async {
    await _db.collection('campaign_views').insertOne({
      'campaign_uuid': campUuid,
      'subscriber_uuid': subUuid,
      'created_at': DateTime.now(),
    });
  }

  /// Register campaign link click
  Future<String?> registerCampaignLinkClick(
    String linkUuid,
    String campUuid,
    String subUuid,
  ) async {
    // Get the link URL
    final link = await _db.collection('links').findOne({'uuid': linkUuid});
    if (link == null) return null;

    await _db.collection('link_clicks').insertOne({
      'link_uuid': linkUuid,
      'campaign_uuid': campUuid,
      'subscriber_uuid': subUuid,
      'url': link['url'],
      'created_at': DateTime.now(),
    });

    return link['url'];
  }

  /// Get campaign meta information
  Future<CampaignMeta> _getCampaignMeta(int campaignId) async {
    final metaDoc = await _db.collection('campaign_meta').findOne({'campaign_id': campaignId});
    
    if (metaDoc == null) {
      return CampaignMeta(
        campaignId: campaignId,
        views: 0,
        clicks: 0,
        bounces: 0,
        lists: [],
        media: [],
        toSend: 0,
        sent: 0,
      );
    }

    return CampaignMeta.fromJson(metaDoc);
  }

  /// Create campaign meta
  Future<void> _createCampaignMeta(int campaignId, List<int> listIds) async {
    await _db.collection('campaign_meta').insertOne({
      'campaign_id': campaignId,
      'views': 0,
      'clicks': 0,
      'bounces': 0,
      'lists': listIds.map((id) => {'list_id': id, 'name': 'List $id'}).toList(),
      'media': [],
      'to_send': 0,
      'sent': 0,
    });
  }

  /// Validate status transition
  void _validateStatusTransition(String currentStatus, String newStatus) {
    switch (newStatus) {
      case CampaignStatus.draft:
        if (currentStatus != CampaignStatus.scheduled) {
          throw Exception('Only scheduled campaigns can be set to draft');
        }
        break;
      case CampaignStatus.scheduled:
        if (currentStatus != CampaignStatus.draft && currentStatus != CampaignStatus.paused) {
          throw Exception('Only draft or paused campaigns can be scheduled');
        }
        break;
      case CampaignStatus.running:
        if (currentStatus != CampaignStatus.paused && currentStatus != CampaignStatus.draft) {
          throw Exception('Only paused or draft campaigns can be started');
        }
        break;
      case CampaignStatus.paused:
        if (currentStatus != CampaignStatus.running) {
          throw Exception('Only running campaigns can be paused');
        }
        break;
      case CampaignStatus.cancelled:
        if (currentStatus != CampaignStatus.running && currentStatus != CampaignStatus.paused) {
          throw Exception('Only running or paused campaigns can be cancelled');
        }
        break;
    }
  }
}