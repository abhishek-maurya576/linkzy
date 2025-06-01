import 'package:flutter/material.dart';
import '../../../services/firebase_service.dart';
import '../models/app_user.dart';
import '../../chat/screens/chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchController = TextEditingController();
  final _firebaseService = FirebaseService();
  List<AppUser> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  Map<String, bool> _savedContactsStatus = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseService.currentUserId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _firebaseService.searchUsersByUsername(query);
      
      // Filter out the current user from search results
      final filteredResults = results.where((user) => user.uid != _currentUserId).toList();
      
      // Check if users are already in contacts
      for (var user in filteredResults) {
        _savedContactsStatus[user.uid] = await _firebaseService.isUserInContacts(user.uid);
      }
      
      setState(() {
        _searchResults = filteredResults;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search users: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToContacts(AppUser user) async {
    if (_currentUserId == null) return;
    
    try {
      setState(() {
        // Show optimistic UI update
        _savedContactsStatus[user.uid] = true;
      });
      
      await _firebaseService.addContact(user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${user.username} to contacts'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _savedContactsStatus[user.uid] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by username',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (_) => _searchUsers(),
          ),
          const SizedBox(height: 16),
          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _searchController.text.isEmpty
                  ? null
                  : _searchUsers,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Search'),
            ),
          ),
          const SizedBox(height: 16),
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          // Results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Search for users by username'
                          : 'No users found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _buildUserItem(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(AppUser user) {
    final bool isInContacts = _savedContactsStatus[user.uid] ?? false;
    final bool hasDisplayName = user.displayName.isNotEmpty;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          backgroundImage: user.profilePicUrl.isNotEmpty 
              ? user.profilePicUrl.startsWith('assets/')
                  ? AssetImage(user.profilePicUrl) as ImageProvider
                  : NetworkImage(user.profilePicUrl) 
              : null,
          child: user.profilePicUrl.isEmpty
              ? Text(
                  user.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: hasDisplayName ? 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ) :
          Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isInContacts ? Icons.person : Icons.person_add_outlined,
                color: isInContacts ? Colors.green : null,
              ),
              onPressed: isInContacts ? null : () => _addToContacts(user),
              tooltip: isInContacts ? 'In Contacts' : 'Add to Contacts',
            ),
            ElevatedButton(
              onPressed: () {
                // Open chat with this user
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(otherUser: user),
                  ),
                );
              },
              child: const Text('Chat'),
            ),
          ],
        ),
      ),
    );
  }
} 