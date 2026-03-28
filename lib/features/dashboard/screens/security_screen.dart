import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_geometric_background.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _securityAlertsEnabled = true;
  String _appLockSetting = 'Off';
  final List<String> _appLockOptions = ['Off', '1 Min', '5 Mins'];

  // ─── Snackbar helpers ───────────────────────────────────────────────────────

  void _showSuccess(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppColors.statusDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // ─── Change Password Dialog ─────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? currentError;
    String? newError;
    String? confirmError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validate() {
            setDialogState(() {
              currentError = currentCtrl.text.isEmpty ? 'This field is required.' : null;
              if (newCtrl.text.length < 8) {
                newError = 'Must be at least 8 characters.';
              } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(newCtrl.text) ||
                  !RegExp(r'[0-9]').hasMatch(newCtrl.text)) {
                newError = 'Security risk: Use at least 8 characters, one special character and a number.';
              } else {
                newError = null;
              }
              confirmError = newCtrl.text != confirmCtrl.text
                  ? 'Passwords do not match. Please ensure both fields are identical.'
                  : null;
            });

            if (currentError == null && newError == null && confirmError == null) {
              // Simulate wrong current password
              if (currentCtrl.text != 'admin123') {
                Navigator.pop(context);
                _showError('Authentication failed. The current password you entered is incorrect. Please try again.');
              } else {
                Navigator.pop(context);
                _showSuccess('Password updated successfully. Your admin credentials are now secure.');
              }
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Icon(Icons.lock_reset_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PasswordField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    obscure: obscureCurrent,
                    error: currentError,
                    onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    hint: null,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    error: newError,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                    hint: 'Must be at least 8 characters. Tip: Use a mix of upper/lowercase letters.',
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    error: confirmError,
                    onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    hint: 'Confirm password must match the new password.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: validate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Log Out All Sessions Dialog ────────────────────────────────────────────

  void _showLogoutAllSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout, color: AppColors.statusDanger, size: 24),
          const SizedBox(width: 10),
          const Text('Log Out All Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: const Text(
          'This will immediately end all other active sessions. Your current device session will remain active.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Successfully logged out of all other devices. Your current session is now the only active access point.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Log Out Others', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecondaryGeometricBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Password & Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── 1. Account Access ──────────────────────────────────────────────
          _SectionHeader(title: '1. Account Access', colorScheme: colorScheme),
          const SizedBox(height: 12),

          _SecurityCard(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your password regularly to keep your admin account secure.',
            trailing: Text('Last Changed: —', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            onTap: _showChangePasswordDialog,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SecurityCard(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Authentication',
            subtitle: 'Enable Face ID or Fingerprint for faster, secure access to the Dashboard.',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (val) {
                setState(() => _biometricEnabled = val);
                _showSuccess(val
                    ? 'Biometric authentication enabled.'
                    : 'Biometric authentication disabled.');
              },
              activeColor: colorScheme.primary,
            ),
            onTap: null,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // ── 2. Advanced Protection ─────────────────────────────────────────
          _SectionHeader(title: '2. Advanced Protection', colorScheme: colorScheme),
          const SizedBox(height: 12),

          _SecurityCard(
            icon: Icons.verified_user_rounded,
            title: 'Two-Factor Authentication (2FA)',
            subtitle: 'Add an extra layer of security. A code will be required via email or SMS when logging into a new device.',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: _twoFactorEnabled,
                  onChanged: (val) {
                    setState(() => _twoFactorEnabled = val);
                    if (val) {
                      _showSuccess('Two-Factor Authentication enabled. An extra layer of protection has been added to the CrowdSense portal.');
                    }
                  },
                  activeColor: colorScheme.primary,
                ),
                if (!_twoFactorEnabled)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('Highly Recommended', style: TextStyle(fontSize: 10, color: AppColors.statusWarning, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            onTap: null,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          _SecurityCard(
            icon: Icons.phone_iphone_rounded,
            title: 'App Lock',
            subtitle: 'Require a PIN or Biometrics every time the app is opened.',
            trailing: DropdownButton<String>(
              value: _appLockSetting,
              underline: const SizedBox(),
              dropdownColor: colorScheme.surface,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13),
              items: _appLockOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: (val) => setState(() => _appLockSetting = val!),
            ),
            onTap: null,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // ── 3. Session Management ──────────────────────────────────────────
          _SectionHeader(title: '3. Session Management', colorScheme: colorScheme),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(colorScheme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.devices_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)),
                ]),
                const SizedBox(height: 10),
                Text('View and manage devices currently logged into your CrowdSense account.', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5)),
                const SizedBox(height: 14),
                _SessionRow(label: 'Current Device', value: 'This Device (Active)', isActive: true, colorScheme: colorScheme),
                const SizedBox(height: 6),
                _SessionRow(label: 'Other Devices', value: 'None', isActive: false, colorScheme: colorScheme),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showLogoutAllSessionsDialog,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log Out All Other Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusDanger,
                      side: const BorderSide(color: AppColors.statusDanger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _SecurityCard(
            icon: Icons.timer_off_rounded,
            title: 'Automatic Session Timeout',
            subtitle: 'Automatically log out after a period of inactivity to prevent unauthorized access at the CEA Building workstations.',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // ── 4. Security Logs ───────────────────────────────────────────────
          _SectionHeader(title: '4. Security Logs', colorScheme: colorScheme),
          const SizedBox(height: 12),

          _SecurityCard(
            icon: Icons.history_rounded,
            title: 'Login History',
            subtitle: 'Review a list of recent successful and failed login attempts.',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SecurityCard(
            icon: Icons.notifications_active_outlined,
            title: 'Security Alerts',
            subtitle: 'Get notified if there is a login from an unrecognized IP address or if a sensor threshold is changed.',
            trailing: Switch(
              value: _securityAlertsEnabled,
              onChanged: (val) => setState(() => _securityAlertsEnabled = val),
              activeColor: colorScheme.primary,
            ),
            onTap: null,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 40),
        ],
      ),
    ));
  }

  BoxDecoration _cardDecoration(ColorScheme colorScheme, bool isDark) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
          blurRadius: isDark ? 10 : 20,
          offset: Offset(0, isDark ? 4 : 8),
        ),
      ],
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  const _SecurityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: isDark ? 10 : 20,
              offset: Offset(0, isDark ? 4 : 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.5)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final ColorScheme colorScheme;

  const _SessionRow({required this.label, required this.value, required this.isActive, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF2E7D32) : colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF2E7D32) : colorScheme.onSurface)),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final String? error;
  final String? hint;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.error,
    required this.hint,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            errorText: error,
            errorMaxLines: 3,
            filled: true,
            fillColor: colorScheme.onSurface.withOpacity(0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              onPressed: onToggle,
            ),
          ),
        ),
        if (hint != null && error == null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withOpacity(0.7), height: 1.4)),
        ],
      ],
    );
  }
}
