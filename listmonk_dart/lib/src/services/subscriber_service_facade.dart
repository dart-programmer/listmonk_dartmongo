import '../models/subscriber.dart';
import '../models/list.dart';
import '../models/constants.dart';
import '../exceptions/listmonk_exceptions.dart';
import '../utils/logger.dart';
import '../utils/performance.dart';
import 'readonly_subscriber_service.dart';
import 'grpc_user_service.dart';

/// Facade service that combines read-only operations with gRPC write operations
/// This service provides a unified interface for subscriber operations
class SubscriberServiceFacade {
  final ReadOnlySubscriberService _readOnlyService;
  final GrpcUserService _grpcService;

  SubscriberServiceFacade({
    required ReadOnlySubscriberService readOnlyService,
    required GrpcUserService grpcService,
  }) : _readOnlyService = readOnlyService,
       _grpcService = grpcService;

  // ========== READ-ONLY OPERATIONS ==========

  /// Get a subscriber by ID, UUID, or email
  Future<Subscriber?> getSubscriber({
    int? id,
    String? uuid,
    String? email,
  }) async {
    return await _readOnlyService.getSubscriber(
      id: id,
      uuid: uuid,
      email: email,
    );
  }

  /// Get subscribers by email addresses
  Future<List<Subscriber>> getSubscribersByEmail(List<String> emails) async {
    return await _readOnlyService.getSubscribersByEmail(emails);
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
    return await _readOnlyService.querySubscribers(
      searchStr: searchStr,
      queryExp: queryExp,
      listIds: listIds,
      subStatus: subStatus,
      orderBy: orderBy,
      order: order,
      offset: offset,
      limit: limit,
    );
  }

  /// Get subscriber lists
  Future<List<Subscription>> getSubscriberLists(int subscriberId) async {
    return await _readOnlyService.getSubscriberLists(subscriberId);
  }

  /// Get subscriber profile for export
  Future<SubscriberExportProfile> getSubscriberProfileForExport({
    int? id,
    String? uuid,
  }) async {
    return await _readOnlyService.getSubscriberProfileForExport(
      id: id,
      uuid: uuid,
    );
  }

  /// Check if subscribers have specific lists
  Future<Map<int, bool>> hasSubscriberLists(List<int> subIds, List<int> listIds) async {
    return await _readOnlyService.hasSubscriberLists(subIds, listIds);
  }

  /// Get subscriber count by status
  Future<Map<String, int>> getSubscriberCountByStatus() async {
    return await _readOnlyService.getSubscriberCountByStatus();
  }

  // ========== WRITE OPERATIONS VIA gRPC ==========

  /// Update subscriber status via gRPC
  Future<void> updateSubscriberStatus({
    required String subscriberUuid,
    required String status,
    String? reason,
  }) async {
    try {
      // Validate status
      if (!ValidationUtils.isValidSubscriberStatus(status)) {
        throw ValidationException('Invalid subscriber status: $status');
      }

      Logger.info('Updating subscriber status via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'status': status,
        'reason': reason,
      });

      await PerformanceMonitor.measureAsync('update_subscriber_status', () async {
        await _grpcService.updateSubscriberStatus(
          subscriberUuid: subscriberUuid,
          status: status,
          reason: reason,
        );
      });

      Logger.info('Subscriber status updated successfully');
    } catch (e) {
      Logger.error('Error updating subscriber status', error: e);
      rethrow;
    }
  }

  /// Handle opt-out via gRPC
  Future<List<String>> optOut({
    required String subscriberUuid,
    List<String>? listUuids,
    String? reason,
    bool blocklist = false,
  }) async {
    try {
      Logger.info('Processing opt-out via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'list_uuids': listUuids,
        'reason': reason,
        'blocklist': blocklist,
      });

      return await PerformanceMonitor.measureAsync('opt_out', () async {
        return await _grpcService.optOut(
          subscriberUuid: subscriberUuid,
          listUuids: listUuids,
          reason: reason,
          blocklist: blocklist,
        );
      });
    } catch (e) {
      Logger.error('Error processing opt-out', error: e);
      rethrow;
    }
  }

  /// Handle opt-in confirmation via gRPC
  Future<List<String>> optIn({
    required String subscriberUuid,
    required List<String> listUuids,
    Map<String, String>? meta,
  }) async {
    try {
      Logger.info('Processing opt-in via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'list_uuids': listUuids,
        'meta': meta,
      });

      return await PerformanceMonitor.measureAsync('opt_in', () async {
        return await _grpcService.optIn(
          subscriberUuid: subscriberUuid,
          listUuids: listUuids,
          meta: meta,
        );
      });
    } catch (e) {
      Logger.error('Error processing opt-in', error: e);
      rethrow;
    }
  }

  /// Update subscriber attributes via gRPC
  Future<void> updateSubscriberAttributes({
    required String subscriberUuid,
    required Map<String, String> attributes,
  }) async {
    try {
      // Validate attributes
      if (!ValidationUtils.isValidJsonAttributes(attributes)) {
        throw ValidationException('Invalid subscriber attributes');
      }

      Logger.info('Updating subscriber attributes via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'attributes': attributes,
      });

      await PerformanceMonitor.measureAsync('update_subscriber_attributes', () async {
        await _grpcService.updateSubscriberAttributes(
          subscriberUuid: subscriberUuid,
          attributes: attributes,
        );
      });

      Logger.info('Subscriber attributes updated successfully');
    } catch (e) {
      Logger.error('Error updating subscriber attributes', error: e);
      rethrow;
    }
  }

  /// Update subscriber subscriptions via gRPC
  Future<List<String>> updateSubscriberSubscriptions({
    required String subscriberUuid,
    required List<String> listUuids,
    required String subscriptionStatus,
    bool deleteExisting = false,
  }) async {
    try {
      // Validate subscription status
      if (!ValidationUtils.isValidSubscriptionStatus(subscriptionStatus)) {
        throw ValidationException('Invalid subscription status: $subscriptionStatus');
      }

      Logger.info('Updating subscriber subscriptions via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'list_uuids': listUuids,
        'subscription_status': subscriptionStatus,
        'delete_existing': deleteExisting,
      });

      return await PerformanceMonitor.measureAsync('update_subscriber_subscriptions', () async {
        return await _grpcService.updateSubscriberSubscriptions(
          subscriberUuid: subscriberUuid,
          listUuids: listUuids,
          subscriptionStatus: subscriptionStatus,
          deleteExisting: deleteExisting,
        );
      });
    } catch (e) {
      Logger.error('Error updating subscriber subscriptions', error: e);
      rethrow;
    }
  }

  /// Delete subscriber via gRPC
  Future<void> deleteSubscriber({
    required String subscriberUuid,
    String? reason,
  }) async {
    try {
      Logger.info('Deleting subscriber via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'reason': reason,
      });

      await PerformanceMonitor.measureAsync('delete_subscriber', () async {
        await _grpcService.deleteSubscriber(
          subscriberUuid: subscriberUuid,
          reason: reason,
        );
      });

      Logger.info('Subscriber deleted successfully');
    } catch (e) {
      Logger.error('Error deleting subscriber', error: e);
      rethrow;
    }
  }

  /// Bulk update subscriber status via gRPC
  Future<BulkUpdateResult> bulkUpdateSubscriberStatus({
    required List<String> subscriberUuids,
    required String status,
    String? reason,
  }) async {
    try {
      // Validate status
      if (!ValidationUtils.isValidSubscriberStatus(status)) {
        throw ValidationException('Invalid subscriber status: $status');
      }

      Logger.info('Bulk updating subscriber status via gRPC', error: {
        'subscriber_uuids': subscriberUuids,
        'status': status,
        'reason': reason,
      });

      return await PerformanceMonitor.measureAsync('bulk_update_subscriber_status', () async {
        return await _grpcService.bulkUpdateSubscriberStatus(
          subscriberUuids: subscriberUuids,
          status: status,
          reason: reason,
        );
      });
    } catch (e) {
      Logger.error('Error bulk updating subscriber status', error: e);
      rethrow;
    }
  }

  /// Bulk opt-out via gRPC
  Future<BulkOptOutResult> bulkOptOut({
    required List<String> subscriberUuids,
    List<String>? listUuids,
    String? reason,
    bool blocklist = false,
  }) async {
    try {
      Logger.info('Bulk opt-out via gRPC', error: {
        'subscriber_uuids': subscriberUuids,
        'list_uuids': listUuids,
        'reason': reason,
        'blocklist': blocklist,
      });

      return await PerformanceMonitor.measureAsync('bulk_opt_out', () async {
        return await _grpcService.bulkOptOut(
          subscriberUuids: subscriberUuids,
          listUuids: listUuids,
          reason: reason,
          blocklist: blocklist,
        );
      });
    } catch (e) {
      Logger.error('Error bulk opt-out', error: e);
      rethrow;
    }
  }

  // ========== CONVENIENCE METHODS ==========

  /// Blocklist a subscriber
  Future<void> blocklistSubscriber(String subscriberUuid, {String? reason}) async {
    await updateSubscriberStatus(
      subscriberUuid: subscriberUuid,
      status: SubscriberStatus.blocklisted,
      reason: reason ?? 'Blocklisted by admin',
    );
  }

  /// Enable a subscriber
  Future<void> enableSubscriber(String subscriberUuid, {String? reason}) async {
    await updateSubscriberStatus(
      subscriberUuid: subscriberUuid,
      status: SubscriberStatus.enabled,
      reason: reason ?? 'Enabled by admin',
    );
  }

  /// Disable a subscriber
  Future<void> disableSubscriber(String subscriberUuid, {String? reason}) async {
    await updateSubscriberStatus(
      subscriberUuid: subscriberUuid,
      status: SubscriberStatus.disabled,
      reason: reason ?? 'Disabled by admin',
    );
  }

  /// Unsubscribe from all lists
  Future<List<String>> unsubscribeFromAll(String subscriberUuid, {String? reason}) async {
    return await optOut(
      subscriberUuid: subscriberUuid,
      reason: reason ?? 'Unsubscribed from all lists',
    );
  }

  /// Subscribe to specific lists
  Future<List<String>> subscribeToList(String subscriberUuid, List<String> listUuids) async {
    return await optIn(
      subscriberUuid: subscriberUuid,
      listUuids: listUuids,
    );
  }
}