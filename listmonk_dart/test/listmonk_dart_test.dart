import 'package:test/test.dart';
import 'package:listmonk_dart/listmonk_dart.dart';

void main() {
  group('Listmonk Dart Tests', () {
    test('Constants are properly defined', () {
      expect(SubscriberStatus.enabled, equals('enabled'));
      expect(SubscriberStatus.disabled, equals('disabled'));
      expect(SubscriberStatus.blocklisted, equals('blocklisted'));

      expect(CampaignStatus.draft, equals('draft'));
      expect(CampaignStatus.running, equals('running'));
      expect(CampaignStatus.finished, equals('finished'));

      expect(CampaignContentType.html, equals('html'));
      expect(CampaignContentType.markdown, equals('markdown'));

      expect(ListType.private, equals('private'));
      expect(ListType.public, equals('public'));

      expect(ListOptin.single, equals('single'));
      expect(ListOptin.double, equals('double'));
    });

    test('Subscriber model creation', () {
      final subscriber = Subscriber(
        uuid: 'test-uuid',
        email: 'test@example.com',
        name: 'Test User',
        attribs: {'company': 'Test Corp'},
        status: SubscriberStatus.enabled,
        lists: [],
      );

      expect(subscriber.email, equals('test@example.com'));
      expect(subscriber.name, equals('Test User'));
      expect(subscriber.status, equals(SubscriberStatus.enabled));
      expect(subscriber.attribs['company'], equals('Test Corp'));
    });

    test('Subscriber name parsing', () {
      final subscriber = Subscriber(
        uuid: 'test-uuid',
        email: 'test@example.com',
        name: 'John Michael Doe',
        attribs: {},
        status: SubscriberStatus.enabled,
        lists: [],
      );

      expect(subscriber.firstName, equals('John'));
      expect(subscriber.lastName, equals('Doe'));
    });

    test('Campaign model creation', () {
      final campaign = Campaign(
        uuid: 'test-uuid',
        type: CampaignType.regular,
        name: 'Test Campaign',
        subject: 'Test Subject',
        fromEmail: 'test@example.com',
        body: '<h1>Test Body</h1>',
        status: CampaignStatus.draft,
        contentType: CampaignContentType.html,
        tags: ['test', 'campaign'],
        headers: [],
        messenger: 'email',
        archive: false,
        archiveMeta: {},
        mediaIds: [],
        attachments: [],
        meta: CampaignMeta(
          campaignId: 1,
          views: 0,
          clicks: 0,
          bounces: 0,
          lists: [],
          media: [],
          toSend: 0,
          sent: 0,
        ),
        total: 0,
      );

      expect(campaign.name, equals('Test Campaign'));
      expect(campaign.type, equals(CampaignType.regular));
      expect(campaign.status, equals(CampaignStatus.draft));
      expect(campaign.contentType, equals(CampaignContentType.html));
    });

    test('List model creation', () {
      final list = List(
        uuid: 'test-uuid',
        name: 'Test List',
        type: ListType.private,
        optin: ListOptin.double,
        tags: ['test', 'list'],
        description: 'Test mailing list',
        subscriberCount: 0,
        subscriberCounts: {},
        total: 0,
      );

      expect(list.name, equals('Test List'));
      expect(list.type, equals(ListType.private));
      expect(list.optin, equals(ListOptin.double));
    });

    test('Template model creation', () {
      final template = Template(
        name: 'Test Template',
        subject: 'Test Subject',
        type: TemplateType.tx,
        body: '<h1>Test Body</h1>',
        isDefault: false,
      );

      expect(template.name, equals('Test Template'));
      expect(template.type, equals(TemplateType.tx));
      expect(template.isDefault, equals(false));
    });

    test('Bounce model creation', () {
      final bounce = Bounce(
        type: BounceType.hard,
        source: 'smtp',
        meta: {'reason': 'User unknown'},
        subscriberStatus: SubscriberStatus.blocklisted,
        total: 0,
      );

      expect(bounce.type, equals(BounceType.hard));
      expect(bounce.source, equals('smtp'));
      expect(bounce.subscriberStatus, equals(SubscriberStatus.blocklisted));
    });

    test('PageResults model creation', () {
      final results = PageResults<String>(
        results: ['item1', 'item2'],
        search: 'test',
        query: 'status:enabled',
        total: 2,
        perPage: 10,
        page: 1,
      );

      expect(results.results.length, equals(2));
      expect(results.total, equals(2));
      expect(results.search, equals('test'));
    });
  });
}