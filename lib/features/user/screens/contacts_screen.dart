import 'package:flutter/material.dart';
import '../../../services/firebase_service.dart';
import '../models/app_user.dart';
import '../models/contact.dart';
import '../../chat/screens/chat_screen.dart';
import '../screens/search_user_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _firebaseService = FirebaseService();
  String? _currentUserId;
  bool _isLoading = true;
  String? _errorMessage;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseService.currentUserId;
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_currentUserId == null) {
        setState(() {
          _errorMessage = 'You must be logged in to view contacts';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeContact(Contact contact) async {
    try {
      await _firebaseService.removeContact(contact.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editContactName(Contact contact) {
    final TextEditingController nameController = TextEditingController(text: contact.contactName);
    
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text('Edit Contact Name'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter custom name',
            labelText: 'Contact Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newName = nameController.text.trim();
                await _firebaseService.updateContactName(contact.id, newName);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contact name updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update contact name: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => const SearchUserScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Center(
        child: Text('You must be logged in to view contacts'),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _navigateToSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search),
                    SizedBox(width: 12),
                    Text('Search for users to add'),
                  ],
                ),
              ),
            ),
          ),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
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
            ),
            
          // Contacts list
          Expanded(
            child: StreamBuilder<List<Contact>>(
              stream: _firebaseService.getUserContacts(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading contacts: ${snapshot.error}'),
                  );
                }
                
                final contacts = snapshot.data ?? [];
                
                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contact_phone_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for users to add them to your contacts',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToSearch,
                          icon: Icon(Icons.search),
                          label: Text('Find Users'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: contacts.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _buildContactItem(contact);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSearch,
        child: const Icon(Icons.person_add),
        tooltip: 'Add Contact',
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final user = contact.userDetails;
    
    if (user == null) {
      return ListTile(
        title: Text(contact.contactName.isEmpty ? 'Unknown User' : contact.contactName),
        subtitle: Text('User details not available'),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeContact(contact),
        ),
      );
    }
    
    // Use custom name if set, then display name if available, then username
    final displayName = contact.contactName.isNotEmpty 
        ? contact.contactName 
        : user.displayName.isNotEmpty 
            ? user.displayName 
            : user.username;
    
    // Check if we're using a custom contact name
    final isCustomName = contact.contactName.isNotEmpty;
    // Check if we have a display name from the user
    final hasDisplayName = user.displayName.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          backgroundImage: user.profilePicUrl.isNotEmpty 
              ? user.profilePicUrl.startsWith('assets/')
                  ? AssetImage(user.profilePicUrl) as ImageProvider
                  : NetworkImage(user.profilePicUrl) 
              : null,
          child: user.profilePicUrl.isEmpty
              ? Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCustomName && hasDisplayName)
              Text(
                'Originally: ${user.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text('@${user.username}'),
            Text(user.email, 
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editContactName(contact),
              tooltip: 'Edit Name',
            ),
            IconButton(
              icon: const Icon(Icons.message, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(otherUser: user),
                  ),
                );
              },
              tooltip: 'Chat',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _removeContact(contact),
              tooltip: 'Remove',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
} 