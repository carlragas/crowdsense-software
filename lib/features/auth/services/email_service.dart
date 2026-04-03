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
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f4f8; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); border: 1px solid #e1e8ed; }
        .header { background-color: #0F172A; color: #ffffff; padding: 32px 24px; text-align: center; } /* Deeper Dark Blue */
        .header h1 { margin: 0; font-size: 26px; font-weight: 700; letter-spacing: -0.5px; }
        .header h1 span { color: #EF4444; } /* Red accent */
        .header p { margin: 10px 0 0; font-size: 14px; opacity: 0.8; font-weight: 500; }
        .content { padding: 40px; background-color: #EFF6FF; } /* Lighter blue body */
        .greeting { font-size: 16px; margin-bottom: 24px; line-height: 1.6; }
        .credentials-box { border: 1px solid #bfdbfe; border-radius: 12px; padding: 24px; background-color: #ffffff; margin-bottom: 24px; box-shadow: 0 2px 4px rgba(0,0,0,0.02); }
        .grid { display: grid; grid-template-columns: 140px 1fr; gap: 16px; font-size: 15px; }
        .label { color: #64748b; font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.05em; }
        .val { font-weight: 700; color: #1e293b; }
        .warning-box { background-color: #fff7ed; border: 1px solid #fed7aa; border-radius: 8px; padding: 16px; margin-bottom: 24px; }
        .warning-title { color: #c2410c; font-weight: bold; margin-bottom: 4px; display: flex; align-items: center; }
        .warning-title span { margin-left: 6px; }
        .warning-text { color: #c2410c; font-size: 13px; margin: 0; }
        .footer { padding: 24px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; background-color: #f8fafc; }
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
                Your account has been created successfully. Please use the temporary credentials below to access the system:
            </div>
            
            <div class="credentials-box">
                <div class="grid">
                    <div class="label">Username</div>
                    <div class="val">$username</div>
                    
                    <div class="label">Temporary Password</div>
                    <div class="val" style="font-family: 'Courier New', Courier, monospace; font-size: 18px; color: #1e40af;">$tempPassword</div>
                    
                    <div class="label">System Role</div>
                    <div class="val" style="text-transform: capitalize;">$role</div>
                </div>
            </div>
 
            <div class="warning-box">
                <div class="warning-title">⚠️ <span>Important Security Note</span></div>
                <p class="warning-text">For your protection, you will be required to change this temporary password immediately upon your first login.</p>
            </div>
        </div>
        <div class="footer">
            This is an automated message from the CrowdSense App. Please do not reply.
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
