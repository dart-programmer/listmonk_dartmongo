import 'package:listmonk_dart/listmonk_dart.dart';

/// Example showing the new gRPC architecture with read-only access and gRPC writes
Future<void> main() async {
  // Initialize the core service with gRPC configuration
  final core = await ListmonkCore.create(
    mongoUri: 'mongodb://localhost:27017',
    databaseName: 'listmonk_example',
    mailtrapConfig: MailtrapConfig(
      username: 'your_mailtrap_username',
      password: 'your_mailtrap_password',
      fromEmail: 'noreply@yourdomain.com',
      fromName: 'Your Company',
      useTls: true,
    ),
    grpcConfig: GrpcConfig(
      host: 'localhost',
      port: 50051,
      useTls: false, // Set to true for production
    ),
  );

  try {
    print('=== Listmonk gRPC Architecture Example ===\n');

    // ========== READ-ONLY OPERATIONS ==========
    print('1. READ-ONLY OPERATIONS (Direct MongoDB access)');
    print('==============================================');

    // Query subscribers (read-only)
    print('\nQuerying subscribers...');
    final subscriberResults = await core.readOnlySubscriberService.querySubscribers(
      searchStr: 'john',
      limit: 10,
    );
    print('Found ${subscriberResults.total} subscribers');
    for (final sub in subscriberResults.results) {
      print('- ${sub.name} (${sub.email}) - Status: ${sub.status}');
    }

    // Get specific subscriber (read-only)
    print('\nGetting specific subscriber...');
    final subscriber = await core.readOnlySubscriberService.getSubscriber(
      email: 'john.doe@example.com',
    );
    if (subscriber != null) {
      print('Found subscriber: ${subscriber.name} (${subscriber.uuid})');
      print('Status: ${subscriber.status}');
      print('Lists: ${subscriber.lists.map((l) => l.listName).join(', ')}');
    } else {
      print('Subscriber not found');
    }

    // Get subscriber count by status (read-only)
    print('\nGetting subscriber count by status...');
    final statusCounts = await core.readOnlySubscriberService.getSubscriberCountByStatus();
    statusCounts.forEach((status, count) {
      print('- $status: $count');
    });

    // ========== WRITE OPERATIONS VIA gRPC ==========
    print('\n\n2. WRITE OPERATIONS (via gRPC)');
    print('================================');

    if (core.subscriberServiceFacade != null) {
      // Update subscriber status via gRPC
      print('\nUpdating subscriber status via gRPC...');
      try {
        await core.subscriberServiceFacade!.updateSubscriberStatus(
          subscriberUuid: subscriber?.uuid ?? 'example-uuid',
          status: SubscriberStatus.enabled,
          reason: 'Status updated via gRPC',
        );
        print('Subscriber status updated successfully');
      } catch (e) {
        print('Error updating subscriber status: $e');
      }

      // Handle opt-out via gRPC
      print('\nProcessing opt-out via gRPC...');
      try {
        final optedOutLists = await core.subscriberServiceFacade!.optOut(
          subscriberUuid: subscriber?.uuid ?? 'example-uuid',
          listUuids: ['list-uuid-1', 'list-uuid-2'],
          reason: 'User requested opt-out',
          blocklist: false,
        );
        print('Opted out from lists: ${optedOutLists.join(', ')}');
      } catch (e) {
        print('Error processing opt-out: $e');
      }

      // Handle opt-in via gRPC
      print('\nProcessing opt-in via gRPC...');
      try {
        final optedInLists = await core.subscriberServiceFacade!.optIn(
          subscriberUuid: subscriber?.uuid ?? 'example-uuid',
          listUuids: ['list-uuid-1'],
          meta: {'source': 'website', 'campaign': 'welcome'},
        );
        print('Opted in to lists: ${optedInLists.join(', ')}');
      } catch (e) {
        print('Error processing opt-in: $e');
      }

      // Update subscriber attributes via gRPC
      print('\nUpdating subscriber attributes via gRPC...');
      try {
        await core.subscriberServiceFacade!.updateSubscriberAttributes(
          subscriberUuid: subscriber?.uuid ?? 'example-uuid',
          attributes: {
            'company': 'Updated Company',
            'industry': 'Technology',
            'location': 'New York',
            'preferences': 'weekly',
          },
        );
        print('Subscriber attributes updated successfully');
      } catch (e) {
        print('Error updating subscriber attributes: $e');
      }

      // Update subscriber subscriptions via gRPC
      print('\nUpdating subscriber subscriptions via gRPC...');
      try {
        final updatedLists = await core.subscriberServiceFacade!.updateSubscriberSubscriptions(
          subscriberUuid: subscriber?.uuid ?? 'example-uuid',
          listUuids: ['list-uuid-1', 'list-uuid-2'],
          subscriptionStatus: SubscriptionStatus.confirmed,
          deleteExisting: false,
        );
        print('Updated subscriptions for lists: ${updatedLists.join(', ')}');
      } catch (e) {
        print('Error updating subscriber subscriptions: $e');
      }

      // Convenience methods
      print('\nUsing convenience methods...');
      try {
        // Blocklist subscriber
        await core.subscriberServiceFacade!.blocklistSubscriber(
          subscriber?.uuid ?? 'example-uuid',
          reason: 'Spam complaints',
        );
        print('Subscriber blocklisted');

        // Enable subscriber
        await core.subscriberServiceFacade!.enableSubscriber(
          subscriber?.uuid ?? 'example-uuid',
          reason: 'Appeal approved',
        );
        print('Subscriber enabled');

        // Unsubscribe from all lists
        final unsubscribedLists = await core.subscriberServiceFacade!.unsubscribeFromAll(
          subscriber?.uuid ?? 'example-uuid',
          reason: 'User requested complete opt-out',
        );
        print('Unsubscribed from all lists: ${unsubscribedLists.join(', ')}');
      } catch (e) {
        print('Error with convenience methods: $e');
      }

      // Bulk operations
      print('\nBulk operations...');
      try {
        final bulkResult = await core.subscriberServiceFacade!.bulkUpdateSubscriberStatus(
          subscriberUuids: ['uuid-1', 'uuid-2', 'uuid-3'],
          status: SubscriberStatus.enabled,
          reason: 'Bulk enable operation',
        );
        print('Bulk update result: ${bulkResult.updatedCount} updated, ${bulkResult.failedUuids.length} failed');

        final bulkOptOutResult = await core.subscriberServiceFacade!.bulkOptOut(
          subscriberUuids: ['uuid-1', 'uuid-2'],
          listUuids: ['list-uuid-1'],
          reason: 'Bulk opt-out operation',
        );
        print('Bulk opt-out result: ${bulkOptOutResult.updatedCount} updated, ${bulkOptOutResult.failedUuids.length} failed');
      } catch (e) {
        print('Error with bulk operations: $e');
      }
    } else {
      print('gRPC service not configured - write operations not available');
    }

    // ========== CAMPAIGN OPERATIONS ==========
    print('\n\n3. CAMPAIGN OPERATIONS (Direct MongoDB access)');
    print('===============================================');

    // Query campaigns
    print('\nQuerying campaigns...');
    final campaignResults = await core.campaignService.queryCampaigns(
      limit: 10,
    );
    print('Found ${campaignResults.total} campaigns');
    for (final camp in campaignResults.results) {
      print('- ${camp.name} - Status: ${camp.status}');
    }

    // ========== EMAIL SENDING ==========
    print('\n\n4. EMAIL SENDING (via Mailtrap)');
    print('=================================');

    if (core.mailtrapService != null && subscriber != null) {
      print('\nSending test email...');
      try {
        await core.mailtrapService!.sendTransactionalEmail(
          toEmail: subscriber.email,
          subject: 'Test Email from Listmonk Dart',
          body: '''
            <h1>Hello ${subscriber.name}!</h1>
            <p>This is a test email sent via the new gRPC architecture.</p>
            <p>Your status: ${subscriber.status}</p>
            <p>Your lists: ${subscriber.lists.map((l) => l.listName).join(', ')}</p>
          ''',
          templateData: {
            'subscriber_name': subscriber.name,
            'subscriber_email': subscriber.email,
            'subscriber_status': subscriber.status,
          },
        );
        print('Test email sent successfully');
      } catch (e) {
        print('Error sending test email: $e');
      }
    } else {
      print('Mailtrap service not configured - email sending not available');
    }

    // ========== ANALYTICS ==========
    print('\n\n5. ANALYTICS (Direct MongoDB access)');
    print('=====================================');

    // Get dashboard statistics
    print('\nGetting dashboard statistics...');
    final stats = await core.analyticsService.getDashboardStats();
    print('Dashboard stats:');
    stats.forEach((key, value) {
      print('- $key: $value');
    });

    print('\n=== Example completed successfully! ===');

  } catch (e) {
    print('Error: $e');
  } finally {
    // Close the database connection
    await core.close();
  }
}