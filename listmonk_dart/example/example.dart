import 'package:listmonk_dart/listmonk_dart.dart';

/// Example usage of the Listmonk Dart package
Future<void> main() async {
  // Initialize the core service
  final core = await ListmonkCore.create(
    mongoUri: 'mongodb://localhost:27017',
    databaseName: 'listmonk_example',
  );

  try {
    // Create a mailing list
    print('Creating mailing list...');
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
        subject: 'Welcome to our newsletter!',
        fromEmail: 'noreply@example.com',
        body: '''
          <h1>Welcome to our newsletter!</h1>
          <p>Thank you for subscribing. We'll keep you updated with our latest news.</p>
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
      url: 'https://example.com/unsubscribe',
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

    print('\nExample completed successfully!');

  } catch (e) {
    print('Error: $e');
  } finally {
    // Close the database connection
    await core.close();
  }
}