# ![linkzy_icon](https://github.com/user-attachments/assets/92a1e58d-6307-401d-a140-f2556db16d9f)

# Linkzy v1.4.0 Release Notes

**Release Date:** June 6, 2025

## Overview

We are excited to announce the release of Linkzy v1.4.0! This major update brings significant improvements and new features to our real-time chat application built with Flutter and Firebase, enhancing both functionality and user experience.

## What's New

- **Red Box Feature Intoduce**: The Red Box is a high-security, hidden chat zone inside Linkzy.
- **Display Name Feature**: Added support for customizable display names separate from usernames
- **UI Overhaul**: Comprehensive visual improvements throughout the application
- **UX Improvements**: Streamlined workflows and interactions for better usability
- **Performance Optimizations**: Faster loading times and improved responsiveness


## Features

### Core Features

- **Real-time Messaging**
  - Instant message delivery with live updates
  - Read receipts and delivery confirmations
  - **NEW:** Animated chat screen backgrounds
  - Message history synchronization
  - Sound notifications for new messages

- **Contact Management**
  - **NEW:** Dedicated contact screen for saving favorite contacts
  - **NEW:** Quick access to frequent conversations
  - **NEW:** Contact organization features

- **User Authentication**
  - Secure email and password authentication
  - Account management
  - Password reset functionality

- **User Profiles**
  - **NEW:** Fully enabled profile editing
  - **NEW:** Display name support separate from username
  - Customizable usernames
  - Profile pictures (upload from device)
  - Predefined avatar selection - Choose from 9 stylish avatars

- **Search Functionality**
  - Find users by username or display name
  - Quick access to recent conversations

- **UI/UX Features**
  - **IMPROVED:** Redesigned interface with better visual hierarchy
  - **IMPROVED:** More intuitive navigation and interactions
  - Message bubbles with enhanced status indicators
  - Conversation preview in chat list
  - Chat list in descending order (newest conversations first)
  - Enhanced emoji support in messages

## 📕 Enhanced Red Box Feature

**💬 Secret Chat Mode with PIN/Password-Based Access** – now accessible via Settings page

### 🔴 Feature Objective
The Red Box is a high-security, hidden chat zone inside Linkzy. It provides:

- 🔐 Secure PIN/passphrase protection
- 🎭 Hidden or disguised access
- 💬 Separate encrypted message storage
- ⚙️ Now also accessible via Settings > Red Box

### 🗂️ Updated User Access Flow

**🔽 Access Points**
User can enter Red Box via:

- 🧤 Hidden Trigger: gesture (e.g., double-tap logo, long press, corner tap)
- ⚙️ Settings Option: Tap on disguised or clearly labeled "Red Box" menu in Settings

**🔐 Authentication & Access Flow**
1. User taps Red Box (via Settings or hidden gesture)
2. App checks if PIN/passphrase exists
   - ❌ If not → Create PIN screen
   - ✅ If yes → Enter PIN screen
3. On valid entry → Load Red Box Chat UI
4. On wrong PIN → Retry limit, delay lockout (optional)

## Platforms

This release is available for:

- **📱 Android**
  - `app-release.apk` – Universal APK for all Android architectures (56.7MB)
  - `app-arm64-v8a-release.apk` – Optimized for modern Android devices (24.0MB)
  - `app-armeabi-v7a-release.apk` – Compatible with older Android devices (21.6MB)
  - `app-x86_64-release.apk` – Suitable for emulators and x86 devices (25.1MB)
  - `app-release.aab` – App Bundle for Google Play Store submission (31.3MB)

- **🌐 Web**
  - Web build for deployment on any static hosting service

## Installation

### Android
1. Download the appropriate APK for your device
   - Most modern phones: `app-arm64-v8a-release.apk`
   - Older devices: `app-armeabi-v7a-release.apk`
   - Emulators: `app-x86_64-release.apk`
   - Any Android device (larger file): `app-release.apk`
2. Enable "Install from Unknown Sources" in your device settings
3. Open the downloaded APK file and follow the installation prompts
4. Launch Linkzy from your app drawer

### Web
1. Deploy the web build to your web server directory
2. Configure your web server to serve the files
3. Access via your web domain

## Technical Details

### Dependencies
- Flutter: ^3.6.2
- Firebase Core: ^3.13.1
- Firebase Auth: ^5.5.4
- Firebase Storage: ^12.4.6
- Firebase Messaging: ^15.2.6
- Cloud Firestore: ^5.6.8
- Other dependencies as listed in `pubspec.yaml`

### Architecture
- **Frontend:** Flutter (UI framework)
- **Backend:** Firebase services
- **State Management:** Provider & Riverpod
- **Storage:** Cloud Firestore (NoSQL database)
- **Authentication:** Firebase Authentication

## Known Issues

- Minor UI glitches on some Android devices with custom fonts
- Web notifications require manual permission
- First-time authentication may take longer than subsequent logins

## Upcoming Features

We're already working on future releases that will include:

- Group messaging
- Media sharing (images, videos)
- Push notifications for background alerts
- Voice messages
- Video calling integration
- Message search functionality
- Message reactions with emojis

## Feedback & Support

We welcome your feedback and suggestions for improving Linkzy. Please submit issues and feature requests through our GitHub repository.

For support, contact us at:
- GitHub Issues: https://github.com/abhishek-maurya576/linkzy/issues
- Email: official.linkzy@gmail.com

## License

Linkzy is licensed under the MIT License. See the [LICENSE](../LICENSE) file for details.

---

Thank you for using Linkzy! We hope you enjoy these updates and look forward to bringing you more exciting features in future releases.

*The Linkzy Team* 