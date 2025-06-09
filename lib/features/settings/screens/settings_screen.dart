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

  void _showRedBoxPINOptions() async {
    // Check if Red Box is set up first
    final isRedBoxSetUp = await _redBoxService.isRedBoxSetUp();
    if (!isRedBoxSetUp) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set up Red Box first'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if decoy PIN is already set up
    final isDecoyPinSetUp = await _redBoxService.isDecoyPinSetUp();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.security, color: Colors.red[800], size: 24),
                const SizedBox(width: 8),
                const Text('Manage Red Box PINs'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Change Main PIN'),
                  subtitle: const Text('Update your primary Red Box PIN'),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangePINDialog(isPrimaryPin: true);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(isDecoyPinSetUp ? 'Change Decoy PIN' : 'Set Up Decoy PIN'),
                  subtitle: Text(isDecoyPinSetUp 
                    ? 'Update your decoy PIN for emergency situations' 
                    : 'Create a decoy PIN to show fake chats when needed'
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDecoyPINSetupDialog();
                  },
                ),
                if (isDecoyPinSetUp) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Remove Decoy PIN', 
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Disable the decoy PIN feature'),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemoveDecoyPINConfirmation();
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showChangePINDialog({required bool isPrimaryPin}) {
    // Create temporary controllers for the PIN inputs
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    
    String? errorMessage;
    bool isPinMasked = true;
    
    // Create a stateful builder for the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isPrimaryPin ? 'Change Primary PIN' : 'Change Decoy PIN',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: currentPinController,
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPinMasked ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isPinMasked = !isPinMasked;
                          });
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: isPinMasked,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPinController,
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: isPinMasked,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPinController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New PIN',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: isPinMasked,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    final currentPin = currentPinController.text.trim();
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();
                    
                    // Basic validation
                    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                      setState(() {
                        errorMessage = 'All fields are required';
                      });
                      return;
                    }
                    
                    if (newPin.length < 4) {
                      setState(() {
                        errorMessage = 'PIN must be at least 4 digits';
                      });
                      return;
                    }
                    
                    if (newPin != confirmPin) {
                      setState(() {
                        errorMessage = 'New PINs do not match';
                      });
                      return;
                    }
                    
                    // Verify current PIN
                    bool isValid = false;
                    if (isPrimaryPin) {
                      isValid = await _redBoxService.verifyPin(currentPin);
                    } else {
                      isValid = await _redBoxService.isDecoyPin(currentPin);
                    }
                    
                    if (!isValid) {
                      setState(() {
                        errorMessage = 'Current PIN is incorrect';
                      });
                      return;
                    }
                    
                    // If this is a decoy PIN, make sure it's different from primary
                    if (!isPrimaryPin) {
                      final primaryPin = await _redBoxService.getPrimaryPin();
                      if (newPin == primaryPin) {
                        setState(() {
                          errorMessage = 'Decoy PIN must be different from primary PIN';
                        });
                        return;
                      }
                    }
                    
                    // Change the PIN
                    bool success = false;
                    if (isPrimaryPin) {
                      success = await _redBoxService.setupRedBox(newPin);
                    } else {
                      success = await _redBoxService.setupDecoyPin(newPin);
                    }
                    
                    // Close dialog
                    Navigator.of(context).pop();
                    
                    // Show result
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                          ? '${isPrimaryPin ? 'Primary' : 'Decoy'} PIN changed successfully' 
                          : 'Failed to change PIN'
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: Text(
                    'CHANGE PIN',
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ],
            );
          }
        );
      },
    ).then((_) {
      // Clean up controllers when dialog is dismissed
      currentPinController.dispose();
      newPinController.dispose();
      confirmPinController.dispose();
    });
  }

  void _showDecoyPINSetupDialog() {
    // Check if decoy PIN is already set up
    _redBoxService.isDecoyPinSetUp().then((isDecoyPinSetUp) {
      // Create custom PIN setup screen for decoy PIN only
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RedBoxPinScreen(
            isSetup: false,
            isDecoyPinSetup: true,
          ),
        ),
      ).then((value) {
        // Refresh the UI after returning from PIN setup
        setState(() {});
        
        // Show confirmation if user navigated back without SnackBar
        if (isDecoyPinSetUp) {
          // If the PIN was already set up, assume it was changed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Decoy PIN updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    });
  }

  void _showRemoveDecoyPINConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade800),
                  const SizedBox(width: 8),
                  const Text('Remove Decoy PIN?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will remove your decoy PIN and disable the plausible deniability feature. '
                    'Are you sure you want to continue?'
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async {
                    // Set loading state
                    setState(() {
                      isLoading = true;
                    });
                    
                    try {
                      await _redBoxService.removeDecoyPin();
                      
                      // Close dialog
                      if (mounted) {
                        Navigator.pop(context);
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Decoy PIN removed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Refresh the UI
                        this.setState(() {});
                      }
                    } catch (e) {
                      // Show error
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error removing decoy PIN: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      
                      // Reset loading state
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  child: Text(
                    'REMOVE',
                    style: TextStyle(
                      color: isLoading ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
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
          title: 'Manage Red Box PINs',
          subtitle: 'Set up or change your decoy PIN',
          icon: Icons.pin,
          iconColor: Colors.red[600],
          onTap: () {
            _showRedBoxPINOptions();
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