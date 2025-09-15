import 'package:mongo_dart/mongo_dart.dart';
import '../models/email_recipient.dart';
import '../models/constants.dart';
import '../utils/validation.dart';
import '../utils/logger.dart';
import '../utils/performance.dart';
import '../exceptions/listmonk_exceptions.dart';

/// Unified email service that can read from both users and subscribers collections
/// This service provides a single interface for email operations across both collections
class UnifiedEmailService {
  final Db _db;

  UnifiedEmailService(this._db);

  /// Get email recipient by email address (searches both collections)
  Future<EmailRecipient?> getEmailRecipient(String email) async {
    try {
      final sanitizedEmail = ValidationUtils.sanitizeEmail(email);
      
      Logger.db('getEmailRecipient', data: {'email': sanitizedEmail});

      return await PerformanceMonitor.measureAsync('get_email_recipient', () async {
        // First try subscribers collection
        final subscriberDoc = await _db.collection('subscribers').findOne({
          'email': sanitizedEmail
        });

        if (subscriberDoc != null) {
          return EmailRecipient.fromSubscriber(subscriberDoc);
        }

        // Then try users collection
        final userDoc = await _db.collection('users').findOne({
          'email': sanitizedEmail
        });

        if (userDoc != null) {
          return EmailRecipient.fromUser(userDoc);
        }

        return null;
      });
    } catch (e) {
      Logger.error('Error getting email recipient', error: e);
      throw DatabaseException('Failed to get email recipient: $e');
    }
  }

  /// Get email recipients by email addresses (searches both collections)
  Future<List<EmailRecipient>> getEmailRecipients(List<String> emails) async {
    try {
      if (emails.isEmpty) return [];

      final sanitizedEmails = emails.map(ValidationUtils.sanitizeEmail).toList();
      
      Logger.db('getEmailRecipients', data: {'emails': sanitizedEmails});

      return await PerformanceMonitor.measureAsync('get_email_recipients', () async {
        final recipients = <EmailRecipient>[];
        final foundEmails = <String>{};

        // Search subscribers collection
        final subscriberCursor = _db.collection('subscribers').find({
          'email': {'\$in': sanitizedEmails}
        });

        await for (final doc in subscriberCursor) {
          final recipient = EmailRecipient.fromSubscriber(doc);
          recipients.add(recipient);
          foundEmails.add(recipient.email);
        }

        // Search users collection for remaining emails
        final remainingEmails = sanitizedEmails.where((e) => !foundEmails.contains(e)).toList();
        if (remainingEmails.isNotEmpty) {
          final userCursor = _db.collection('users').find({
            'email': {'\$in': remainingEmails}
          });

          await for (final doc in userCursor) {
            final recipient = EmailRecipient.fromUser(doc);
            recipients.add(recipient);
          }
        }

        return recipients;
      });
    } catch (e) {
      Logger.error('Error getting email recipients', error: e);
      throw DatabaseException('Failed to get email recipients: $e');
    }
  }

  /// Query email recipients with pagination and filtering (searches both collections)
  Future<PageResults<EmailRecipient>> queryEmailRecipients({
    String? searchStr,
    String? queryExp,
    List<String>? sources, // ['subscribers', 'users'] or null for both
    String? status,
    String? listId, // Only for subscribers
    String orderBy = 'email',
    String order = SortOrder.asc,
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

      Logger.db('queryEmailRecipients', data: {
        'searchStr': searchStr,
        'sources': sources,
        'status': status,
        'listId': listId,
        'orderBy': orderBy,
        'order': order,
        'offset': offset,
        'limit': limit,
      });

      return await PerformanceMonitor.measureAsync('query_email_recipients', () async {
        final allRecipients = <EmailRecipient>[];

        // Determine which collections to search
        final collectionsToSearch = sources ?? ['subscribers', 'users'];

        // Search subscribers collection
        if (collectionsToSearch.contains('subscribers')) {
          final subscriberQuery = _buildSubscriberQuery(searchStr, status, listId);
          final subscriberCursor = _db.collection('subscribers').find(subscriberQuery);

          await for (final doc in subscriberCursor) {
            allRecipients.add(EmailRecipient.fromSubscriber(doc));
          }
        }

        // Search users collection
        if (collectionsToSearch.contains('users')) {
          final userQuery = _buildUserQuery(searchStr, status);
          final userCursor = _db.collection('users').find(userQuery);

          await for (final doc in userCursor) {
            allRecipients.add(EmailRecipient.fromUser(doc));
          }
        }

        // Sort and paginate
        allRecipients.sort((a, b) {
          final aValue = _getSortValue(a, orderBy);
          final bValue = _getSortValue(b, orderBy);
          
          if (order == SortOrder.asc) {
            return aValue.compareTo(bValue);
          } else {
            return bValue.compareTo(aValue);
          }
        });

        final total = allRecipients.length;
        final paginatedRecipients = allRecipients
            .skip(offset)
            .take(limit)
            .toList();

        return PageResults<EmailRecipient>(
          results: paginatedRecipients,
          search: searchStr ?? '',
          query: queryExp ?? '',
          total: total,
          perPage: limit,
          page: (offset / limit).floor() + 1,
        );
      });
    } catch (e) {
      Logger.error('Error querying email recipients', error: e);
      if (e is ValidationException) rethrow;
      throw DatabaseException('Failed to query email recipients: $e');
    }
  }

  /// Get email recipients by list ID (subscribers only)
  Future<List<EmailRecipient>> getEmailRecipientsByList(String listId) async {
    try {
      Logger.db('getEmailRecipientsByList', data: {'listId': listId});

      return await PerformanceMonitor.measureAsync('get_email_recipients_by_list', () async {
        final recipients = <EmailRecipient>[];

        // Get subscribers for this list
        final subscriberCursor = _db.collection('subscribers').find({
          'lists.listId': listId
        });

        await for (final doc in subscriberCursor) {
          recipients.add(EmailRecipient.fromSubscriber(doc));
        }

        return recipients;
      });
    } catch (e) {
      Logger.error('Error getting email recipients by list', error: e);
      throw DatabaseException('Failed to get email recipients by list: $e');
    }
  }

  /// Get email recipients by status (searches both collections)
  Future<List<EmailRecipient>> getEmailRecipientsByStatus(String status) async {
    try {
      Logger.db('getEmailRecipientsByStatus', data: {'status': status});

      return await PerformanceMonitor.measureAsync('get_email_recipients_by_status', () async {
        final recipients = <EmailRecipient>[];

        // Search subscribers collection
        final subscriberCursor = _db.collection('subscribers').find({
          'status': status
        });

        await for (final doc in subscriberCursor) {
          recipients.add(EmailRecipient.fromSubscriber(doc));
        }

        // Search users collection
        final userCursor = _db.collection('users').find({
          'status': status
        });

        await for (final doc in userCursor) {
          recipients.add(EmailRecipient.fromUser(doc));
        }

        return recipients;
      });
    } catch (e) {
      Logger.error('Error getting email recipients by status', error: e);
      throw DatabaseException('Failed to get email recipients by status: $e');
    }
  }

  /// Get email recipient count by status (both collections)
  Future<Map<String, int>> getEmailRecipientCountByStatus() async {
    try {
      Logger.db('getEmailRecipientCountByStatus');

      return await PerformanceMonitor.measureAsync('get_email_recipient_count_by_status', () async {
        final statusCounts = <String, int>{};

        // Count subscribers by status
        final subscriberPipeline = [
          {
            '\$group': {
              '_id': '\$status',
              'count': {'\$sum': 1}
            }
          }
        ];

        final subscriberCursor = _db.collection('subscribers').aggregate(subscriberPipeline);
        await for (final doc in subscriberCursor) {
          statusCounts['subscribers_${doc['_id']}'] = doc['count'];
        }

        // Count users by status
        final userPipeline = [
          {
            '\$group': {
              '_id': '\$status',
              'count': {'\$sum': 1}
            }
          }
        ];

        final userCursor = _db.collection('users').aggregate(userPipeline);
        await for (final doc in userCursor) {
          statusCounts['users_${doc['_id']}'] = doc['count'];
        }

        return statusCounts;
      });
    } catch (e) {
      Logger.error('Error getting email recipient count by status', error: e);
      throw DatabaseException('Failed to get email recipient count by status: $e');
    }
  }

  /// Get email recipients for campaign (both collections)
  Future<List<EmailRecipient>> getEmailRecipientsForCampaign({
    required String campaignId,
    List<String>? listIds,
    String? status,
  }) async {
    try {
      Logger.db('getEmailRecipientsForCampaign', data: {
        'campaignId': campaignId,
        'listIds': listIds,
        'status': status,
      });

      return await PerformanceMonitor.measureAsync('get_email_recipients_for_campaign', () async {
        final recipients = <EmailRecipient>[];

        // Get subscribers for campaign lists
        if (listIds != null && listIds.isNotEmpty) {
          final subscriberQuery = <String, dynamic>{
            'lists.listId': {'\$in': listIds}
          };
          
          if (status != null) {
            subscriberQuery['status'] = status;
          }

          final subscriberCursor = _db.collection('subscribers').find(subscriberQuery);
          await for (final doc in subscriberCursor) {
            recipients.add(EmailRecipient.fromSubscriber(doc));
          }
        }

        // Get users for campaign (if no specific lists)
        if (listIds == null || listIds.isEmpty) {
          final userQuery = <String, dynamic>{};
          
          if (status != null) {
            userQuery['status'] = status;
          }

          final userCursor = _db.collection('users').find(userQuery);
          await for (final doc in userCursor) {
            recipients.add(EmailRecipient.fromUser(doc));
          }
        }

        return recipients;
      });
    } catch (e) {
      Logger.error('Error getting email recipients for campaign', error: e);
      throw DatabaseException('Failed to get email recipients for campaign: $e');
    }
  }

  /// Search email recipients by text (both collections)
  Future<List<EmailRecipient>> searchEmailRecipients(String searchText) async {
    try {
      Logger.db('searchEmailRecipients', data: {'searchText': searchText});

      return await PerformanceMonitor.measureAsync('search_email_recipients', () async {
        final recipients = <EmailRecipient>[];

        // Search subscribers collection
        final subscriberCursor = _db.collection('subscribers').find({
          '\$or': [
            {'email': {'\$regex': searchText, '\$options': 'i'}},
            {'name': {'\$regex': searchText, '\$options': 'i'}},
          ]
        });

        await for (final doc in subscriberCursor) {
          recipients.add(EmailRecipient.fromSubscriber(doc));
        }

        // Search users collection
        final userCursor = _db.collection('users').find({
          '\$or': [
            {'email': {'\$regex': searchText, '\$options': 'i'}},
            {'name': {'\$regex': searchText, '\$options': 'i'}},
            {'displayName': {'\$regex': searchText, '\$options': 'i'}},
          ]
        });

        await for (final doc in userCursor) {
          recipients.add(EmailRecipient.fromUser(doc));
        }

        return recipients;
      });
    } catch (e) {
      Logger.error('Error searching email recipients', error: e);
      throw DatabaseException('Failed to search email recipients: $e');
    }
  }

  /// Build query for subscribers collection
  Map<String, dynamic> _buildSubscriberQuery(String? searchStr, String? status, String? listId) {
    final query = <String, dynamic>{};

    if (status != null) {
      query['status'] = status;
    }

    if (listId != null) {
      query['lists.listId'] = listId;
    }

    if (searchStr != null && searchStr.isNotEmpty) {
      query['\$or'] = [
        {'email': {'\$regex': searchStr, '\$options': 'i'}},
        {'name': {'\$regex': searchStr, '\$options': 'i'}},
      ];
    }

    return query;
  }

  /// Build query for users collection
  Map<String, dynamic> _buildUserQuery(String? searchStr, String? status) {
    final query = <String, dynamic>{};

    if (status != null) {
      query['status'] = status;
    }

    if (searchStr != null && searchStr.isNotEmpty) {
      query['\$or'] = [
        {'email': {'\$regex': searchStr, '\$options': 'i'}},
        {'name': {'\$regex': searchStr, '\$options': 'i'}},
        {'displayName': {'\$regex': searchStr, '\$options': 'i'}},
      ];
    }

    return query;
  }

  /// Get sort value for a recipient based on orderBy field
  dynamic _getSortValue(EmailRecipient recipient, String orderBy) {
    switch (orderBy) {
      case 'email':
        return recipient.email;
      case 'name':
        return recipient.name ?? recipient.email;
      case 'status':
        return recipient.status;
      case 'source':
        return recipient.source;
      case 'createdAt':
        return recipient.createdAt ?? DateTime(1970);
      case 'updatedAt':
        return recipient.updatedAt ?? DateTime(1970);
      case 'lastActivityAt':
        return recipient.lastActivityAt ?? DateTime(1970);
      default:
        return recipient.email;
    }
  }
}