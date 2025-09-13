import 'package:mongo_dart/mongo_dart.dart';
import '../models/constants.dart';
import '../services/subscriber_service.dart';
import '../services/campaign_service.dart';
import '../services/list_service.dart';
import '../services/template_service.dart';
import '../services/analytics_service.dart';

/// Core Listmonk service that provides access to all functionality
class ListmonkCore {
  final Db _db;
  final SubscriberService _subscriberService;
  final CampaignService _campaignService;
  final ListService _listService;
  final TemplateService _templateService;
  final AnalyticsService _analyticsService;

  ListmonkCore._({
    required Db db,
    required SubscriberService subscriberService,
    required CampaignService campaignService,
    required ListService listService,
    required TemplateService templateService,
    required AnalyticsService analyticsService,
  }) : _db = db,
       _subscriberService = subscriberService,
       _campaignService = campaignService,
       _listService = listService,
       _templateService = templateService,
       _analyticsService = analyticsService;

  /// Factory constructor to create a new ListmonkCore instance
  static Future<ListmonkCore> create({
    required String mongoUri,
    String? databaseName,
  }) async {
    final db = Db(mongoUri);
    await db.open();

    final databaseName = databaseName ?? 'listmonk';
    final database = db.database(databaseName);

    // Initialize services
    final subscriberService = SubscriberService(database);
    final campaignService = CampaignService(database);
    final listService = ListService(database);
    final templateService = TemplateService(database);
    final analyticsService = AnalyticsService(database);

    return ListmonkCore._(
      db: db,
      subscriberService: subscriberService,
      campaignService: campaignService,
      listService: listService,
      templateService: templateService,
      analyticsService: analyticsService,
    );
  }

  /// Get the subscriber service
  SubscriberService get subscriberService => _subscriberService;

  /// Get the campaign service
  CampaignService get campaignService => _campaignService;

  /// Get the list service
  ListService get listService => _listService;

  /// Get the template service
  TemplateService get templateService => _templateService;

  /// Get the analytics service
  AnalyticsService get analyticsService => _analyticsService;

  /// Close the database connection
  Future<void> close() async {
    await _db.close();
  }

  /// Get database health status
  Future<bool> isHealthy() async {
    try {
      await _db.eval('ping');
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Configuration constants for the core service
class CoreConstants {
  final bool sendOptinConfirmation;
  final Map<String, BounceAction> bounceActions;
  final bool cacheSlowQueries;

  const CoreConstants({
    this.sendOptinConfirmation = true,
    this.bounceActions = const {},
    this.cacheSlowQueries = false,
  });
}

/// Bounce action configuration
class BounceAction {
  final int count;
  final String action;

  const BounceAction({
    required this.count,
    required this.action,
  });
}