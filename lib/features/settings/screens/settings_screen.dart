import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../services/firebase_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/red_box_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/user/screens/user_profile_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/chat/screens/red_box_pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  final _notificationService = NotificationService();
  final _redBoxService = RedBoxService();
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

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('areNotificationsEnabled', _areNotificationsEnabled);
      
      // Apply notification settings
      _notificationService.toggleSound(_areNotificationsEnabled);
    } catch (e) {
      debugPrint('Failed to save notification settings: $e');
    }
  }

  Future<void> _accessRedBox() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if Red Box is already set up
      final isSetUp = await _redBoxService.isRedBoxSetUp();
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RedBoxPinScreen(
              isSetup: !isSetUp,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing Red Box: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
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
              _saveNotificationSettings();
            },
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Privacy & Security'),
        _buildSettingCardWithAction(
          title: 'Red Box',
          subtitle: 'Access secure chat mode',
          icon: Icons.security,
          iconColor: Colors.red[800],
          onTap: () {
            _accessRedBox();
          },
        ),
        _buildSettingCardWithAction(
          title: 'Change Password',
          subtitle: 'Update your login credentials',
          icon: Icons.lock,
          onTap: () {
            // Navigate to change password screen
          },
        ),
        _buildSettingCardWithAction(
          title: 'Block List',
          subtitle: 'Manage blocked contacts',
          icon: Icons.block,
          onTap: () {
            // Navigate to block list screen
          },
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Account'),
        _buildSettingCardWithAction(
          title: 'Edit Profile',
          subtitle: 'Update your name, username and photo',
          icon: Icons.person,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfileScreen()),
            );
          },
        ),
        _buildSettingCardWithAction(
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
          subtitle: AppConstants.appVersion,
          icon: Icons.info_outline,
          trailing: const SizedBox(), // Empty widget as trailing
        ),
        _buildSettingCardWithAction(
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          icon: Icons.policy,
          onTap: () {
            // Show privacy policy
          },
        ),
        _buildSettingCardWithAction(
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        trailing: trailing,
      ),
    );
  }
  
  Widget _buildSettingCardWithAction({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon, 
          size: 28,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: textColor != null ? textColor.withOpacity(0.7) : Colors.grey[500],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
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