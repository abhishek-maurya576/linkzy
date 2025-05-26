# Linkzy Firestore Database Schema

This document outlines the database schema used in the Linkzy application. The app uses Cloud Firestore, a NoSQL document database.

## Collections and Documents

### Users Collection

**Path:** `/users/{userId}`

Each document represents a user profile:

```
{
  "uid": String,           // User ID (same as the document ID)
  "email": String,         // User email address
  "username": String,      // Unique username for the user
  "profilePicUrl": String  // URL to profile picture (optional)
}
```

**Indexes Required:**
- `username` (for username search and uniqueness validation)

### Messages Collection

**Path:** `/messages/{messageId}`

Each document represents a single message:

```
{
  "id": String,            // Message ID (same as document ID)
  "senderId": String,      // User ID of message sender
  "receiverId": String,    // User ID of message recipient
  "content": String,       // Message text content
  "timestamp": Timestamp,  // Server timestamp when message was sent
  "isDelivered": Boolean,  // Whether message was delivered
  "isSeen": Boolean        // Whether message was read by recipient
}
```

**Indexes Required:**
- Composite index: `senderId ASC`, `receiverId ASC`, `timestamp DESC`
- Composite index: `senderId ASC`, `timestamp DESC`
- Composite index: `receiverId ASC`, `timestamp DESC`

## Relationships

- A user can send many messages
- A user can receive many messages
- Messages belong to exactly one sender and one recipient

## Query Examples

### Get User Profile

```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
```

### Get Messages Between Two Users

```dart
FirebaseFirestore.instance
    .collection('messages')
    .where('senderId', isEqualTo: userId1)
    .where('receiverId', isEqualTo: userId2)
    .orderBy('timestamp', descending: true)
    .get();
```

### Get Recent Chats for User

```dart
FirebaseFirestore.instance
    .collection('messages')
    .where('senderId', isEqualTo: currentUserId)
    .orderBy('timestamp', descending: true)
    .get();

FirebaseFirestore.instance
    .collection('messages')
    .where('receiverId', isEqualTo: currentUserId)
    .orderBy('timestamp', descending: true)
    .get();
```

## Security Considerations

All database access is protected by Firestore security rules that ensure:
- Users can only read messages where they are the sender or receiver
- Users can only write messages where they are the sender
- Only the receiver can update message delivery status
- User profiles are readable by any authenticated user but only writable by the owner 