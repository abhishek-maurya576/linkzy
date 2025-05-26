# Linkzy Architecture Documentation

This document provides an overview of the architecture and code structure of the Linkzy chat application.

## Architecture Diagram

For a visual representation of the application architecture, please see the [Architecture Diagram](./images/architecture.md).

## Project Structure

```
linkzy/
├── lib/
│   ├── app.dart                 # App configuration and theme
│   ├── main.dart                # Entry point
│   ├── firebase_options.dart    # Firebase configuration
│   ├── core/                    # Core utilities and shared components
│   ├── features/                # Feature modules
│   │   ├── auth/                # Authentication feature
│   │   ├── chat/                # Chat feature
│   │   ├── settings/            # Settings feature
│   │   └── user/                # User profile feature
│   └── services/                # Services layer
│       └── firebase_service.dart # Firebase service implementation
├── assets/                      # Static assets (images, animations)
└── test/                        # Test files
```

## Architecture Overview

Linkzy follows a feature-first architecture with a clear separation of concerns. The application is divided into the following layers:

1. **Presentation Layer**: Contains UI components, screens, and widgets
2. **Business Logic Layer**: Contains services and state management
3. **Data Layer**: Handles data fetching and persistence

## Key Components

### Services

#### FirebaseService

The `FirebaseService` class serves as the primary interface for all Firebase-related operations. It handles:

- Authentication (login, registration, password reset)
- User profile management
- Message sending and retrieval
- Real-time data synchronization

```dart
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Authentication methods
  Future<Map<String, dynamic>> loginUser(String email, String password) { ... }
  Future<Map<String, dynamic>> registerUser(String email, String password) { ... }
  
  // User profile methods
  Future<void> createUserProfile(AppUser user) { ... }
  Future<AppUser?> getUserProfile(String userId) { ... }
  
  // Chat methods
  Future<void> sendMessage(String senderId, String receiverId, String content) { ... }
  Stream<List<Message>> getMessages(String userId1, String userId2) { ... }
}
```

### Models

#### AppUser

Represents a user in the application with their profile information.

```dart
class AppUser {
  final String uid;
  final String email;
  final String username;
  final String profilePicUrl;
  
  // Constructor and methods...
}
```

#### Message

Represents a chat message with metadata for delivery status.

```dart
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isSeen;
  final bool isDelivered;
  
  // Constructor and methods...
}
```

## Screens and Navigation

The app uses a bottom navigation bar for main navigation between features, with each feature implementing its own internal navigation.

Key screens include:
- Login/Registration
- Chat List
- Chat Conversation
- User Profile
- Settings

## State Management

State management is handled using a combination of:

1. **Provider** - For simpler state management needs
2. **Riverpod** - For more complex state management requirements

## Data Flow

1. **User Authentication**:
   - User enters credentials
   - FirebaseService authenticates with Firebase Auth
   - On success, user profile is retrieved from Firestore

2. **Messaging Flow**:
   - User selects a contact
   - FirebaseService streams messages between the two users
   - Messages are displayed in the UI
   - When sending, messages are saved to Firestore and streamed in real-time

## Firebase Integration

The app uses the following Firebase services:

1. **Firebase Authentication** - User sign-up and login
2. **Cloud Firestore** - Database for users and messages
3. **Firebase Storage** - For storing profile pictures
4. **Firebase Cloud Messaging** - For push notifications

## Security Rules

Firestore security rules are implemented to ensure that:
- Users can only read their own messages
- Users can only write messages where they are the sender
- User profiles have appropriate read/write permissions

## Performance Optimizations

1. **Indexed Queries** - Firestore queries are optimized with appropriate indexes
2. **Message Pagination** - Messages are loaded in chunks for better performance
3. **Image Caching** - Profile pictures are cached for faster loading

## Testing Strategy

The application includes:
1. **Unit Tests** - For testing individual components
2. **Widget Tests** - For testing UI components
3. **Integration Tests** - For testing feature workflows 