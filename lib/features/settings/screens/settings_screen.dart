import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/firebase_service.dart';
import '../../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  final _notificationService = NotificationService();
  bool _isDarkMode = true;
  bool _areNotificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? true;
        _areNotificationsEnabled = prefs.getBool('areNotificationsEnabled') ?? true;
      });
      
      // Apply notification settings
      _notificationService.toggleSound(_areNotificationsEnabled);
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setBool('areNotificationsEnabled', _areNotificationsEnabled);
      
      // Apply notification settings
      _notificationService.toggleSound(_areNotificationsEnabled);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Settings sections
        _buildSectionTitle('Appearance'),
        _buildSettingCard(
          title: 'Dark Mode',
          subtitle: 'Switch between light and dark theme',
          icon: Icons.dark_mode,
          trailing: Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveSettings();
              // In a real app, you'd also apply the theme change here
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Notifications'),
        _buildSettingCard(
          title: 'Push Notifications',
          subtitle: 'Get notified about new messages',
          icon: Icons.notifications,
          trailing: Switch(
            value: _areNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _areNotificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Account'),
        _buildSettingCard(
          title: 'Change Password',
          subtitle: 'Update your login credentials',
          icon: Icons.lock,
          onTap: () {
            // Navigate to change password screen
          },
        ),
        _buildSettingCard(
          title: 'Block List',
          subtitle: 'Manage blocked contacts',
          icon: Icons.block,
          onTap: () {
            // Navigate to block list screen
          },
        ),
        _buildSettingCard(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: () {
            _showDeleteAccountConfirmation();
          },
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('About'),
        _buildSettingCard(
          title: 'App Version',
          subtitle: '1.0.0',
          icon: Icons.info_outline,
        ),
        _buildSettingCard(
          title: 'Privacy Policy',
          icon: Icons.policy,
          onTap: () {
            // Show privacy policy
          },
        ),
        _buildSettingCard(
          title: 'Terms of Service',
          icon: Icons.description,
          onTap: () {
            // Show terms of service
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement account deletion
              Navigator.of(context).pop();
              // In a real app, you'd delete the account and navigate to login
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 