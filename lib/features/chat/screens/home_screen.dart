import 'package:flutter/material.dart';
import '../../../services/firebase_service.dart';
import '../../../services/red_box_service.dart';
import '../../user/screens/search_user_screen.dart';
import '../../user/screens/user_profile_screen.dart';
import '../../user/screens/contacts_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'chat_list_screen.dart';
import 'red_box_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  final _redBoxService = RedBoxService();
  int _currentIndex = 0;
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const ContactsScreen(),
    const SearchUserScreen(),
    const UserProfileScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Chats',
    'Contacts',
    'Search',
    'Profile',
    'Settings',
  ];

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // Method to check for the hidden gesture to access Red Box
  Future<void> _checkForRedBoxGesture() async {
    final now = DateTime.now();
    
    // Reset counter if more than 2 seconds since last tap
    if (_lastLogoTap != null && now.difference(_lastLogoTap!).inSeconds > 2) {
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    
    _lastLogoTap = now;
    
    // If double-tapped on logo (hidden gesture)
    if (_logoTapCount == 2) {
      _logoTapCount = 0; // Reset counter
      
      try {
        // Check if Red Box is already set up
        final isSetUp = await _redBoxService.isRedBoxSetUp();
        
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _checkForRedBoxGesture,
          child: Text(_titles[_currentIndex]),
        ),
        elevation: 0,
        actions: [
          if (_currentIndex == 0) // Only show on chats tab
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh chats
              },
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            changeTab(index);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts_outlined),
              activeIcon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.saved_search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
