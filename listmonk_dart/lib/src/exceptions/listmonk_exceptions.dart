/// Custom exceptions for the Listmonk Dart package

/// Base exception for all Listmonk-related errors
abstract class ListmonkException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const ListmonkException(this.message, {this.code, this.details});

  @override
  String toString() => 'ListmonkException: $message';
}

/// Database-related exceptions
class DatabaseException extends ListmonkException {
  const DatabaseException(super.message, {super.code, super.details});
}

/// Validation-related exceptions
class ValidationException extends ListmonkException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Email-related exceptions
class EmailException extends ListmonkException {
  const EmailException(super.message, {super.code, super.details});
}

/// Subscriber-related exceptions
class SubscriberException extends ListmonkException {
  const SubscriberException(super.message, {super.code, super.details});
}

/// Campaign-related exceptions
class CampaignException extends ListmonkException {
  const CampaignException(super.message, {super.code, super.details});
}

/// List-related exceptions
class ListException extends ListmonkException {
  const ListException(super.message, {super.code, super.details});
}

/// Template-related exceptions
class TemplateException extends ListmonkException {
  const TemplateException(super.message, {super.code, super.details});
}

/// Analytics-related exceptions
class AnalyticsException extends ListmonkException {
  const AnalyticsException(super.message, {super.code, super.details});
}

/// SMTP-related exceptions
class SmtpException extends ListmonkException {
  const SmtpException(super.message, {super.code, super.details});
}

/// Not found exceptions
class NotFoundException extends ListmonkException {
  const NotFoundException(super.message, {super.code, super.details});
}

/// Duplicate entry exceptions
class DuplicateException extends ListmonkException {
  const DuplicateException(super.message, {super.code, super.details});
}

/// Configuration exceptions
class ConfigurationException extends ListmonkException {
  const ConfigurationException(super.message, {super.code, super.details});
}

/// Authentication exceptions
class AuthenticationException extends ListmonkException {
  const AuthenticationException(super.message, {super.code, super.details});
}

/// Authorization exceptions
class AuthorizationException extends ListmonkException {
  const AuthorizationException(super.message, {super.code, super.details});
}