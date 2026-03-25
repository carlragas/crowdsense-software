import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/page_title.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailAlerts = false;
  bool maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(title: "Settings"),
        const SizedBox(height: 24),
        // Settings Content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader("Account"),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: "Profile Details",
              subtitle: "Admin",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: "Password & Security",
              onTap: () {},
            ),
            
            const SizedBox(height: 24),
            // Preferences Section
            _buildSectionHeader("Preferences"),
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: "Push Notifications",
              value: pushNotifications,
              onChanged: (val) => setState(() => pushNotifications = val),
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: "Email Alerts",
              subtitle: "Daily logs and critical alerts",
              value: emailAlerts,
              onChanged: (val) => setState(() => emailAlerts = val),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSwitchTile(
                  icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  title: "Dark Mode",
                  subtitle: themeProvider.isDarkMode ? "Enabled" : "Disabled",
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                );
              }
            ),

            const SizedBox(height: 24),
            // System & Gateway Section
            _buildSectionHeader("System Network"),
            _buildSettingsTile(
              icon: Icons.router_outlined,
              title: "Gateway Configuration",
              subtitle: "Connected to PUP-CEA-MAIN",
              onTap: () {},
            ),
            _buildSwitchTile(
              icon: Icons.build_circle_outlined,
              title: "Maintenance Mode",
              subtitle: "Suspend automated emergency protocols",
              value: maintenanceMode,
              onChanged: (val) => setState(() => maintenanceMode = val),
            ),

            const SizedBox(height: 24),
            // Support & About Section
            _buildSectionHeader("About"),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: "Help Center & Support",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: "About CrowdSense",
              subtitle: "Version 1.0.0",
              onTap: () {},
            ),

            const SizedBox(height: 32),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Log Out"),
                        content: const Text("Log out of your account?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            child: const Text(
                              "Log Out",
                              style: TextStyle(color: AppColors.statusDanger),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.statusDanger),
                label: const Text(
                  "Log Out",
                  style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.statusDanger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.secondary, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        activeColor: colorScheme.secondary,
        activeTrackColor: colorScheme.primary.withOpacity(0.5),
        inactiveThumbColor: colorScheme.onSurfaceVariant,
        inactiveTrackColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value ? colorScheme.primary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon, 
            color: value ? colorScheme.secondary : colorScheme.onSurfaceVariant, 
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              )
            : null,
      ),
    );
  }
}
