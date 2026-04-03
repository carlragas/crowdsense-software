import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static Future<void> sendWelcomeEmail({
    required String targetEmail,
    required String name,
    required String username,
    required String tempPassword,
    required String role,
  }) async {
    final senderEmail = dotenv.env['SMTP_EMAIL'];
    final appPassword = dotenv.env['SMTP_PASSWORD'];

    // If not configured, just return early entirely or throw error
    if (senderEmail == null || senderEmail.isEmpty || appPassword == null || appPassword.isEmpty) {
      throw Exception('SMTP Configuration Missing: Unable to load credentials from .env. Received: Email (\$senderEmail), Pass (\$appPassword)');
    }

    final smtpServer = gmail(senderEmail, appPassword);

    final String htmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f7f9fc; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border: 1px solid #e1e8ed; }
        .header { background-color: #1E1E2E; color: #ffffff; padding: 24px; text-align: center; } /* CrowdSense Dark Navy */
        .header h1 { margin: 0; font-size: 24px; font-weight: 600; }
        .header h1 span { color: #EF4444; } /* Red accent */
        .header p { margin: 8px 0 0; font-size: 14px; opacity: 0.8; }
        .content { padding: 32px; }
        .greeting { font-size: 16px; margin-bottom: 24px; }
        .credentials-box { border: 1px solid #e1e8ed; border-radius: 8px; padding: 24px; background-color: #f4f6f8; margin-bottom: 24px; }
        .grid { display: grid; grid-template-columns: 140px 1fr; gap: 12px; font-size: 14px; }
        .label { color: #64748b; font-weight: 600; }
        .val { font-weight: bold; color: #0f172a; }
        .warning-box { background-color: #fff7ed; border: 1px solid #fed7aa; border-radius: 8px; padding: 16px; margin-bottom: 32px; }
        .warning-title { color: #c2410c; font-weight: bold; margin-bottom: 4px; display: flex; align-items: center; }
        .warning-title span { margin-left: 6px; }
        .warning-text { color: #c2410c; font-size: 13px; margin: 0; }
        .btn-container { text-align: center; }
        .btn { display: inline-block; background-color: #EF4444; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 6px; font-weight: bold; font-size: 14px; transition: background-color 0.2s; }
        .btn:hover { background-color: #dc2626; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to Crowd<span>Sense</span></h1>
            <p>Intelligent Crowd Monitoring & Alert System</p>
        </div>
        <div class="content">
            <div class="greeting">
                Hello <strong>$name</strong>,<br><br>
                Your account has been created successfully. Here are your temporary login credentials:
            </div>
            
            <div class="credentials-box">
                <div class="grid">
                    <div class="label">Username</div>
                    <div class="val">$username</div>
                    
                    <div class="label">Temporary Password</div>
                    <div class="val" style="font-family: monospace; font-size: 16px; padding: 2px 6px; background: #e2e8f0; border-radius: 4px;">$tempPassword</div>
                    
                    <div class="label">System Role</div>
                    <div class="val" style="text-transform: capitalize;">$role</div>
                </div>
            </div>

            <div class="warning-box">
                <div class="warning-title">⚠️ <span>Important</span></div>
                <p class="warning-text">You will be required to change your password on your first login.</p>
            </div>

            <div class="btn-container">
                <a href="#" class="btn">Login to System</a>
            </div>
        </div>
    </div>
</body>
</html>
    ''';

    final message = Message()
      ..from = Address(senderEmail, 'CrowdSense System')
      ..recipients.add(targetEmail)
      ..subject = 'Welcome to CrowdSense - Your Account Details'
      ..html = htmlTemplate;

    try {
      await send(message, smtpServer);
      debugPrint('SMTP Email sent successfully to $targetEmail');
    } catch (e) {
      debugPrint('Failed to send SMTP email: $e');
      throw Exception('Failed to email temporary password.');
    }
  }
}
