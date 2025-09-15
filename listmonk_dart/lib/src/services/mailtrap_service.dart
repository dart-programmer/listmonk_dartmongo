import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/subscriber.dart';
import '../models/campaign.dart';
import '../models/message.dart';
import '../utils/validation.dart';

/// Service for sending emails via Mailtrap SMTP
class MailtrapService {
  final SmtpServer _smtpServer;
  final String _fromEmail;
  final String _fromName;

  MailtrapService({
    required String host,
    required int port,
    required String username,
    required String password,
    required String fromEmail,
    String? fromName,
    bool useTls = true,
  }) : _smtpServer = SmtpServer(
          host,
          port: port,
          username: username,
          password: password,
          allowInsecure: !useTls,
          ignoreBadCertificate: false,
        ),
        _fromEmail = fromEmail,
        _fromName = fromName ?? fromEmail.split('@').first;

  /// Factory constructor for Mailtrap SMTP
  factory MailtrapService.mailtrap({
    required String username,
    required String password,
    required String fromEmail,
    String? fromName,
    bool useTls = true,
  }) {
    return MailtrapService(
      host: 'smtp.mailtrap.io',
      port: 587,
      username: username,
      password: password,
      fromEmail: fromEmail,
      fromName: fromName,
      useTls: useTls,
    );
  }

  /// Send a single email message
  Future<SendReport> sendMessage(Message message) async {
    try {
      return await send(message, _smtpServer);
    } on MailerException catch (e) {
      throw Exception('Failed to send email: ${e.message}');
    }
  }

  /// Send a campaign email to a subscriber
  Future<SendReport> sendCampaignEmail({
    required Campaign campaign,
    required Subscriber subscriber,
    String? customSubject,
    String? customBody,
  }) async {
    // Validate inputs
    if (!ValidationUtils.isValidEmail(subscriber.email)) {
      throw ArgumentError('Invalid subscriber email: ${subscriber.email}');
    }

    if (!ValidationUtils.isValidEmail(campaign.fromEmail)) {
      throw ArgumentError('Invalid campaign from email: ${campaign.fromEmail}');
    }

    // Prepare email content
    final subject = customSubject ?? _processTemplate(campaign.subject, subscriber);
    final body = customBody ?? _processTemplate(campaign.body, subscriber);
    final altBody = campaign.altBody != null 
        ? _processTemplate(campaign.altBody!, subscriber)
        : null;

    // Create message
    final message = Message()
      ..from = Address(campaign.fromEmail, _fromName)
      ..recipients.add(subscriber.email)
      ..subject = subject
      ..html = body;

    if (altBody != null) {
      message.text = altBody;
    }

    // Add campaign headers for tracking
    message.headers = {
      'X-Listmonk-Campaign': campaign.uuid,
      'X-Listmonk-Subscriber': subscriber.uuid,
      'X-Mailer': 'Listmonk Dart',
      ...campaign.headers.fold<Map<String, String>>({}, (map, header) {
        map[header.keys.first] = header.values.first;
        return map;
      }),
    };

    // Add attachments if any
    for (final attachment in campaign.attachments) {
      message.attachments.add(FileAttachment(
        attachment.name,
        attachment.content,
        contentType: attachment.header['Content-Type'] ?? 'application/octet-stream',
      ));
    }

    return await sendMessage(message);
  }

  /// Send transactional email using template
  Future<SendReport> sendTransactionalEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? fromEmail,
    String? fromName,
    Map<String, dynamic>? templateData,
    List<Attachment>? attachments,
  }) async {
    // Validate inputs
    if (!ValidationUtils.isValidEmail(toEmail)) {
      throw ArgumentError('Invalid recipient email: $toEmail');
    }

    final senderEmail = fromEmail ?? _fromEmail;
    final senderName = fromName ?? _fromName;

    if (!ValidationUtils.isValidEmail(senderEmail)) {
      throw ArgumentError('Invalid sender email: $senderEmail');
    }

    // Process template if data provided
    String processedSubject = subject;
    String processedBody = body;

    if (templateData != null) {
      processedSubject = _processTemplateWithData(subject, templateData);
      processedBody = _processTemplateWithData(body, templateData);
    }

    // Create message
    final message = Message()
      ..from = Address(senderEmail, senderName)
      ..recipients.add(toEmail)
      ..subject = processedSubject
      ..html = processedBody
      ..headers = {
        'X-Mailer': 'Listmonk Dart',
      };

    // Add attachments if any
    if (attachments != null) {
      for (final attachment in attachments) {
        message.attachments.add(FileAttachment(
          attachment.name,
          attachment.content,
          contentType: attachment.header['Content-Type'] ?? 'application/octet-stream',
        ));
      }
    }

    return await sendMessage(message);
  }

  /// Send opt-in confirmation email
  Future<SendReport> sendOptinConfirmation({
    required Subscriber subscriber,
    required List<List> lists,
    required String confirmUrl,
    required String unsubscribeUrl,
  }) async {
    final subject = 'Confirm your subscription';
    
    final body = '''
      <html>
        <body>
          <h1>Confirm Your Subscription</h1>
          <p>Hello ${subscriber.name},</p>
          <p>Thank you for subscribing to our newsletter(s):</p>
          <ul>
            ${lists.map((list) => '<li>${list.name}</li>').join()}
          </ul>
          <p>Please click the link below to confirm your subscription:</p>
          <p><a href="$confirmUrl">Confirm Subscription</a></p>
          <p>If you didn't request this subscription, you can ignore this email.</p>
          <p>To unsubscribe, <a href="$unsubscribeUrl">click here</a>.</p>
        </body>
      </html>
    ''';

    return await sendTransactionalEmail(
      toEmail: subscriber.email,
      subject: subject,
      body: body,
    );
  }

  /// Send welcome email
  Future<SendReport> sendWelcomeEmail({
    required Subscriber subscriber,
    required List<List> lists,
    required String manageUrl,
  }) async {
    final subject = 'Welcome to our newsletter!';
    
    final body = '''
      <html>
        <body>
          <h1>Welcome ${subscriber.name}!</h1>
          <p>Thank you for subscribing to our newsletter(s):</p>
          <ul>
            ${lists.map((list) => '<li>${list.name}</li>').join()}
          </ul>
          <p>We're excited to have you on board!</p>
          <p>You can manage your subscription preferences <a href="$manageUrl">here</a>.</p>
        </body>
      </html>
    ''';

    return await sendTransactionalEmail(
      toEmail: subscriber.email,
      subject: subject,
      body: body,
    );
  }

  /// Send unsubscribe confirmation
  Future<SendReport> sendUnsubscribeConfirmation({
    required Subscriber subscriber,
    required List<List> lists,
  }) async {
    final subject = 'You have been unsubscribed';
    
    final body = '''
      <html>
        <body>
          <h1>Unsubscribed Successfully</h1>
          <p>Hello ${subscriber.name},</p>
          <p>You have been unsubscribed from the following newsletter(s):</p>
          <ul>
            ${lists.map((list) => '<li>${list.name}</li>').join()}
          </ul>
          <p>You will no longer receive emails from these lists.</p>
          <p>If this was a mistake, please contact us to resubscribe.</p>
        </body>
      </html>
    ''';

    return await sendTransactionalEmail(
      toEmail: subscriber.email,
      subject: subject,
      body: body,
    );
  }

  /// Process template with subscriber data
  String _processTemplate(String template, Subscriber subscriber) {
    return template
        .replaceAll('{{subscriber.name}}', subscriber.name)
        .replaceAll('{{subscriber.email}}', subscriber.email)
        .replaceAll('{{subscriber.first_name}}', subscriber.firstName)
        .replaceAll('{{subscriber.last_name}}', subscriber.lastName)
        .replaceAll('{{subscriber.uuid}}', subscriber.uuid);
  }

  /// Process template with custom data
  String _processTemplateWithData(String template, Map<String, dynamic> data) {
    String result = template;
    
    data.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    
    return result;
  }

  /// Test SMTP connection
  Future<bool> testConnection() async {
    try {
      final message = Message()
        ..from = Address(_fromEmail, _fromName)
        ..recipients.add(_fromEmail) // Send to self for testing
        ..subject = 'Test Connection'
        ..text = 'This is a test email to verify SMTP connection.';

      await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}