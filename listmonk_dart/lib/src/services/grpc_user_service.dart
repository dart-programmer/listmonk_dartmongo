import 'package:grpc/grpc.dart';
import '../exceptions/listmonk_exceptions.dart';
import '../utils/logger.dart';
import '../utils/performance.dart';

/// gRPC client service for user operations
/// This service handles all user updates via gRPC calls to the user service
class GrpcUserService {
  final ClientChannel _channel;
  late final UserServiceClient _client;

  GrpcUserService({
    required String host,
    required int port,
    bool useTls = true,
  }) : _channel = ClientChannel(
          host,
          port: port,
          options: ChannelOptions(
            credentials: useTls ? ChannelCredentials.secure() : ChannelCredentials.insecure(),
          ),
        ) {
    _client = UserServiceClient(_channel);
  }

  /// Factory constructor for gRPC user service
  factory GrpcUserService.create({
    required String host,
    required int port,
    bool useTls = true,
  }) {
    return GrpcUserService(
      host: host,
      port: port,
      useTls: useTls,
    );
  }

  /// Update subscriber status
  Future<void> updateSubscriberStatus({
    required String subscriberUuid,
    required String status,
    String? reason,
  }) async {
    try {
      Logger.info('Updating subscriber status via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'status': status,
        'reason': reason,
      });

      await PerformanceMonitor.measureAsync('grpc_update_subscriber_status', () async {
        final request = UpdateSubscriberStatusRequest()
          ..subscriberUuid = subscriberUuid
          ..status = status
          ..reason = reason ?? '';

        final response = await _client.updateSubscriberStatus(request);

        if (!response.success) {
          throw UserException('Failed to update subscriber status: ${response.message}');
        }

        Logger.info('Subscriber status updated successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
          'status': status,
        });
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error updating subscriber status', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error updating subscriber status', error: e);
      throw UserException('Failed to update subscriber status: $e');
    }
  }

  /// Handle opt-out request
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

      return await PerformanceMonitor.measureAsync('grpc_opt_out', () async {
        final request = OptOutRequest()
          ..subscriberUuid = subscriberUuid
          ..listUuids.addAll(listUuids ?? [])
          ..reason = reason ?? ''
          ..blocklist = blocklist;

        final response = await _client.optOut(request);

        if (!response.success) {
          throw UserException('Failed to process opt-out: ${response.message}');
        }

        Logger.info('Opt-out processed successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
          'opted_out_lists': response.optedOutLists,
        });

        return response.optedOutLists;
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error processing opt-out', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error processing opt-out', error: e);
      throw UserException('Failed to process opt-out: $e');
    }
  }

  /// Handle opt-in confirmation
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

      return await PerformanceMonitor.measureAsync('grpc_opt_in', () async {
        final request = OptInRequest()
          ..subscriberUuid = subscriberUuid
          ..listUuids.addAll(listUuids)
          ..meta.addAll(meta ?? {});

        final response = await _client.optIn(request);

        if (!response.success) {
          throw UserException('Failed to process opt-in: ${response.message}');
        }

        Logger.info('Opt-in processed successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
          'opted_in_lists': response.optedInLists,
        });

        return response.optedInLists;
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error processing opt-in', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error processing opt-in', error: e);
      throw UserException('Failed to process opt-in: $e');
    }
  }

  /// Update subscriber attributes
  Future<void> updateSubscriberAttributes({
    required String subscriberUuid,
    required Map<String, String> attributes,
  }) async {
    try {
      Logger.info('Updating subscriber attributes via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'attributes': attributes,
      });

      await PerformanceMonitor.measureAsync('grpc_update_subscriber_attributes', () async {
        final request = UpdateSubscriberAttributesRequest()
          ..subscriberUuid = subscriberUuid
          ..attributes.addAll(attributes);

        final response = await _client.updateSubscriberAttributes(request);

        if (!response.success) {
          throw UserException('Failed to update subscriber attributes: ${response.message}');
        }

        Logger.info('Subscriber attributes updated successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
        });
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error updating subscriber attributes', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error updating subscriber attributes', error: e);
      throw UserException('Failed to update subscriber attributes: $e');
    }
  }

  /// Update subscriber subscriptions
  Future<List<String>> updateSubscriberSubscriptions({
    required String subscriberUuid,
    required List<String> listUuids,
    required String subscriptionStatus,
    bool deleteExisting = false,
  }) async {
    try {
      Logger.info('Updating subscriber subscriptions via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'list_uuids': listUuids,
        'subscription_status': subscriptionStatus,
        'delete_existing': deleteExisting,
      });

      return await PerformanceMonitor.measureAsync('grpc_update_subscriber_subscriptions', () async {
        final request = UpdateSubscriberSubscriptionsRequest()
          ..subscriberUuid = subscriberUuid
          ..listUuids.addAll(listUuids)
          ..subscriptionStatus = subscriptionStatus
          ..deleteExisting = deleteExisting;

        final response = await _client.updateSubscriberSubscriptions(request);

        if (!response.success) {
          throw UserException('Failed to update subscriber subscriptions: ${response.message}');
        }

        Logger.info('Subscriber subscriptions updated successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
          'updated_lists': response.updatedLists,
        });

        return response.updatedLists;
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error updating subscriber subscriptions', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error updating subscriber subscriptions', error: e);
      throw UserException('Failed to update subscriber subscriptions: $e');
    }
  }

  /// Delete subscriber
  Future<void> deleteSubscriber({
    required String subscriberUuid,
    String? reason,
  }) async {
    try {
      Logger.info('Deleting subscriber via gRPC', error: {
        'subscriber_uuid': subscriberUuid,
        'reason': reason,
      });

      await PerformanceMonitor.measureAsync('grpc_delete_subscriber', () async {
        final request = DeleteSubscriberRequest()
          ..subscriberUuid = subscriberUuid
          ..reason = reason ?? '';

        final response = await _client.deleteSubscriber(request);

        if (!response.success) {
          throw UserException('Failed to delete subscriber: ${response.message}');
        }

        Logger.info('Subscriber deleted successfully', error: {
          'subscriber_uuid': response.subscriberUuid,
        });
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error deleting subscriber', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error deleting subscriber', error: e);
      throw UserException('Failed to delete subscriber: $e');
    }
  }

  /// Bulk update subscriber status
  Future<BulkUpdateResult> bulkUpdateSubscriberStatus({
    required List<String> subscriberUuids,
    required String status,
    String? reason,
  }) async {
    try {
      Logger.info('Bulk updating subscriber status via gRPC', error: {
        'subscriber_uuids': subscriberUuids,
        'status': status,
        'reason': reason,
      });

      return await PerformanceMonitor.measureAsync('grpc_bulk_update_subscriber_status', () async {
        final request = BulkUpdateSubscriberStatusRequest()
          ..subscriberUuids.addAll(subscriberUuids)
          ..status = status
          ..reason = reason ?? '';

        final response = await _client.bulkUpdateSubscriberStatus(request);

        if (!response.success) {
          throw UserException('Failed to bulk update subscriber status: ${response.message}');
        }

        Logger.info('Bulk subscriber status update completed', error: {
          'updated_count': response.updatedCount,
          'failed_uuids': response.failedUuids,
        });

        return BulkUpdateResult(
          success: response.success,
          updatedCount: response.updatedCount,
          failedUuids: response.failedUuids,
        );
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error bulk updating subscriber status', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error bulk updating subscriber status', error: e);
      throw UserException('Failed to bulk update subscriber status: $e');
    }
  }

  /// Bulk opt-out
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

      return await PerformanceMonitor.measureAsync('grpc_bulk_opt_out', () async {
        final request = BulkOptOutRequest()
          ..subscriberUuids.addAll(subscriberUuids)
          ..listUuids.addAll(listUuids ?? [])
          ..reason = reason ?? ''
          ..blocklist = blocklist;

        final response = await _client.bulkOptOut(request);

        if (!response.success) {
          throw UserException('Failed to bulk opt-out: ${response.message}');
        }

        Logger.info('Bulk opt-out completed', error: {
          'updated_count': response.updatedCount,
          'failed_uuids': response.failedUuids,
        });

        return BulkOptOutResult(
          success: response.success,
          updatedCount: response.updatedCount,
          failedUuids: response.failedUuids,
        );
      });
    } on GrpcException catch (e) {
      Logger.error('gRPC error bulk opt-out', error: e);
      throw UserException('gRPC error: ${e.message}', code: 'GRPC_ERROR');
    } catch (e) {
      Logger.error('Error bulk opt-out', error: e);
      throw UserException('Failed to bulk opt-out: $e');
    }
  }

  /// Close the gRPC channel
  Future<void> close() async {
    await _channel.shutdown();
    Logger.info('gRPC channel closed');
  }
}

/// Result of bulk update operations
class BulkUpdateResult {
  final bool success;
  final int updatedCount;
  final List<String> failedUuids;

  const BulkUpdateResult({
    required this.success,
    required this.updatedCount,
    required this.failedUuids,
  });
}

/// Result of bulk opt-out operations
class BulkOptOutResult {
  final bool success;
  final int updatedCount;
  final List<String> failedUuids;

  const BulkOptOutResult({
    required this.success,
    required this.updatedCount,
    required this.failedUuids,
  });
}

// gRPC service client stub (this would be generated from the .proto file)
class UserServiceClient {
  final ClientChannel _channel;

  UserServiceClient(this._channel);

  Future<UpdateSubscriberStatusResponse> updateSubscriberStatus(UpdateSubscriberStatusRequest request) async {
    // This would be implemented by the generated gRPC client
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<OptOutResponse> optOut(OptOutRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<OptInResponse> optIn(OptInRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<UpdateSubscriberAttributesResponse> updateSubscriberAttributes(UpdateSubscriberAttributesRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<UpdateSubscriberSubscriptionsResponse> updateSubscriberSubscriptions(UpdateSubscriberSubscriptionsRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<DeleteSubscriberResponse> deleteSubscriber(DeleteSubscriberRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<BulkUpdateSubscriberStatusResponse> bulkUpdateSubscriberStatus(BulkUpdateSubscriberStatusRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }

  Future<BulkOptOutResponse> bulkOptOut(BulkOptOutRequest request) async {
    throw UnimplementedError('gRPC client not implemented - needs to be generated from .proto');
  }
}

// gRPC message classes (these would be generated from the .proto file)
class UpdateSubscriberStatusRequest {
  String subscriberUuid = '';
  String status = '';
  String reason = '';
}

class UpdateSubscriberStatusResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
}

class OptOutRequest {
  String subscriberUuid = '';
  List<String> listUuids = [];
  String reason = '';
  bool blocklist = false;
}

class OptOutResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
  List<String> optedOutLists = [];
}

class OptInRequest {
  String subscriberUuid = '';
  List<String> listUuids = [];
  Map<String, String> meta = {};
}

class OptInResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
  List<String> optedInLists = [];
}

class UpdateSubscriberAttributesRequest {
  String subscriberUuid = '';
  Map<String, String> attributes = {};
}

class UpdateSubscriberAttributesResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
}

class UpdateSubscriberSubscriptionsRequest {
  String subscriberUuid = '';
  List<String> listUuids = [];
  String subscriptionStatus = '';
  bool deleteExisting = false;
}

class UpdateSubscriberSubscriptionsResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
  List<String> updatedLists = [];
}

class DeleteSubscriberRequest {
  String subscriberUuid = '';
  String reason = '';
}

class DeleteSubscriberResponse {
  bool success = false;
  String message = '';
  String subscriberUuid = '';
}

class BulkUpdateSubscriberStatusRequest {
  List<String> subscriberUuids = [];
  String status = '';
  String reason = '';
}

class BulkUpdateSubscriberStatusResponse {
  bool success = false;
  String message = '';
  int updatedCount = 0;
  List<String> failedUuids = [];
}

class BulkOptOutRequest {
  List<String> subscriberUuids = [];
  List<String> listUuids = [];
  String reason = '';
  bool blocklist = false;
}

class BulkOptOutResponse {
  bool success = false;
  String message = '';
  int updatedCount = 0;
  List<String> failedUuids = [];
}