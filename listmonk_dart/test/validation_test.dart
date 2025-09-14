import 'package:test/test.dart';
import 'package:listmonk_dart/listmonk_dart.dart';

void main() {
  group('Validation Tests', () {
    test('Email validation should work correctly', () {
      expect(ValidationUtils.isValidEmail('test@example.com'), isTrue);
      expect(ValidationUtils.isValidEmail('user.name+tag@domain.co.uk'), isTrue);
      expect(ValidationUtils.isValidEmail('invalid-email'), isFalse);
      expect(ValidationUtils.isValidEmail(''), isFalse);
      expect(ValidationUtils.isValidEmail('test@'), isFalse);
    });

    test('Email validation should throw exception for invalid emails', () {
      expect(() => ValidationUtils.validateEmail(''), throwsA(isA<ValidationException>()));
      expect(() => ValidationUtils.validateEmail('invalid-email'), throwsA(isA<ValidationException>()));
      expect(() => ValidationUtils.validateEmail('test@example.com'), returnsNormally);
    });

    test('UUID validation should work correctly', () {
      expect(ValidationUtils.isValidUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(ValidationUtils.isValidUuid('invalid-uuid'), isFalse);
      expect(ValidationUtils.isValidUuid(''), isFalse);
    });

    test('Status validation should work correctly', () {
      expect(ValidationUtils.isValidSubscriberStatus('enabled'), isTrue);
      expect(ValidationUtils.isValidSubscriberStatus('disabled'), isTrue);
      expect(ValidationUtils.isValidSubscriberStatus('blocklisted'), isTrue);
      expect(ValidationUtils.isValidSubscriberStatus('invalid'), isFalse);

      expect(ValidationUtils.isValidSubscriptionStatus('confirmed'), isTrue);
      expect(ValidationUtils.isValidSubscriptionStatus('unconfirmed'), isTrue);
      expect(ValidationUtils.isValidSubscriptionStatus('unsubscribed'), isTrue);
      expect(ValidationUtils.isValidSubscriptionStatus('invalid'), isFalse);
    });

    test('Content type validation should work correctly', () {
      expect(ValidationUtils.isValidContentType('html'), isTrue);
      expect(ValidationUtils.isValidContentType('markdown'), isTrue);
      expect(ValidationUtils.isValidContentType('plain'), isTrue);
      expect(ValidationUtils.isValidContentType('invalid'), isFalse);
    });

    test('List type validation should work correctly', () {
      expect(ValidationUtils.isValidListType('private'), isTrue);
      expect(ValidationUtils.isValidListType('public'), isTrue);
      expect(ValidationUtils.isValidListType('invalid'), isFalse);
    });

    test('Opt-in type validation should work correctly', () {
      expect(ValidationUtils.isValidOptinType('single'), isTrue);
      expect(ValidationUtils.isValidOptinType('double'), isTrue);
      expect(ValidationUtils.isValidOptinType('invalid'), isFalse);
    });

    test('Pagination validation should work correctly', () {
      expect(ValidationUtils.isValidPagination(0, 10), isTrue);
      expect(ValidationUtils.isValidPagination(10, 50), isTrue);
      expect(ValidationUtils.isValidPagination(-1, 10), isFalse);
      expect(ValidationUtils.isValidPagination(0, 0), isFalse);
      expect(ValidationUtils.isValidPagination(0, 1001), isFalse);
    });

    test('Date range validation should work correctly', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 1));
      final past = now.subtract(const Duration(days: 1));

      expect(ValidationUtils.isValidDateRange(past, now), isTrue);
      expect(ValidationUtils.isValidDateRange(now, future), isTrue);
      expect(ValidationUtils.isValidDateRange(now, now), isTrue);
      expect(ValidationUtils.isValidDateRange(future, past), isFalse);
    });

    test('Search string validation should work correctly', () {
      expect(ValidationUtils.isValidSearchString(null), isTrue);
      expect(ValidationUtils.isValidSearchString('test'), isTrue);
      expect(ValidationUtils.isValidSearchString('a'), isFalse);
      expect(ValidationUtils.isValidSearchString('a' * 101), isFalse);
    });

    test('Tag sanitization should work correctly', () {
      final tags = ['Test Tag', 'Another-Tag', 'tag with spaces', 'Special@Chars!'];
      final sanitized = ValidationUtils.sanitizeTags(tags);
      
      expect(sanitized, equals(['test-tag', 'another-tag', 'tag-with-spaces', 'special-chars']));
    });

    test('Email sanitization should work correctly', () {
      expect(ValidationUtils.sanitizeEmail('  Test@Example.COM  '), equals('test@example.com'));
      expect(ValidationUtils.sanitizeEmail('user@domain.com'), equals('user@domain.com'));
    });

    test('Name sanitization should work correctly', () {
      expect(ValidationUtils.sanitizeName('  John   Doe  '), equals('John Doe'));
      expect(ValidationUtils.sanitizeName('Jane\tSmith\n'), equals('Jane Smith'));
    });

    test('Archive slug validation should work correctly', () {
      expect(ValidationUtils.isValidArchiveSlug('valid-slug'), isTrue);
      expect(ValidationUtils.isValidArchiveSlug('another-valid-slug-123'), isTrue);
      expect(ValidationUtils.isValidArchiveSlug('invalid slug'), isFalse);
      expect(ValidationUtils.isValidArchiveSlug('invalid@slug'), isFalse);
      expect(ValidationUtils.isValidArchiveSlug('a' * 101), isFalse);
    });
  });
}