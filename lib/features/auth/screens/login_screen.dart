import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/animated_background.dart';
import '../../../core/utils/validators.dart';
import '../../../services/firebase_service.dart';
import '../../../features/user/models/app_user.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _usernameFormKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showDemoInfo = false;
  bool _showUsernameDialog = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    Future.delayed(Duration.zero, () {
      if (_firebaseService.currentUserId != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 3) {
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Login with Firebase Authentication
      await _firebaseService.loginUser(email, password);

      // Check if we have a user profile, if not, we'll prompt for username
      final user = await _firebaseService.getCurrentUserProfile();
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showUsernameDialog = true;
          });
        }
        return;
      }

      // Show success message
      Fluttertoast.showToast(
        msg: 'Login successful!',
        backgroundColor: Colors.green,
      );

      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: 'Login failed: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createUserProfile() async {
    if (!_usernameFormKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final username = _usernameController.text.trim();
      final displayName = _displayNameController.text.trim();
      
      // Check availability one more time
      final isAvailable = await _firebaseService.isUsernameAvailable(username);
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username already taken. Please choose another one.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _isUsernameAvailable = false;
        });
        return;
      }
      
      // Create user profile
      await _firebaseService.createUserProfile(
        AppUser(
          uid: _firebaseService.currentUserId!,
          email: _emailController.text.trim(),
          username: username,
          displayName: displayName,
        ),
      );
      
      // Show success message
      Fluttertoast.showToast(
        msg: 'Profile created successfully!',
        backgroundColor: Colors.green,
      );
      
      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: 'Failed to create profile: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _useDemoCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = 'password';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
              Colors.blue.shade300,
            ],
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.blue,
                              offset: Offset(0, 5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _emailController,
                        hint: 'Email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        prefixIcon: Icons.lock,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: Validators.validatePassword,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showDemoInfo = !_showDemoInfo;
                              });
                            },
                            child: Text(_showDemoInfo ? 'Hide Demo Info' : 'Demo Info'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      if (_showDemoInfo) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Demo Accounts:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDemoUser('john@example.com', 'John Doe'),
                              _buildDemoUser('jane@example.com', 'Jane Smith'),
                              _buildDemoUser('bob@example.com', 'Bob Johnson'),
                              const SizedBox(height: 8),
                              const Text(
                                'All accounts use password: "password"',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'First create these accounts using the register screen',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showUsernameDialog) _buildUsernameDialog(),
        ],
      ),
    );
  }
  
  Widget _buildUsernameDialog() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _usernameFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _displayNameController,
                    hint: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _usernameController,
                    hint: 'Username',
                    prefixIcon: Icons.person,
                    onChanged: (_) {
                      setState(() {
                        _isUsernameAvailable = true;
                      });
                    },
                    onFieldSubmitted: (_) => _checkUsernameAvailability(),
                    validator: (value) {
                      final error = Validators.validateUsername(value);
                      if (error != null) {
                        return error;
                      }
                      if (!_isUsernameAvailable) {
                        return 'Username already taken';
                      }
                      return null;
                    },
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () async {
                          await _firebaseService.signOut();
                          if (mounted) {
                            setState(() {
                              _showUsernameDialog = false;
                            });
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createUserProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDemoUser(String email, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          TextButton(
            onPressed: () => _useDemoCredentials(email),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              foregroundColor: Colors.cyan,
            ),
            child: Text(name),
          ),
          Text(' - ', style: TextStyle(color: Colors.grey[400])),
          Text(email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
} 