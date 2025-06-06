import 'package:flutter/material.dart';
import '../../../services/red_box_service.dart';
import 'red_box_chat_list_screen.dart';

class RedBoxPinScreen extends StatefulWidget {
  final bool isSetup;

  const RedBoxPinScreen({
    Key? key,
    this.isSetup = false,
  }) : super(key: key);

  @override
  _RedBoxPinScreenState createState() => _RedBoxPinScreenState();
}

class _RedBoxPinScreenState extends State<RedBoxPinScreen> {
  final _redBoxService = RedBoxService();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _pin = '';
  bool _isPinMasked = true;
  String? _errorMessage;
  bool _isLoading = false;
  int _pinAttempts = 0;
  bool _isLocked = false;
  DateTime? _lockUntil;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _onPinSubmitted() async {
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
      if (widget.isSetup) {
        if (_confirmPinController.text.trim() != pin) {
          setState(() {
            _errorMessage = 'PINs do not match';
            _isLoading = false;
          });
          return;
        }
        
        final success = await _redBoxService.setupRedBox(pin);
        
        if (success) {
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
          setState(() {
            _errorMessage = 'Failed to set up Red Box';
          });
        }
      } else {
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
          });
          
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Set Up Red Box' : 'Enter Red Box PIN'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              widget.isSetup
                  ? 'Create a PIN to secure your Red Box'
                  : 'Enter your Red Box PIN',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isSetup
                  ? 'Your PIN must be at least 4 digits long'
                  : 'Enter your PIN to access your secure chats',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
              onSubmitted: (_) {
                if (widget.isSetup && _confirmPinController.text.isEmpty) {
                  FocusScope.of(context).nextFocus();
                } else {
                  _onPinSubmitted();
                }
              },
            ),
            if (widget.isSetup) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
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
                onSubmitted: (_) => _onPinSubmitted(),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading || _isLocked ? null : _onPinSubmitted,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isSetup ? 'CREATE PIN' : 'UNLOCK',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 