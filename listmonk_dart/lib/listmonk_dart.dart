/// A Dart package providing core listmonk functionality for subscriber and campaign management.
/// 
/// This package translates the core backend logic from the original Go implementation to Dart,
/// designed to work with MongoDB instead of PostgreSQL.
library listmonk_dart;

// Core
export 'src/core/listmonk_core.dart';

// Models
export 'src/models/base.dart';
export 'src/models/constants.dart';
export 'src/models/subscriber.dart';
export 'src/models/list.dart';
export 'src/models/campaign.dart';
export 'src/models/template.dart';
export 'src/models/bounce.dart';
export 'src/models/message.dart';

// Services
export 'src/services/subscriber_service.dart';
export 'src/services/campaign_service.dart';
export 'src/services/list_service.dart';
export 'src/services/template_service.dart';
export 'src/services/analytics_service.dart';
export 'src/services/mailtrap_service.dart';

// Utils
export 'src/utils/validation.dart';
export 'src/utils/logger.dart';
export 'src/utils/performance.dart';
export 'src/utils/database_indexes.dart';

// Exceptions
export 'src/exceptions/listmonk_exceptions.dart';