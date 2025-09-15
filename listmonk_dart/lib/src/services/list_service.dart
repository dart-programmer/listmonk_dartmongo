import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import '../models/list.dart';
import '../models/constants.dart';

/// Service for managing mailing lists
class ListService {
  final Db _db;
  final Uuid _uuid = const Uuid();

  ListService(this._db);

  /// Get all lists optionally filtered by type
  Future<List<List>> getLists({
    String? type,
    bool getAll = false,
    List<int>? permittedIds,
  }) async {
    final query = <String, dynamic>{};

    if (type != null) {
      query['type'] = type;
    }

    if (permittedIds != null && permittedIds.isNotEmpty) {
      query['id'] = {'\$in': permittedIds};
    }

    final cursor = _db.collection('lists').find(query).sort({'id': 1});
    
    final lists = <List>[];
    await for (final doc in cursor) {
      final list = List.fromJson(doc);
      final subscriberCounts = await _getSubscriberCounts(list.id!);
      lists.add(list.copyWith(
        subscriberCounts: subscriberCounts,
        subscriberCount: subscriberCounts.values.fold(0, (sum, count) => sum + count),
      ));
    }

    return lists;
  }

  /// Query lists with pagination and filtering
  Future<PageResults<List>> queryLists({
    String? searchStr,
    String? type,
    String? optin,
    List<String>? tags,
    String orderBy = 'created_at',
    String order = SortOrder.desc,
    bool getAll = false,
    List<int>? permittedIds,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{};

    // Apply type filter
    if (type != null) {
      query['type'] = type;
    }

    // Apply optin filter
    if (optin != null) {
      query['optin'] = optin;
    }

    // Apply tags filter
    if (tags != null && tags.isNotEmpty) {
      query['tags'] = {'\$in': tags};
    }

    // Apply permission filter
    if (permittedIds != null && permittedIds.isNotEmpty) {
      query['id'] = {'\$in': permittedIds};
    }

    // Apply search filter
    if (searchStr != null && searchStr.isNotEmpty) {
      query['\$or'] = [
        {'name': {'\$regex': searchStr, '\$options': 'i'}},
        {'description': {'\$regex': searchStr, '\$options': 'i'}},
      ];
    }

    final total = await _db.collection('lists').count(query);
    
    final cursor = _db.collection('lists')
        .find(query)
        .sort({orderBy: order == SortOrder.asc ? 1 : -1})
        .skip(offset)
        .limit(limit);

    final lists = <List>[];
    await for (final doc in cursor) {
      final list = List.fromJson(doc);
      final subscriberCounts = await _getSubscriberCounts(list.id!);
      lists.add(list.copyWith(
        subscriberCounts: subscriberCounts,
        subscriberCount: subscriberCounts.values.fold(0, (sum, count) => sum + count),
      ));
    }

    return PageResults<List>(
      results: lists,
      search: searchStr ?? '',
      query: '',
      total: total,
      perPage: limit,
      page: (offset / limit).floor() + 1,
    );
  }

  /// Get a list by ID or UUID
  Future<List?> getList({int? id, String? uuid}) async {
    final query = <String, dynamic>{};
    
    if (id != null) {
      query['id'] = id;
    } else if (uuid != null) {
      query['uuid'] = uuid;
    } else {
      throw ArgumentError('At least one of id or uuid must be provided');
    }

    final listDoc = await _db.collection('lists').findOne(query);
    if (listDoc == null) return null;

    final list = List.fromJson(listDoc);
    final subscriberCounts = await _getSubscriberCounts(list.id!);
    
    return list.copyWith(
      subscriberCounts: subscriberCounts,
      subscriberCount: subscriberCounts.values.fold(0, (sum, count) => sum + count),
    );
  }

  /// Get lists by optin type
  Future<List<List>> getListsByOptin({
    required String optinType,
    List<int>? ids,
  }) async {
    final query = <String, dynamic>{
      'optin': optinType,
    };

    if (ids != null && ids.isNotEmpty) {
      query['id'] = {'\$in': ids};
    }

    final cursor = _db.collection('lists').find(query);
    
    final lists = <List>[];
    await for (final doc in cursor) {
      final list = List.fromJson(doc);
      final subscriberCounts = await _getSubscriberCounts(list.id!);
      lists.add(list.copyWith(
        subscriberCounts: subscriberCounts,
        subscriberCount: subscriberCounts.values.fold(0, (sum, count) => sum + count),
      ));
    }

    return lists;
  }

  /// Get list types by IDs or UUIDs
  Future<Map<dynamic, String>> getListTypes({
    List<int>? ids,
    List<String>? uuids,
  }) async {
    final query = <String, dynamic>{};
    
    if (ids != null && ids.isNotEmpty) {
      query['id'] = {'\$in': ids};
    } else if (uuids != null && uuids.isNotEmpty) {
      query['uuid'] = {'\$in': uuids};
    } else {
      throw ArgumentError('At least one of ids or uuids must be provided');
    }

    final cursor = _db.collection('lists').find(query, {'id': 1, 'uuid': 1, 'type': 1});
    
    final result = <dynamic, String>{};
    await for (final doc in cursor) {
      final key = ids != null ? doc['id'] : doc['uuid'];
      result[key] = doc['type'];
    }

    return result;
  }

  /// Create a new list
  Future<List> createList(List list) async {
    final uuid = _uuid.v4();
    final now = DateTime.now();

    final newList = list.copyWith(
      uuid: uuid,
      type: list.type.isEmpty ? ListType.private : list.type,
      optin: list.optin.isEmpty ? ListOptin.single : list.optin,
      tags: _normalizeTags(list.tags),
      createdAt: now,
      updatedAt: now,
    );

    // Insert list
    final result = await _db.collection('lists').insertOne({
      ...newList.toJson(),
      'id': null, // Will be set by MongoDB
    });

    final listId = result.id;

    // Get the created list
    final createdList = await getList(id: listId);
    if (createdList == null) {
      throw Exception('Failed to create list');
    }

    return createdList;
  }

  /// Update a list
  Future<List> updateList(int id, List list) async {
    final now = DateTime.now();
    
    await _db.collection('lists').updateOne(
      {'id': id},
      {
        '\$set': {
          'name': list.name,
          'type': list.type,
          'optin': list.optin,
          'tags': _normalizeTags(list.tags),
          'description': list.description,
          'updated_at': now,
        }
      },
    );

    final updatedList = await getList(id: id);
    if (updatedList == null) {
      throw Exception('List not found');
    }

    return updatedList;
  }

  /// Delete a list
  Future<void> deleteList(int id) async {
    await deleteLists([id]);
  }

  /// Delete multiple lists
  Future<void> deleteLists(List<int> ids) async {
    if (ids.isEmpty) return;

    await _db.collection('lists').deleteMany({'id': {'\$in': ids}});
    await _db.collection('subscriptions').deleteMany({'list_id': {'\$in': ids}});
  }

  /// Get subscriber counts by status for a list
  Future<Map<String, int>> _getSubscriberCounts(int listId) async {
    final pipeline = [
      {
        '\$match': {'list_id': listId}
      },
      {
        '\$lookup': {
          'from': 'subscribers',
          'localField': 'subscriber_id',
          'foreignField': 'id',
          'as': 'subscriber'
        }
      },
      {
        '\$unwind': '\$subscriber'
      },
      {
        '\$group': {
          '_id': '\$subscriber.status',
          'count': {'\$sum': 1}
        }
      }
    ];

    final cursor = _db.collection('subscriptions').aggregate(pipeline);
    
    final counts = <String, int>{};
    await for (final doc in cursor) {
      counts[doc['_id']] = doc['count'];
    }

    return counts;
  }

  /// Normalize tags by lowercasing and removing special characters
  List<String> _normalizeTags(List<String> tags) {
    return tags
        .map((tag) => tag.toLowerCase().replaceAll(RegExp(r'[^\w\-]'), '-'))
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}