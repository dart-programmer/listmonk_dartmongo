import '../exceptions/listmonk_exceptions.dart';

/// Validation utilities for the Listmonk Dart package
class ValidationUtils {
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate email format and throw exception if invalid
  static void validateEmail(String email) {
    if (email.isEmpty) {
      throw ValidationException('Email cannot be empty', code: 'EMAIL_EMPTY');
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      throw ValidationException('Invalid email format: $email', code: 'EMAIL_INVALID');
    }
  }

  /// Validate UUID format
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// Validate campaign status transition
  static bool isValidStatusTransition(String currentStatus, String newStatus) {
    switch (newStatus) {
      case 'draft':
        return currentStatus == 'scheduled';
      case 'scheduled':
        return currentStatus == 'draft' || currentStatus == 'paused';
      case 'running':
        return currentStatus == 'paused' || currentStatus == 'draft';
      case 'paused':
        return currentStatus == 'running';
      case 'cancelled':
        return currentStatus == 'running' || currentStatus == 'paused';
      case 'finished':
        return currentStatus == 'running';
      default:
        return false;
    }
  }

  /// Validate required fields
  static List<String> validateRequiredFields(Map<String, dynamic> data, List<String> requiredFields) {
    final missingFields = <String>[];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null || data[field].toString().trim().isEmpty) {
        missingFields.add(field);
      }
    }
    
    return missingFields;
  }

  /// Sanitize email address
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Sanitize name
  static String sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validate list IDs
  static bool isValidListIds(List<int> listIds) {
    return listIds.isNotEmpty && listIds.every((id) => id > 0);
  }

  /// Validate campaign content type
  static bool isValidContentType(String contentType) {
    const validTypes = ['richtext', 'html', 'markdown', 'plain', 'visual'];
    return validTypes.contains(contentType);
  }

  /// Validate subscriber status
  static bool isValidSubscriberStatus(String status) {
    const validStatuses = ['enabled', 'disabled', 'blocklisted'];
    return validStatuses.contains(status);
  }

  /// Validate subscription status
  static bool isValidSubscriptionStatus(String status) {
    const validStatuses = ['unconfirmed', 'confirmed', 'unsubscribed'];
    return validStatuses.contains(status);
  }

  /// Validate list type
  static bool isValidListType(String type) {
    const validTypes = ['private', 'public'];
    return validTypes.contains(type);
  }

  /// Validate opt-in type
  static bool isValidOptinType(String optin) {
    const validOptins = ['single', 'double'];
    return validOptins.contains(optin);
  }

  /// Validate bounce type
  static bool isValidBounceType(String type) {
    const validTypes = ['hard', 'soft', 'complaint'];
    return validTypes.contains(type);
  }

  /// Validate template type
  static bool isValidTemplateType(String type) {
    const validTypes = ['campaign', 'campaign_visual', 'tx'];
    return validTypes.contains(type);
  }

  /// Validate pagination parameters
  static bool isValidPagination(int offset, int limit) {
    return offset >= 0 && limit > 0 && limit <= 1000; // Max 1000 items per page
  }

  /// Validate date range
  static bool isValidDateRange(DateTime fromDate, DateTime toDate) {
    return fromDate.isBefore(toDate) || fromDate.isAtSameMomentAs(toDate);
  }

  /// Validate search string
  static bool isValidSearchString(String? searchStr) {
    if (searchStr == null) return true;
    return searchStr.length >= 2 && searchStr.length <= 100;
  }

  /// Validate tags
  static List<String> sanitizeTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim().toLowerCase().replaceAll(RegExp(r'[^\w\-]'), '-'))
        .where((tag) => tag.isNotEmpty && tag.length <= 50)
        .toList();
  }

  /// Validate JSON attributes
  static bool isValidJsonAttributes(Map<String, dynamic> attribs) {
    // Check if all values are serializable
    try {
      // This will throw if any value is not serializable
      attribs.toString();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate campaign send time
  static bool isValidSendTime(DateTime? sendAt) {
    if (sendAt == null) return true;
    return sendAt.isAfter(DateTime.now());
  }

  /// Validate archive slug
  static bool isValidArchiveSlug(String? slug) {
    if (slug == null) return true;
    return RegExp(r'^[a-z0-9\-]+$').hasMatch(slug) && slug.length <= 100;
  }
}