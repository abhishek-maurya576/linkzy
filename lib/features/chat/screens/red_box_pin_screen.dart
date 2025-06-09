import 'package:flutter/material.dart';
import '../../../services/red_box_service.dart';
import 'red_box_chat_list_screen.dart';

class RedBoxPinScreen extends StatefulWidget {
  final bool isSetup;
  final bool isDecoyPinSetup;

  const RedBoxPinScreen({
    Key? key,
    this.isSetup = false,
    this.isDecoyPinSetup = false,
  }) : super(key: key);

  @override
  _RedBoxPinScreenState createState() => _RedBoxPinScreenState();
}

class _RedBoxPinScreenState extends State<RedBoxPinScreen> {
  final _redBoxService = RedBoxService();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _decoyPinController = TextEditingController();
  final _confirmDecoyPinController = TextEditingController();
  String _pin = '';
  bool _isPinMasked = true;
  String? _errorMessage;
  bool _isLoading = false;
  int _pinAttempts = 0;
  bool _isLocked = false;
  DateTime? _lockUntil;
  
  // Setup process tracking
  bool _isMainPinSetup = true;
  bool _showDecoyPinSetup = false;
  bool _skipDecoyPin = false;

  @override
  void initState() {
    super.initState();
    // If we're only setting up the decoy PIN, skip to that step
    if (widget.isDecoyPinSetup) {
      _isMainPinSetup = false;
      _showDecoyPinSetup = true;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _decoyPinController.dispose();
    _confirmDecoyPinController.dispose();
    super.dispose();
  }

  Future<void> _onPinSubmitted() async {
    // If we're setting up, handle the multi-step process
    if (widget.isSetup) {
      await _handleSetupProcess();
      return;
    }
    
    // If we're specifically setting up a decoy PIN only
    if (widget.isDecoyPinSetup) {
      await _setupDecoyPin();
      return;
    }
    
    // Otherwise handle login with existing PIN
    await _handlePinLogin();
  }
  
  Future<void> _handleSetupProcess() async {
    if (_isMainPinSetup) {
      // Step 1: Setup the main PIN
      final success = await _setupMainPin();
      
      if (success) {
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary PIN set up successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        setState(() {
          _isMainPinSetup = false;
          _showDecoyPinSetup = true;
          _errorMessage = null;
          _pinController.clear();
          _confirmPinController.clear();
        });
      }
    } else if (_showDecoyPinSetup && !_skipDecoyPin) {
      // Step 2: Setup the decoy PIN (optional)
      final success = await _setupDecoyPin();
      
      if (success) {
        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decoy PIN set up successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to Red Box chat list screen
        if (mounted) {
          // If we only set up the decoy PIN, go back to settings
          if (widget.isDecoyPinSetup) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Decoy PIN set up successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Otherwise proceed to chat screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RedBoxChatListScreen(),
              ),
            );
          }
        }
      }
    }
  }
  
  Future<bool> _setupMainPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    
    if (pin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a PIN';
      });
      return false;
    }
    
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return false;
    }
    
    if (confirmPin != pin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return false;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final success = await _redBoxService.setupRedBox(pin);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to set up Red Box';
        });
      }
      
      return success;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred';
      });
      return false;
    }
  }
  
  Future<bool> _setupDecoyPin() async {
    final decoyPin = _decoyPinController.text.trim();
    final confirmDecoyPin = _confirmDecoyPinController.text.trim();
    final mainPin = await _redBoxService.getPrimaryPin();
    
    if (decoyPin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a decoy PIN';
      });
      return false;
    }
    
    if (decoyPin.length < 4) {
      setState(() {
        _errorMessage = 'Decoy PIN must be at least 4 digits';
      });
      return false;
    }
    
    if (confirmDecoyPin != decoyPin) {
      setState(() {
        _errorMessage = 'Decoy PINs do not match';
      });
      return false;
    }
    
    if (decoyPin == mainPin) {
      setState(() {
        _errorMessage = 'Decoy PIN must be different from your main PIN';
      });
      return false;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final success = await _redBoxService.setupDecoyPin(decoyPin);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to set up decoy PIN';
        });
      }
      
      return success;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred';
      });
      return false;
    }
  }
  
  Future<void> _handlePinLogin() async {
    final pin = _pinController.text.trim();
    
    if (pin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a PIN';
      });
      return;
    }
    
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Check if we're locked out
      if (_isLocked && _lockUntil != null && _lockUntil!.isAfter(DateTime.now())) {
        final remaining = _lockUntil!.difference(DateTime.now());
        setState(() {
          _errorMessage = 'Too many attempts. Try again in ${remaining.inSeconds} seconds';
          _isLoading = false;
        });
        return;
      }
      
      // Reset lock if expired
      if (_isLocked && _lockUntil != null && _lockUntil!.isBefore(DateTime.now())) {
        setState(() {
          _isLocked = false;
          _pinAttempts = 0;
        });
      }
      
      // Check if PIN is a decoy
      final isDecoy = await _redBoxService.isDecoyPin(pin);
      if (isDecoy) {
        // Show login success feedback
        setState(() {
          _isLoading = false;
        });
        
        // Visual confirmation of successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accessing decoy mode...'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1000),
          ),
        );
        
        // Slight delay to show the confirmation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Show empty chat list for decoy mode
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RedBoxChatListScreen(isDecoyMode: true),
            ),
          );
        }
        return;
      }
      
      // Verify PIN
      final isValid = await _redBoxService.verifyPin(pin);
      
      if (isValid) {
        // Reset attempts
        setState(() {
          _pinAttempts = 0;
          _isLocked = false;
          _isLoading = false;
        });
        
        // Visual confirmation of successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access granted'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1000),
          ),
        );
        
        // Slight delay to show the confirmation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to Red Box chat list screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RedBoxChatListScreen(),
            ),
          );
        }
      } else {
        // Increment attempt counter
        setState(() {
          _pinAttempts++;
          _errorMessage = 'Invalid PIN';
          
          // Lock after 5 attempts
          if (_pinAttempts >= 5) {
            _isLocked = true;
            // Lock for 30 seconds
            _lockUntil = DateTime.now().add(const Duration(seconds: 30));
            _errorMessage = 'Too many attempts. Try again in 30 seconds';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _skipDecoyPinSetup() {
    setState(() {
      _skipDecoyPin = true;
    });
    
    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Decoy PIN setup skipped'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    // If we're in standalone decoy PIN setup mode, just go back
    if (widget.isDecoyPinSetup) {
      Navigator.pop(context);
      return;
    }
    
    // Otherwise, this is the initial setup, so navigate to Red Box chat list
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RedBoxChatListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Colors.red.shade800,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getHeaderText(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubheaderText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.isSetup && _isMainPinSetup) ...[
                      _buildMainPinSetupFields(),
                    ] else if ((widget.isSetup && _showDecoyPinSetup) || widget.isDecoyPinSetup) ...[
                      _buildDecoyPinSetupFields(),
                    ] else ...[
                      _buildPinLoginField(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
  
  String _getScreenTitle() {
    if (!widget.isSetup && !widget.isDecoyPinSetup) {
      return 'Enter Red Box PIN';
    } else if (widget.isDecoyPinSetup) {
      return 'Set Up Decoy PIN';
    } else if (_isMainPinSetup) {
      return 'Set Up Red Box';
    } else {
      return 'Set Up Decoy PIN (Optional)';
    }
  }
  
  String _getHeaderText() {
    if (!widget.isSetup && !widget.isDecoyPinSetup) {
      return 'Enter your Red Box PIN';
    } else if (widget.isDecoyPinSetup) {
      return 'Create a decoy PIN for emergency exit';
    } else if (_isMainPinSetup) {
      return 'Create a PIN to secure your Red Box';
    } else {
      return 'Create a decoy PIN (optional)';
    }
  }
  
  String _getSubheaderText() {
    if (!widget.isSetup && !widget.isDecoyPinSetup) {
      return 'Enter your PIN to access the Red Box';
    } else if (widget.isDecoyPinSetup) {
      return 'A decoy PIN shows fake chats when under duress';
    } else if (_isMainPinSetup) {
      return 'This PIN will protect all your Red Box messages';
    } else {
      return 'A decoy PIN will show empty chats if someone forces you to unlock';
    }
  }
  
  Widget _buildMainPinSetupFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pinController,
          decoration: InputDecoration(
            labelText: 'PIN',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPinMasked ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPinMasked = !_isPinMasked;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          obscureText: _isPinMasked,
          onChanged: (value) {
            setState(() {
              _pin = value;
              _errorMessage = null;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPinController,
          decoration: InputDecoration(
            labelText: 'Confirm PIN',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          obscureText: _isPinMasked,
          onChanged: (_) => setState(() => _errorMessage = null),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _onPinSubmitted(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDecoyPinSetupFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _decoyPinController,
          decoration: InputDecoration(
            labelText: 'Decoy PIN',
            helperText: 'Different from your main PIN',
            prefixIcon: const Icon(Icons.security),
            suffixIcon: IconButton(
              icon: Icon(
                _isPinMasked ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPinMasked = !_isPinMasked;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          obscureText: _isPinMasked,
          onChanged: (_) => setState(() => _errorMessage = null),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmDecoyPinController,
          decoration: InputDecoration(
            labelText: 'Confirm Decoy PIN',
            prefixIcon: const Icon(Icons.security),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          obscureText: _isPinMasked,
          onChanged: (_) => setState(() => _errorMessage = null),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _onPinSubmitted(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Set Up Decoy PIN',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _skipDecoyPinSetup,
          child: const Text('Skip for now'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: const [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(height: 8),
              Text(
                'A decoy PIN shows empty chats if someone forces you to unlock your Red Box.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPinLoginField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pinController,
          decoration: InputDecoration(
            labelText: 'PIN',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPinMasked ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPinMasked = !_isPinMasked;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          obscureText: _isPinMasked,
          onChanged: (value) {
            setState(() {
              _pin = value;
              _errorMessage = null;
            });
          },
          onSubmitted: (_) => _onPinSubmitted(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _onPinSubmitted,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Access Red Box',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 