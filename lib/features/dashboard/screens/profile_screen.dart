import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/widgets/secondary_geometric_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _accentBlue = Color(0xFF0056D2);

  // ── editable state ─────────────────────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _designationCtrl;

  late String _adminId;
  late String _accessLevel;

  // static display data
  final List<String> _permissions = ['Read/Write – Sensor Thresholds', 'Device Decommissioning', 'Trend Reporting'];
  final List<String> _managedZones = ['Sector 7 – North CEA Wing', 'Main Access Gateway – PUP-CEA'];
  final String _lastLogin = 'Mar 26, 2026  •  17:34 PHT';
  final String _lastIp = '192.168.1.42 (PUP-CEA LAN)';
  bool _twoFactorEnabled = true;
  final List<Map<String, String>> _activeSessions = [
    {'device': 'This Device', 'status': 'Active'},
  ];
  final List<String> _recentActions = [
    'Updated smoke threshold → Sensor B12',
    'Exported Weekly Trend Report',
    'Acknowledged fire alert – Sector 7',
    'Decommissioned Sensor A04',
    'Changed password',
  ];
  final Map<String, int> _deviceHealth = {'Online': 6, 'Critical': 1, 'Offline': 0};

  String _alertChannel = 'Push Notification';
  final List<String> _alertChannels = ['Push Notification', 'SMS', 'Automated Voice Call'];

  bool _isEditing = false;
  bool _hasChanges = false;

  // originals for cancel-reset
  late String _origName, _origUsername, _origEmail, _origPhone, _origDesignation;

  @override
  void initState() {
    super.initState();
    final userProv = context.read<UserProvider>();
    
    _origName = userProv.name;
    _origUsername = userProv.username;
    _origEmail = userProv.email;
    _origPhone = userProv.phone.isEmpty ? '+63 900 000 0000' : userProv.phone;
    _origDesignation = userProv.designation;
    _adminId = userProv.id;
    _accessLevel = userProv.role.toUpperCase();

    _nameCtrl = TextEditingController(text: _origName)..addListener(_onChange);
    _usernameCtrl = TextEditingController(text: _origUsername)..addListener(_onChange);
    _emailCtrl = TextEditingController(text: _origEmail)..addListener(_onChange);
    _phoneCtrl = TextEditingController(text: _origPhone)..addListener(_onChange);
    _designationCtrl = TextEditingController(text: _origDesignation)..addListener(_onChange);
  }

  void _onChange() {
    final changed = _nameCtrl.text != _origName ||
        _usernameCtrl.text != _origUsername ||
        _emailCtrl.text != _origEmail ||
        _phoneCtrl.text != _origPhone ||
        _designationCtrl.text != _origDesignation;
    if (_hasChanges != changed) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  void _cancel() {
    setState(() {
      _nameCtrl.text = _origName;
      _emailCtrl.text = _origEmail;
      _phoneCtrl.text = _origPhone;
      _designationCtrl.text = _origDesignation;
      _isEditing = false;
      _hasChanges = false;
    });
  }

  void _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _designationCtrl.text.trim().isEmpty) {
      _showError('Update incomplete. Please provide a valid Designation to proceed.');
      return;
    }
    
    setState(() {
      _isEditing = false;
    });

    final userProv = context.read<UserProvider>();
    final uid = userProv.authUser?.uid;
    
    if (uid != null) {
      try {
        final idToken = await userProv.authUser!.getIdToken();
        final dbBaseUrl = 'https://crowdsense-db-default-rtdb.asia-southeast1.firebasedatabase.app';
        final updateUrl = Uri.parse('$dbBaseUrl/users/$uid.json?auth=$idToken');
        
        final payload = json.encode({
          'name': _nameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'designation': _designationCtrl.text.trim(),
        });

        final response = await http.patch(updateUrl, body: payload);

        if (response.statusCode != 200) {
          throw Exception('Server rejected edit: ${response.body}');
        }
        
        userProv.updateProfile({
          'name': _nameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'designation': _designationCtrl.text.trim(),
        });
        
        setState(() {
          _origName = _nameCtrl.text;
          _origUsername = _usernameCtrl.text;
          _origEmail = _emailCtrl.text;
          _origPhone = _phoneCtrl.text;
          _origDesignation = _designationCtrl.text;
          _hasChanges = false;
        });
        
        _showSuccess('Profile updated. Your changes are now synced across the CrowdSense network.');
      } catch (e) {
        setState(() => _isEditing = true);
        _showError('Failed to sync changes with server: $e');
      }
    }
  }

  void _showSuccess(String msg) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: AppColors.statusDanger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(label: 'Dismiss', textColor: Colors.white, onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          title: Text(
          _isEditing ? 'Edit Profile Details' : 'Profile Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [

          // ─── AVATAR HEADER ────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentBlue.withOpacity(0.4), width: 3),
                    boxShadow: [BoxShadow(color: _accentBlue.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: _accentBlue.withOpacity(0.15),
                    child: Icon(Icons.person, size: 52, color: _accentBlue),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      if (_isEditing) {
                        _showSuccess('Avatar updated successfully.');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isEditing ? const Color(0xFF6A1B9A) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: _isEditing ? Border.all(color: cs.surface, width: 2) : null,
                      ),
                      child: _isEditing
                          ? Icon(Icons.edit_rounded, size: 16, color: cs.onPrimary)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _nameCtrl.text.isEmpty ? _origName : _nameCtrl.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_designationCtrl.text, style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          if (!_isEditing)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue.withOpacity(0.12),
                  foregroundColor: _accentBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ─── SECTION 1: Personal Identity & Role ─────────────────────────
          _SectionLabel(label: '1. Personal Identity & Professional Role'),
          const SizedBox(height: 10),
          _ProfileCard(colorScheme: cs, isDark: isDark, children: [
            _isEditing
                ? _EditField(label: 'Full Name', controller: _nameCtrl, keyboardType: TextInputType.name, accentColor: _accentBlue)
                : _StaticRow(icon: Icons.badge_outlined, label: 'Full Name', value: _nameCtrl.text, colorScheme: cs),
            const _Divider(),
            _isEditing
                ? _EditField(label: 'Username', controller: _usernameCtrl, keyboardType: TextInputType.text, accentColor: _accentBlue)
                : _StaticRow(icon: Icons.alternate_email_rounded, label: 'Username', value: _usernameCtrl.text, colorScheme: cs),
            const _Divider(),
            _StaticRow(icon: Icons.tag_rounded, label: 'Admin ID', value: _adminId, colorScheme: cs, locked: true),
            const _Divider(),
            _isEditing
                ? _EditField(label: 'Official Designation', controller: _designationCtrl, accentColor: _accentBlue)
                : _StaticRow(icon: Icons.work_outline_rounded, label: 'Official Designation', value: _designationCtrl.text, colorScheme: cs),
            const _Divider(),
            _StaticRow(icon: Icons.corporate_fare_rounded, label: 'Department / Unit', value: 'Disaster Response Team – CEA', colorScheme: cs),
          ]),
          const SizedBox(height: 20),

          // ─── SECTION 2: Admin Credentials & Access ────────────────────────
          _SectionLabel(label: '2. Administrative Credentials & Access'),
          const SizedBox(height: 10),
          _ProfileCard(colorScheme: cs, isDark: isDark, children: [
            _StaticRow(
              icon: Icons.shield_rounded, 
              label: 'Access Level', 
              value: _accessLevel, 
              colorScheme: cs, 
              badge: _accessLevel,
              badgeColor: _accessLevel.toLowerCase() == 'admin' ? AppColors.statusDanger : AppColors.statusWarning,
            ),
            const _Divider(),
            _PermissionsRow(permissions: _permissions, colorScheme: cs),
            const _Divider(),
            _ZonesRow(zones: _managedZones, colorScheme: cs),
          ]),
          const SizedBox(height: 20),

          // ─── SECTION 3: Communication & Emergency Contact ─────────────────
          _SectionLabel(label: '3. Communication & Emergency Contact'),
          const SizedBox(height: 10),
          _ProfileCard(colorScheme: cs, isDark: isDark, children: [
            _isEditing
                ? _EditField(label: 'Secure Work Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, accentColor: _accentBlue)
                : _StaticRow(icon: Icons.email_outlined, label: 'Secure Work Email', value: _emailCtrl.text, colorScheme: cs),
            const _Divider(),
            _isEditing
                ? _EditField(
                    label: 'Emergency Contact Number',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    accentColor: _accentBlue,
                    hint: 'This number is used for critical SMS sensor alerts.',
                  )
                : _StaticRow(icon: Icons.phone_outlined, label: 'Emergency Contact Number', value: _phoneCtrl.text, colorScheme: cs),
            const _Divider(),
            _StaticRow(icon: Icons.person_pin_outlined, label: 'Emergency Escalation Path', value: 'Backup: Shift Lead B – H. Llarinas', colorScheme: cs),
            const _Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.campaign_outlined, size: 18, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Preferred Alert Channel', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
                  DropdownButton<String>(
                    value: _alertChannel,
                    underline: const SizedBox(),
                    dropdownColor: cs.surface,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 13),
                    items: _alertChannels.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _alertChannel = val!),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ─── SECTION 4: Security & Authentication ────────────────────────
          _SectionLabel(label: '4. Security & Authentication'),
          const SizedBox(height: 10),
          _ProfileCard(colorScheme: cs, isDark: isDark, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.verified_user_rounded, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                Text(_twoFactorEnabled ? 'Enabled – Account is secure' : 'Disabled – Highly Recommended',
                    style: TextStyle(fontSize: 11, color: _twoFactorEnabled ? const Color(0xFF2E7D32) : AppColors.statusWarning, fontWeight: FontWeight.w600)),
              ])),
              Switch(
                value: _twoFactorEnabled,
                onChanged: (val) => setState(() => _twoFactorEnabled = val),
                activeColor: cs.primary,
              ),
            ]),
            const _Divider(),
            _StaticRow(icon: Icons.access_time_rounded, label: 'Last Login', value: _lastLogin, colorScheme: cs),
            const _Divider(),
            _StaticRow(icon: Icons.language_rounded, label: 'Last IP Address', value: _lastIp, colorScheme: cs),
            const _Divider(),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.devices_rounded, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
              ]),
              const SizedBox(height: 10),
              ..._activeSessions.map((s) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E7D32))),
                  const SizedBox(width: 8),
                  Text('${s['device']}', style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Active', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  ),
                ]),
              )),
            ]),
          ]),
          const SizedBox(height: 20),

          // ─── SECTION 5: System Activity & Performance ────────────────────
          _SectionLabel(label: '5. System Activity & Performance'),
          const SizedBox(height: 10),

          // Device health mini-stats
          Row(children: [
            _StatChip(label: 'Online', value: _deviceHealth['Online']!, color: const Color(0xFF2E7D32), colorScheme: cs),
            const SizedBox(width: 10),
            _StatChip(label: 'Critical', value: _deviceHealth['Critical']!, color: AppColors.statusDanger, colorScheme: cs),
            const SizedBox(width: 10),
            _StatChip(label: 'Offline', value: _deviceHealth['Offline']!, color: cs.onSurfaceVariant, colorScheme: cs),
          ]),
          const SizedBox(height: 12),

          _ProfileCard(colorScheme: cs, isDark: isDark, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.history_rounded, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Text('Recent Actions Log', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
            ]),
            const SizedBox(height: 12),
            ..._recentActions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4))),
              ]),
            )),
          ]),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _isEditing
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), offset: const Offset(0, -4), blurRadius: 10)],
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accentBlue.withOpacity(0.3),
                      disabledForegroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
            )
          : null,
    ));
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;
  final List<Widget> children;
  const _ProfileCard({required this.colorScheme, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: isDark ? 10 : 20,
            offset: Offset(0, isDark ? 4 : 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 24,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool locked;
  final String? badge;
  final Color? badgeColor;

  const _StaticRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.locked = false,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(locked ? Icons.lock_outline_rounded : icon, size: 18, color: colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (badgeColor ?? colorScheme.primary).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(badge!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor ?? colorScheme.primary)),
            )
          else
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('Assigned by System Architect · cannot be changed', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
            ),
        ]),
      ),
    ]);
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Color accentColor;
  final String? hint;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    required this.accentColor,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.6)),
        ),
      ),
    ]);
  }
}

class _PermissionsRow extends StatelessWidget {
  final List<String> permissions;
  final ColorScheme colorScheme;
  const _PermissionsRow({required this.permissions, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.admin_panel_settings_outlined, size: 18, color: colorScheme.primary)),
        const SizedBox(width: 12),
        Text('Permissions Overview', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: permissions.map((p) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2))),
          child: Text(p, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
        )).toList(),
      ),
    ]);
  }
}

class _ZonesRow extends StatelessWidget {
  final List<String> zones;
  final ColorScheme colorScheme;
  const _ZonesRow({required this.zones, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.map_outlined, size: 18, color: colorScheme.primary)),
        const SizedBox(width: 12),
        Text('Managed Zones', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 8),
      ...zones.map((z) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary)),
          const SizedBox(width: 8),
          Text(z, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        ]),
      )),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ColorScheme colorScheme;
  const _StatChip({required this.label, required this.value, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
        ]),
      ),
    );
  }
}
