import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/firebase_service.dart';
import '../models/app_user.dart';
import '../../../core/utils/validators.dart';
import 'avatar_selection_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _firebaseService = FirebaseService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isUpdatingUsername = false;
  bool _isUpdatingDisplayName = false;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  AppUser? _currentUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _firebaseService.currentUserId;
      
      if (userId == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final user = await _firebaseService.getUserProfile(userId);
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Show options for profile picture
  Future<void> _showProfilePictureOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _uploadProfilePicture();
            },
          ),
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Select Avatar'),
            onTap: () {
              Navigator.pop(context);
              _selectAvatar();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectAvatar() async {
    final avatarPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const AvatarSelectionScreen(),
      ),
    );

    if (avatarPath != null && _currentUser != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        await _firebaseService.updateUserWithAvatar(_currentUser!, avatarPath);
        
        // Reload user data to get updated profile
        await _loadCurrentUser();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _isUploadingImage = true;
      });
      
      final userId = _firebaseService.currentUserId;
      if (userId == null) return;
      
      final imageFile = File(image.path);
      final downloadUrl = await _firebaseService.uploadProfilePicture(userId, imageFile);
      
      // Update the user profile
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(profilePicUrl: downloadUrl);
        await _firebaseService.createUserProfile(updatedUser);
        
        setState(() {
          _currentUser = updatedUser;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }
  
  Future<void> _showEditUsernameDialog() async {
    if (_currentUser == null) return;
    
    _usernameController.text = _currentUser!.username;
    _isUsernameAvailable = true;
    _isCheckingUsername = false;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Enter your new username',
            errorText: !_isUsernameAvailable ? 'Username already taken' : null,
            suffixIcon: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : (_usernameController.text.isNotEmpty && _isUsernameAvailable
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null),
          ),
          onChanged: (_) {
            setState(() {
              _isUsernameAvailable = true;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isUpdatingUsername ? null : () => _updateUsername(context),
            child: _isUpdatingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDisplayNameDialog() async {
    if (_currentUser == null) return;
    
    _displayNameController.text = _currentUser!.displayName;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isUpdatingDisplayName ? null : () => _updateDisplayName(context),
            child: _isUpdatingDisplayName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 3) {
      return;
    }
    
    // Skip check if username hasn't changed
    if (_currentUser != null && username == _currentUser!.username) {
      setState(() {
        _isUsernameAvailable = true;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    try {
      final isAvailable = await _firebaseService.isUsernameAvailable(username);
      
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking username: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _updateUsername(BuildContext dialogContext) async {
    final username = _usernameController.text.trim();
    
    // Validate username
    final error = Validators.validateUsername(username);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    
    // Skip update if username hasn't changed
    if (_currentUser != null && username == _currentUser!.username) {
      Navigator.pop(dialogContext);
      return;
    }
    
    setState(() {
      _isUpdatingUsername = true;
    });
    
    try {
      // Check availability one more time
      final isAvailable = await _firebaseService.isUsernameAvailable(username);
      if (!isAvailable) {
        setState(() {
          _isUsernameAvailable = false;
          _isUpdatingUsername = false;
        });
        return;
      }
      
      // Update username
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(username: username);
        await _firebaseService.createUserProfile(updatedUser);
        
        // Close dialog and reload profile
        if (mounted) {
          Navigator.pop(dialogContext);
          await _loadCurrentUser();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update username: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingUsername = false;
        });
      }
    }
  }

  Future<void> _updateDisplayName(BuildContext dialogContext) async {
    final displayName = _displayNameController.text.trim();
    
    // Validate display name
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    // Skip update if display name hasn't changed
    if (_currentUser != null && displayName == _currentUser!.displayName) {
      Navigator.pop(dialogContext);
      return;
    }
    
    setState(() {
      _isUpdatingDisplayName = true;
    });
    
    try {
      // Update display name
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(displayName: displayName);
        await _firebaseService.createUserProfile(updatedUser);
        
        // Close dialog and reload profile
        if (mounted) {
          Navigator.pop(dialogContext);
          await _loadCurrentUser();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Display name updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update display name: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingDisplayName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentUser,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'User profile not found',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile picture
            Stack(
              children: [
                GestureDetector(
                  onTap: _showProfilePictureOptions,
                  child: _isUploadingImage
                      ? Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 70,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: _currentUser!.profilePicUrl.isNotEmpty
                              ? _currentUser!.profilePicUrl.startsWith('assets/')
                                  ? AssetImage(_currentUser!.profilePicUrl) as ImageProvider
                                  : NetworkImage(_currentUser!.profilePicUrl)
                              : null,
                          child: _currentUser!.profilePicUrl.isEmpty
                              ? Text(
                                  _currentUser!.username.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      onPressed: _showProfilePictureOptions,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Display name with edit option
            if (_currentUser!.displayName.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _currentUser!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditDisplayNameDialog,
                    tooltip: 'Edit Display Name',
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Username with edit option
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '@${_currentUser!.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _showEditUsernameDialog,
                  tooltip: 'Edit Username',
                  iconSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Email
            Text(
              _currentUser!.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Profile actions
            _buildActionCard(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                // Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile feature coming soon')),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                try {
                  await _firebaseService.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to log out: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
} 