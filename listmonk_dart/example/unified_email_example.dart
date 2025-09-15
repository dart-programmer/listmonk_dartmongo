import 'package:listmonk_dart/listmonk_dart.dart';

/// Example showing unified email reading from both users and subscribers collections
Future<void> main() async {
  // Initialize the core service
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
      useTls: false,
    ),
  );

  try {
    print('=== Unified Email Reading Example ===\n');

    // ========== UNIFIED EMAIL OPERATIONS ==========
    print('1. UNIFIED EMAIL OPERATIONS (Both Users & Subscribers)');
    print('=====================================================');

    // Get email recipient by email (searches both collections)
    print('\nGetting email recipient by email...');
    final recipient = await core.unifiedEmailService.getEmailRecipient('user@example.com');
    if (recipient != null) {
      print('Found recipient:');
      print('- Email: ${recipient.email}');
      print('- Name: ${recipient.displayName}');
      print('- Status: ${recipient.status}');
      print('- Source: ${recipient.source}');
      print('- Active: ${recipient.isActive}');
      if (recipient.hasSubscriptions) {
        print('- Subscriptions: ${recipient.subscriptions?.length ?? 0} lists');
      }
    } else {
      print('Recipient not found');
    }

    // Get multiple email recipients
    print('\nGetting multiple email recipients...');
    final recipients = await core.unifiedEmailService.getEmailRecipients([
      'user1@example.com',
      'user2@example.com',
      'subscriber1@example.com',
      'subscriber2@example.com',
    ]);
    
    print('Found ${recipients.length} recipients:');
    for (final recipient in recipients) {
      print('- ${recipient.email} (${recipient.source}) - ${recipient.status}');
    }

    // Query email recipients with filtering
    print('\nQuerying email recipients with filters...');
    final queryResults = await core.unifiedEmailService.queryEmailRecipients(
      searchStr: 'john',
      sources: ['subscribers', 'users'], // Search both collections
      status: 'active',
      orderBy: 'email',
      order: SortOrder.asc,
      limit: 10,
    );
    
    print('Query results:');
    print('- Total: ${queryResults.total}');
    print('- Page: ${queryResults.page}');
    print('- Per page: ${queryResults.perPage}');
    print('- Results:');
    for (final recipient in queryResults.results) {
      print('  * ${recipient.email} (${recipient.source}) - ${recipient.status}');
    }

    // Get email recipients by status
    print('\nGetting email recipients by status...');
    final activeRecipients = await core.unifiedEmailService.getEmailRecipientsByStatus('active');
    print('Found ${activeRecipients.length} active recipients');
    
    final enabledRecipients = await core.unifiedEmailService.getEmailRecipientsByStatus('enabled');
    print('Found ${enabledRecipients.length} enabled recipients');

    // Get email recipients by list (subscribers only)
    print('\nGetting email recipients by list...');
    final listRecipients = await core.unifiedEmailService.getEmailRecipientsByList('list-uuid-123');
    print('Found ${listRecipients.length} recipients in list');

    // Search email recipients by text
    print('\nSearching email recipients by text...');
    final searchResults = await core.unifiedEmailService.searchEmailRecipients('gmail');
    print('Found ${searchResults.length} recipients matching "gmail"');
    for (final recipient in searchResults.take(5)) {
      print('- ${recipient.email} (${recipient.source})');
    }

    // Get email recipient count by status
    print('\nGetting email recipient count by status...');
    final statusCounts = await core.unifiedEmailService.getEmailRecipientCountByStatus();
    print('Status counts:');
    statusCounts.forEach((status, count) {
      print('- $status: $count');
    });

    // ========== CAMPAIGN EMAIL RECIPIENTS ==========
    print('\n\n2. CAMPAIGN EMAIL RECIPIENTS');
    print('=============================');

    // Get email recipients for a campaign
    print('\nGetting email recipients for campaign...');
    final campaignRecipients = await core.unifiedEmailService.getEmailRecipientsForCampaign(
      campaignId: 'campaign-uuid-123',
      listIds: ['list-uuid-1', 'list-uuid-2'],
      status: 'active',
    );
    
    print('Found ${campaignRecipients.length} recipients for campaign');
    print('Recipients by source:');
    final subscribers = campaignRecipients.where((r) => r.source == 'subscribers').length;
    final users = campaignRecipients.where((r) => r.source == 'users').length;
    print('- Subscribers: $subscribers');
    print('- Users: $users');

    // ========== EMAIL SENDING WITH UNIFIED RECIPIENTS ==========
    print('\n\n3. EMAIL SENDING WITH UNIFIED RECIPIENTS');
    print('==========================================');

    if (core.mailtrapService != null) {
      // Send email to all active recipients
      print('\nSending email to active recipients...');
      final activeRecipientsForEmail = await core.unifiedEmailService.getEmailRecipientsByStatus('active');
      
      for (final recipient in activeRecipientsForEmail.take(3)) { // Limit to 3 for demo
        try {
          await core.mailtrapService!.sendTransactionalEmail(
            toEmail: recipient.email,
            subject: 'Hello ${recipient.displayName}!',
            body: '''
              <h1>Hello ${recipient.displayName}!</h1>
              <p>This is a test email sent via the unified email service.</p>
              <p>Your details:</p>
              <ul>
                <li>Email: ${recipient.email}</li>
                <li>Status: ${recipient.status}</li>
                <li>Source: ${recipient.source}</li>
                <li>Active: ${recipient.isActive}</li>
              </ul>
              ${recipient.hasSubscriptions ? '<p>You are subscribed to ${recipient.subscriptions?.length ?? 0} lists.</p>' : ''}
            ''',
            templateData: {
              'recipient_name': recipient.displayName,
              'recipient_email': recipient.email,
              'recipient_status': recipient.status,
              'recipient_source': recipient.source,
              'is_active': recipient.isActive.toString(),
            },
          );
          print('✓ Email sent to ${recipient.email} (${recipient.source})');
        } catch (e) {
          print('✗ Failed to send email to ${recipient.email}: $e');
        }
      }
    } else {
      print('Mailtrap service not configured - email sending not available');
    }

    // ========== ADVANCED QUERIES ==========
    print('\n\n4. ADVANCED QUERIES');
    print('====================');

    // Query with complex filters
    print('\nComplex query with multiple filters...');
    final complexResults = await core.unifiedEmailService.queryEmailRecipients(
      searchStr: 'company',
      sources: ['users'], // Only users collection
      status: 'active',
      orderBy: 'createdAt',
      order: SortOrder.desc,
      limit: 5,
    );
    
    print('Complex query results:');
    for (final recipient in complexResults.results) {
      print('- ${recipient.email} (${recipient.source}) - Created: ${recipient.createdAt}');
    }

    // Query subscribers only
    print('\nQuerying subscribers only...');
    final subscriberResults = await core.unifiedEmailService.queryEmailRecipients(
      sources: ['subscribers'],
      status: 'enabled',
      orderBy: 'email',
      limit: 10,
    );
    
    print('Subscribers only:');
    for (final recipient in subscriberResults.results) {
      print('- ${recipient.email} - Lists: ${recipient.subscriptions?.length ?? 0}');
    }

    // Query users only
    print('\nQuerying users only...');
    final userResults = await core.unifiedEmailService.queryEmailRecipients(
      sources: ['users'],
      status: 'active',
      orderBy: 'lastActivityAt',
      order: SortOrder.desc,
      limit: 10,
    );
    
    print('Users only:');
    for (final recipient in userResults.results) {
      print('- ${recipient.email} - Last activity: ${recipient.lastActivityAt}');
    }

    // ========== ANALYTICS WITH UNIFIED DATA ==========
    print('\n\n5. ANALYTICS WITH UNIFIED DATA');
    print('===============================');

    // Get comprehensive email statistics
    print('\nGetting comprehensive email statistics...');
    final allStatusCounts = await core.unifiedEmailService.getEmailRecipientCountByStatus();
    
    print('Email recipient statistics:');
    allStatusCounts.forEach((status, count) {
      print('- $status: $count');
    });

    // Calculate total unique email addresses
    final totalSubscribers = allStatusCounts.entries
        .where((e) => e.key.startsWith('subscribers_'))
        .fold(0, (sum, e) => sum + e.value);
    
    final totalUsers = allStatusCounts.entries
        .where((e) => e.key.startsWith('users_'))
        .fold(0, (sum, e) => sum + e.value);
    
    print('\nTotal counts:');
    print('- Subscribers: $totalSubscribers');
    print('- Users: $totalUsers');
    print('- Total unique emails: ${totalSubscribers + totalUsers}');

    print('\n=== Example completed successfully! ===');

  } catch (e) {
    print('Error: $e');
  } finally {
    // Close the database connection
    await core.close();
  }
}