import 'package:test/test.dart';
import 'package:listmonk_dart/listmonk_dart.dart';

void main() {
  group('Exception Tests', () {
    test('ValidationException should have proper message and code', () {
      const exception = ValidationException('Invalid email', code: 'EMAIL_INVALID');
      expect(exception.message, equals('Invalid email'));
      expect(exception.code, equals('EMAIL_INVALID'));
      expect(exception.toString(), contains('ListmonkException: Invalid email'));
    });

    test('DuplicateException should have proper message and code', () {
      const exception = DuplicateException('Email already exists', code: 'EMAIL_EXISTS');
      expect(exception.message, equals('Email already exists'));
      expect(exception.code, equals('EMAIL_EXISTS'));
    });

    test('DatabaseException should have proper message and code', () {
      const exception = DatabaseException('Connection failed', code: 'DB_CONNECTION');
      expect(exception.message, equals('Connection failed'));
      expect(exception.code, equals('DB_CONNECTION'));
    });

    test('EmailException should have proper message and code', () {
      const exception = EmailException('SMTP error', code: 'SMTP_ERROR');
      expect(exception.message, equals('SMTP error'));
      expect(exception.code, equals('SMTP_ERROR'));
    });

    test('NotFoundException should have proper message and code', () {
      const exception = NotFoundException('Subscriber not found', code: 'NOT_FOUND');
      expect(exception.message, equals('Subscriber not found'));
      expect(exception.code, equals('NOT_FOUND'));
    });
  });
}