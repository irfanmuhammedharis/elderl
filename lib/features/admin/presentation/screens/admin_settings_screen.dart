import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Settings state model
class AppSettings {
  final bool notificationsEnabled;
  final bool emergencyAlertsEnabled;
  final bool dailyDigestEnabled;
  final int checkInReminderHour;
  final int checkInReminderMinute;
  final bool darkModeEnabled;
  final bool highContrastEnabled;
  final double fontScale;
  final bool autoApproveFamily;
  final int sessionTimeoutMinutes;
  final bool maintenanceMode;

  AppSettings({
    this.notificationsEnabled = true,
    this.emergencyAlertsEnabled = true,
    this.dailyDigestEnabled = true,
    this.checkInReminderHour = 9,
    this.checkInReminderMinute = 0,
    this.darkModeEnabled = false,
    this.highContrastEnabled = false,
    this.fontScale = 1.0,
    this.autoApproveFamily = false,
    this.sessionTimeoutMinutes = 30,
    this.maintenanceMode = false,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? emergencyAlertsEnabled,
    bool? dailyDigestEnabled,
    int? checkInReminderHour,
    int? checkInReminderMinute,
    bool? darkModeEnabled,
    bool? highContrastEnabled,
    double? fontScale,
    bool? autoApproveFamily,
    int? sessionTimeoutMinutes,
    bool? maintenanceMode,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emergencyAlertsEnabled: emergencyAlertsEnabled ?? this.emergencyAlertsEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      checkInReminderHour: checkInReminderHour ?? this.checkInReminderHour,
      checkInReminderMinute: checkInReminderMinute ?? this.checkInReminderMinute,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      fontScale: fontScale ?? this.fontScale,
      autoApproveFamily: autoApproveFamily ?? this.autoApproveFamily,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    );
  }
}

/// Settings state notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setEmergencyAlertsEnabled(bool value) {
    state = state.copyWith(emergencyAlertsEnabled: value);
  }

  void setDailyDigestEnabled(bool value) {
    state = state.copyWith(dailyDigestEnabled: value);
  }

  void setCheckInReminderTime(int hour, int minute) {
    state = state.copyWith(checkInReminderHour: hour, checkInReminderMinute: minute);
  }

  void setDarkModeEnabled(bool value) {
    state = state.copyWith(darkModeEnabled: value);
  }

  void setHighContrastEnabled(bool value) {
    state = state.copyWith(highContrastEnabled: value);
  }

  void setFontScale(double value) {
    state = state.copyWith(fontScale: value);
  }

  void setAutoApproveFamily(bool value) {
    state = state.copyWith(autoApproveFamily: value);
  }

  void setSessionTimeout(int minutes) {
    state = state.copyWith(sessionTimeoutMinutes: minutes);
  }

  void setMaintenanceMode(bool value) {
    state = state.copyWith(maintenanceMode: value);
  }

  void resetToDefaults() {
    state = AppSettings();
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Admin Settings Screen - App configuration and system settings
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore, color: Colors.white),
            label: const Text('Reset', style: TextStyle(color: Colors.white)),
            onPressed: () => _showResetConfirmation(context, settingsNotifier),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notification Settings
                _buildSettingsSection(
                  context,
                  title: 'Notifications',
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      'Push Notifications',
                      'Enable push notifications for important updates',
                      settings.notificationsEnabled,
                      (value) => settingsNotifier.setNotificationsEnabled(value),
                      Icons.notifications_active,
                    ),
                    _buildSwitchTile(
                      'Emergency Alerts',
                      'Receive immediate alerts for emergencies',
                      settings.emergencyAlertsEnabled,
                      (value) => settingsNotifier.setEmergencyAlertsEnabled(value),
                      Icons.emergency,
                    ),
                    _buildSwitchTile(
                      'Daily Digest',
                      'Receive daily summary of activities',
                      settings.dailyDigestEnabled,
                      (value) => settingsNotifier.setDailyDigestEnabled(value),
                      Icons.summarize,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Check-in Settings
                _buildSettingsSection(
                  context,
                  title: 'Check-in Settings',
                  icon: Icons.fact_check,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Daily Reminder Time'),
                      subtitle: Text(
                        _formatTime(settings.checkInReminderHour, settings.checkInReminderMinute),
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTimePicker(context, settings, settingsNotifier),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Appearance Settings
                _buildSettingsSection(
                  context,
                  title: 'Appearance',
                  icon: Icons.palette,
                  children: [
                    _buildSwitchTile(
                      'Dark Mode',
                      'Use dark color scheme',
                      settings.darkModeEnabled,
                      (value) => settingsNotifier.setDarkModeEnabled(value),
                      Icons.dark_mode,
                    ),
                    _buildSwitchTile(
                      'High Contrast',
                      'Increase contrast for better visibility',
                      settings.highContrastEnabled,
                      (value) => settingsNotifier.setHighContrastEnabled(value),
                      Icons.contrast,
                    ),
                    ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text('Font Size'),
                      subtitle: Slider(
                        value: settings.fontScale,
                        min: 0.8,
                        max: 1.5,
                        divisions: 7,
                        label: '${(settings.fontScale * 100).round()}%',
                        onChanged: (value) => settingsNotifier.setFontScale(value),
                      ),
                      trailing: Text(
                        '${(settings.fontScale * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Admin Settings
                _buildSettingsSection(
                  context,
                  title: 'Administration',
                  icon: Icons.admin_panel_settings,
                  children: [
                    _buildSwitchTile(
                      'Auto-Approve Family Requests',
                      'Automatically approve family member link requests',
                      settings.autoApproveFamily,
                      (value) => settingsNotifier.setAutoApproveFamily(value),
                      Icons.family_restroom,
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Session Timeout'),
                      subtitle: Text(
                        '${settings.sessionTimeoutMinutes} minutes',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSessionTimeoutDialog(context, settings, settingsNotifier),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // System Settings
                _buildSettingsSection(
                  context,
                  title: 'System',
                  icon: Icons.settings_applications,
                  children: [
                    _buildSwitchTile(
                      'Maintenance Mode',
                      'Temporarily disable app access for non-admins',
                      settings.maintenanceMode,
                      (value) => _showMaintenanceModeConfirmation(context, value, settingsNotifier),
                      Icons.engineering,
                      isDanger: true,
                    ),
                    ListTile(
                      leading: Icon(Icons.cloud_sync, color: Colors.grey[600]),
                      title: const Text('Sync Data'),
                      subtitle: const Text('Force sync all data with server'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSyncConfirmation(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_sweep, color: Colors.red[400]),
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Clear local cached data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showClearCacheConfirmation(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // About Section
                _buildSettingsSection(
                  context,
                  title: 'About',
                  icon: Icons.info,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('App Version'),
                      subtitle: Text('1.0.0 (Build 1)'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.policy),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening privacy policy...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening terms of service...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('Report a Bug'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening bug report form...')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings', style: TextStyle(fontSize: 16)),
                    onPressed: () => _saveSettings(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon, {
    bool isDanger = false,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.red : null)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: isDanger ? Colors.red : AppTheme.primaryColor,
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  void _showTimePicker(BuildContext context, AppSettings settings, SettingsNotifier notifier) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.checkInReminderHour, minute: settings.checkInReminderMinute),
      helpText: 'Select Check-in Reminder Time',
    );
    if (picked != null) {
      notifier.setCheckInReminderTime(picked.hour, picked.minute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder time set to ${_formatTime(picked.hour, picked.minute)}')),
        );
      }
    }
  }

  void _showSessionTimeoutDialog(BuildContext context, AppSettings settings, SettingsNotifier notifier) {
    final options = [15, 30, 60, 120];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) => RadioListTile<int>(
            title: Text('$minutes minutes'),
            value: minutes,
            groupValue: settings.sessionTimeoutMinutes,
            onChanged: (value) {
              if (value != null) {
                notifier.setSessionTimeout(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceModeConfirmation(BuildContext context, bool newValue, SettingsNotifier notifier) {
    if (newValue) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Enable Maintenance Mode?'),
            ],
          ),
          content: const Text(
            'This will prevent non-admin users from accessing the app. '
            'Only use this during scheduled maintenance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                notifier.setMaintenanceMode(true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maintenance mode enabled'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      notifier.setMaintenanceMode(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance mode disabled')),
      );
    }
  }

  void _showResetConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text('This will reset all settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSyncConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Data?'),
        content: const Text('This will synchronize all local data with the server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
            },
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear all locally cached data. You may need to re-download some content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: Colors.green[600],
      ),
    );
  }
}
