import 'package:listmonk_dart/listmonk_dart.dart';

/// Example usage of the Listmonk Dart package with Mailtrap integration
Future<void> main() async {
  // Initialize the core service with Mailtrap configuration
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
  );

  try {
    // Test Mailtrap connection
    print('Testing Mailtrap connection...');
    if (core.mailtrapService != null) {
      final isConnected = await core.mailtrapService!.testConnection();
      print('Mailtrap connection: ${isConnected ? "Success" : "Failed"}');
    }

    // Create a mailing list
    print('\nCreating mailing list...');
    final list = await core.listService.createList(List(
      name: 'Newsletter Subscribers',
      type: ListType.private,
      optin: ListOptin.double,
      tags: ['newsletter', 'marketing'],
      description: 'Main newsletter for product updates',
    ));
    print('Created list: ${list.name} (ID: ${list.id})');

    // Create a subscriber
    print('\nCreating subscriber...');
    final subscriber = await core.subscriberService.createSubscriber(
      Subscriber(
        email: 'john.doe@example.com',
        name: 'John Doe',
        status: SubscriberStatus.enabled,
        attribs: {
          'company': 'Acme Corp',
          'industry': 'Technology',
          'location': 'San Francisco',
        },
        lists: [],
      ),
      listIds: [list.id!],
    );
    print('Created subscriber: ${subscriber.email} (UUID: ${subscriber.uuid})');

    // Send opt-in confirmation email
    if (core.mailtrapService != null) {
      print('\nSending opt-in confirmation email...');
      try {
        await core.mailtrapService!.sendOptinConfirmation(
          subscriber: subscriber,
          lists: [list],
          confirmUrl: 'https://yourdomain.com/confirm?token=${subscriber.uuid}',
          unsubscribeUrl: 'https://yourdomain.com/unsubscribe?token=${subscriber.uuid}',
        );
        print('Opt-in confirmation email sent successfully');
      } catch (e) {
        print('Failed to send opt-in confirmation: $e');
      }
    }

    // Create an email template
    print('\nCreating email template...');
    final template = await core.templateService.createTemplate(Template(
      name: 'Welcome Email',
      subject: 'Welcome to our newsletter, {{subscriber.name}}!',
      type: TemplateType.tx,
      body: '''
        <h1>Welcome {{subscriber.name}}!</h1>
        <p>Thank you for subscribing to our newsletter.</p>
        <p>We're excited to have you on board!</p>
        <p>Best regards,<br>The Team</p>
      ''',
      isDefault: true,
    ));
    print('Created template: ${template.name} (ID: ${template.id})');

    // Create a campaign
    print('\nCreating campaign...');
    final campaign = await core.campaignService.createCampaign(
      Campaign(
        name: 'Welcome Campaign',
        subject: 'Welcome to our newsletter, {{subscriber.name}}!',
        fromEmail: 'noreply@yourdomain.com',
        body: '''
          <h1>Welcome {{subscriber.name}}!</h1>
          <p>Thank you for subscribing to our newsletter. We'll keep you updated with our latest news.</p>
          <p>Your company: {{subscriber.attribs.company}}</p>
          <p>Location: {{subscriber.attribs.location}}</p>
          <p><a href="{{unsubscribe_url}}">Unsubscribe</a></p>
        ''',
        contentType: CampaignContentType.html,
        type: CampaignType.regular,
        messenger: 'email',
        archive: true,
        archiveSlug: 'welcome-campaign',
        archiveMeta: {},
        mediaIds: [],
        attachments: [],
        meta: CampaignMeta(
          campaignId: 0,
          views: 0,
          clicks: 0,
          bounces: 0,
          lists: [],
          media: [],
          toSend: 0,
          sent: 0,
        ),
        total: 0,
      ),
      listIds: [list.id!],
    );
    print('Created campaign: ${campaign.name} (UUID: ${campaign.uuid})');

    // Send campaign email to subscriber
    if (core.mailtrapService != null) {
      print('\nSending campaign email...');
      try {
        await core.mailtrapService!.sendCampaignEmail(
          campaign: campaign,
          subscriber: subscriber,
        );
        print('Campaign email sent successfully');
      } catch (e) {
        print('Failed to send campaign email: $e');
      }
    }

    // Send transactional email
    if (core.mailtrapService != null) {
      print('\nSending transactional email...');
      try {
        await core.mailtrapService!.sendTransactionalEmail(
          toEmail: subscriber.email,
          subject: 'Test Transactional Email',
          body: '''
            <h1>Test Email</h1>
            <p>This is a test transactional email sent via Mailtrap.</p>
            <p>Subscriber: ${subscriber.name}</p>
            <p>Company: ${subscriber.attribs['company']}</p>
          ''',
          templateData: {
            'subscriber_name': subscriber.name,
            'subscriber_email': subscriber.email,
            'company': subscriber.attribs['company'],
          },
        );
        print('Transactional email sent successfully');
      } catch (e) {
        print('Failed to send transactional email: $e');
      }
    }

    // Update campaign status to scheduled
    print('\nScheduling campaign...');
    final scheduledCampaign = await core.campaignService.updateCampaignStatus(
      campaign.id!,
      CampaignStatus.scheduled,
    );
    print('Campaign status updated to: ${scheduledCampaign.status}');

    // Query subscribers
    print('\nQuerying subscribers...');
    final subscriberResults = await core.subscriberService.querySubscribers(
      searchStr: 'john',
      limit: 10,
    );
    print('Found ${subscriberResults.total} subscribers');
    for (final sub in subscriberResults.results) {
      print('- ${sub.name} (${sub.email}) - Status: ${sub.status}');
    }

    // Query campaigns
    print('\nQuerying campaigns...');
    final campaignResults = await core.campaignService.queryCampaigns(
      limit: 10,
    );
    print('Found ${campaignResults.total} campaigns');
    for (final camp in campaignResults.results) {
      print('- ${camp.name} - Status: ${camp.status}');
    }

    // Get dashboard statistics
    print('\nGetting dashboard statistics...');
    final stats = await core.analyticsService.getDashboardStats();
    print('Dashboard stats:');
    stats.forEach((key, value) {
      print('- $key: $value');
    });

    // Register a campaign view (simulating a subscriber viewing the campaign)
    print('\nRegistering campaign view...');
    await core.analyticsService.registerCampaignView(
      campaignUuid: campaign.uuid,
      subscriberUuid: subscriber.uuid,
    );
    print('Campaign view registered');

    // Register a link click (simulating a subscriber clicking a link)
    print('\nRegistering link click...');
    await core.analyticsService.registerLinkClick(
      linkUuid: 'example-link-uuid',
      campaignUuid: campaign.uuid,
      subscriberUuid: subscriber.uuid,
      url: 'https://yourdomain.com/unsubscribe',
    );
    print('Link click registered');

    // Get campaign analytics
    print('\nGetting campaign analytics...');
    final analytics = await core.analyticsService.getCampaignAnalyticsCounts(
      campaignIds: [campaign.id!],
      type: CampaignAnalytics.views,
      fromDate: DateTime.now().subtract(const Duration(days: 30)),
      toDate: DateTime.now(),
    );
    print('Campaign views in last 30 days: ${analytics.length}');

    print('\nMailtrap integration example completed successfully!');

  } catch (e) {
    print('Error: $e');
  } finally {
    // Close the database connection
    await core.close();
  }
}