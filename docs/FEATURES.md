# Linkzy Features Documentation

This document outlines the features and functionality of the Linkzy chat application.

## Core Features

### User Authentication

- **User Registration**: Create new accounts with email and password
- **User Login**: Secure authentication with email and password
- **Password Reset**: Ability to reset forgotten passwords via email
- **Authentication Persistence**: Stay logged in across app restarts
- **Logout**: Securely log out from the application

### User Profiles

- **Profile Creation**: Set username, display name and profile picture during onboarding
- **Profile Editing**: Update username, display name, and profile picture
- **Multiple Edit Entry Points**: Edit profile from both Profile tab and Settings
- **Intuitive Edit Interface**: Modal bottom sheet with clear editing options
- **Display Name**: Set and manage your real name or preferred display name
- **Username Uniqueness**: Ensures all usernames are unique across the platform
- **Name Priority**: Custom contact name > display name > username for identification
- **Predefined Avatars**: Choose from a collection of predefined avatar images
- **Custom Profile Pictures**: Upload your own profile picture from your device
- **Profile Viewing**: View other users' profiles

For a detailed guide on profile management, see the [User Guide](./USER_GUIDE.md#managing-your-profile).

### Messaging

- **One-to-One Chat**: Private conversations between two users
- **Real-time Messages**: Instant delivery of messages between users
- **Message Status**: Track when messages are delivered and read
- **Message History**: Access full conversation history
- **Message Timestamps**: Display when messages were sent
- **Message Notifications**: Receive sound and popup notifications for new messages

For a detailed look at how messages flow through the system, see the [Chat Message Flow Diagram](./images/chat_flow.md).

### Search and Discovery

- **User Search**: Find other users by username
- **Recent Chats**: Quick access to recent conversations sorted by most recent
- **Conversation Preview**: See the last message and time in chat list

## UI/UX Features

### Home Screen

The home screen serves as the main hub for the application, featuring:

- **Chat List**: Displays recent conversations with message previews in descending order (newest first)
- **Navigation Bar**: Easy access to other app sections
- **Status Indicators**: Shows online/offline status of users
- **Unread Indicators**: Visual cues for unread messages

### Chat Screen

The chat screen provides a rich messaging experience with:

- **Message Bubbles**: Visually distinct bubbles for sent/received messages
- **Timestamps**: Message sending time display
- **Read/Delivery Status**: Indicators for message status
- **Input Bar**: Text input with send button
- **User Info**: Display of the conversation partner's name and avatar
- **Emoji Support**: Enhanced display of emoji characters

### Profile Screen

The profile screen allows users to:

- **View Profile**: See their own profile information
- **Edit Profile**: Change username and profile picture
- **Choose Avatar**: Select from predefined avatar images
- **Upload Picture**: Upload custom profile pictures from device gallery
- **Account Settings**: Access account-related settings

### Settings Screen

The settings screen provides configuration options for:

- **Appearance**: Toggle between light and dark mode themes
- **Notifications**: Configure notification preferences
- **Account Management**: 
  - Edit profile information
  - Change password
  - Manage blocked users
  - Delete account
- **Sign Out**: Log out of the account

## Technical Features

### Real-time Functionality

Linkzy provides real-time capabilities powered by Firestore:

- **Live Message Updates**: Messages appear instantly for both sender and receiver
- **Status Synchronization**: Read receipts update in real-time
- **User Presence**: Ability to see when other users are online

### Data Persistence

The app maintains data consistency through:

- **Offline Support**: Messages can be viewed when offline
- **Message Queueing**: Messages sent when offline are queued for delivery
- **Sync Mechanisms**: Automatic synchronization when connection is restored

### Security Features

The application implements several security measures:

- **Secure Authentication**: Firebase Authentication for user management
- **Data Access Control**: Firestore security rules to protect user data
- **Message Privacy**: Ensures messages can only be read by participants

### Performance Optimizations

To ensure a smooth user experience, the app includes:

- **Lazy Loading**: Messages load incrementally for faster initial loading
- **Image Optimization**: Profile pictures are compressed and cached
- **State Management**: Efficient state handling for responsive UI
- **Query Optimization**: Optimized Firestore queries with proper indexing

## Planned Features

The following features are planned for future releases:

- **Group Messaging**: Create and participate in group conversations
- **Media Sharing**: Send images, videos, and files in conversations
- **Push Notifications**: Receive notifications for new messages when app is closed
- **Voice Messages**: Record and send audio messages
- **Video Calling**: Integrated video call functionality
- **Message Search**: Search through message content
- **Message Reactions**: React to messages with emojis
- **Unread Message Count**: Display badge with unread message count 