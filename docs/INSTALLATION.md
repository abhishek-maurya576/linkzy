# Linkzy Installation Guide

This guide will walk you through the process of setting up and running the Linkzy chat application on different platforms.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (v3.6.0 or later)
- [Dart](https://dart.dev/get-dart) (v3.6.0 or later)
- [Git](https://git-scm.com/downloads)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- Firebase CLI (for Firebase deployment)

## Clone the Repository

```bash
git clone https://github.com/abhishek-maurya576/linkzy.git
cd linkzy
```

## Firebase Setup

1. **Create a Firebase Project**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Click "Add Project" and follow the setup wizard

2. **Configure Firebase for Flutter**
   - Install Firebase CLI: `npm install -g firebase-tools`
   - Login to Firebase: `firebase login`
   - Initialize Firebase: `firebase init` and select Firestore, Authentication, and Storage

3. **Set up Firebase Authentication**
   - In the Firebase Console, navigate to Authentication
   - Enable Email/Password authentication

4. **Set up Firestore**
   - In the Firebase Console, navigate to Firestore Database
   - Create a database in production mode
   - Deploy the Firestore security rules: `firebase deploy --only firestore:rules`

5. **Set up Firebase Storage**
   - In the Firebase Console, navigate to Storage
   - Initialize Storage with default settings

## Configuration

1. **Connect Firebase to Flutter**

   ```bash
   flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
   flutterfire configure
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

## Running the App

### Web

```bash
flutter run -d chrome
```

### Android

```bash
flutter run -d [android-device-id]
```
You can get the list of connected devices with `flutter devices`

### iOS (macOS only)

```bash
flutter run -d [ios-device-id]
```

## Building for Production

### Web

```bash
flutter build web
firebase deploy --only hosting
```

### Android

```bash
flutter build apk --release
```
The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

### iOS (macOS only)

```bash
flutter build ios --release
```
Then open the iOS project in Xcode and follow the deployment steps.

## Troubleshooting

### Common Issues

1. **Firebase Dependencies Error**
   - Make sure you have the correct Firebase packages in your pubspec.yaml
   - Ensure the Firebase configuration files are properly set up

2. **Android Build Issues**
   - Check Android SDK version in `android/app/build.gradle`
   - Make sure Java compatibility is set correctly

3. **Web Build Issues**
   - Ensure web support is enabled: `flutter config --enable-web`

For more help, refer to the [Flutter documentation](https://flutter.dev/docs) or open an issue in the repository. 