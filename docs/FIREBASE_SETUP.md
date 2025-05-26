# Firebase Setup for Linkzy

This guide provides step-by-step instructions for setting up Firebase services required by the Linkzy chat application.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click on "Add project" and provide a project name (e.g., "linkzy")
3. (Optional) Enable Google Analytics
4. Click "Create project" to complete the setup

## 2. Register Your App with Firebase

### For Android:

1. In the Firebase console, click on the Android icon to add an Android app
2. Enter your app's package name (e.g., `com.example.linkzy`)
3. (Optional) Enter your app nickname and Debug signing certificate SHA-1
4. Click "Register app"
5. Download the `google-services.json` file
6. Place the file in your project's `android/app/` directory

### For iOS:

1. In the Firebase console, click on the iOS icon to add an iOS app
2. Enter your app's bundle ID (found in your Xcode project settings)
3. (Optional) Enter your app nickname
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Add this file to your project in Xcode

### For Web:

1. In the Firebase console, click on the Web icon to add a web app
2. Enter your app's nickname
3. (Optional) Set up Firebase Hosting
4. Click "Register app"
5. Note the Firebase configuration details provided

## 3. Add Firebase SDK to Your Flutter Project

1. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase for your Flutter project:

```bash
flutterfire configure --project=[your-project-id]
```

## 4. Set Up Firebase Authentication

1. In the Firebase console, navigate to "Authentication" from the left menu
2. Click "Get Started"
3. Enable the "Email/Password" sign-in method
4. (Optional) Configure other authentication providers as needed

## 5. Set Up Cloud Firestore

1. In the Firebase console, navigate to "Firestore Database" from the left menu
2. Click "Create database"
3. Select "Start in production mode"
4. Choose a database location close to your users
5. Create the database

For details on the database schema and structure, see [Database Schema](./images/database_schema.md).

### Firestore Security Rules

Create a file named `firestore.rules` in your project root with the following content:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection rules
    match /users/{userId} {
      // Allow read access to all authenticated users
      allow read: if request.auth != null;
      
      // Allow users to create and update their own profiles
      allow create, update: if request.auth != null && request.auth.uid == userId && validUserData();
      
      // Validate user data
      function validUserData() {
        return request.resource.data.keys().hasAll(['uid', 'email', 'username']) &&
               request.resource.data.uid == userId &&
               request.resource.data.email is string &&
               request.resource.data.username is string;
      }
    }
    
    // Messages collection rules
    match /messages/{messageId} {
      // Allow authenticated users to read messages where they are sender or receiver
      allow read: if request.auth != null && 
                   (resource.data.senderId == request.auth.uid || 
                    resource.data.receiverId == request.auth.uid);
      
      // Allow authenticated users to create messages where they are the sender
      allow create: if request.auth != null && 
                     request.resource.data.senderId == request.auth.uid;
      
      // Allow users to update delivery/seen status only if they are the receiver
      allow update: if request.auth != null &&
                    resource.data.receiverId == request.auth.uid &&
                    request.resource.data.diff(resource.data).affectedKeys()
                      .hasOnly(['isDelivered', 'isSeen']);
    }
  }
}
```

Deploy the security rules:

```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes

Create a file named `firestore.indexes.json` in your project root with the following content:

```json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "senderId", "order": "ASCENDING" },
        { "fieldPath": "receiverId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "senderId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "receiverId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy the indexes:

```bash
firebase deploy --only firestore:indexes
```

## 6. Set Up Firebase Storage

1. In the Firebase console, navigate to "Storage" from the left menu
2. Click "Get Started"
3. Select "Start in production mode"
4. Choose a storage location close to your users

### Storage Rules

The default rules should be similar to:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

For better security, you can update the rules to:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile picture storage
    match /profile_pictures/{userId}.jpg {
      // Anyone can read profile pictures
      allow read: if request.auth != null;
      // Only the owner can upload their profile picture
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 7. Firebase Cloud Messaging (Optional)

1. In the Firebase console, navigate to "Messaging" from the left menu
2. Set up Cloud Messaging for your platforms:
   - For Android: No additional setup needed if you've added `google-services.json`
   - For iOS: Update your app capabilities in Xcode
   - For Web: Add the Firebase Messaging web SDK

## 8. Integrate with Flutter App

Ensure your Flutter app has the necessary dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.4
  cloud_firestore: ^5.6.8
  firebase_storage: ^12.4.6
  firebase_messaging: ^15.2.6
```

## 9. Testing Your Firebase Setup

1. Run your app and test Firebase services:

```bash
flutter run
```

2. Check the Firebase console to verify that data is being stored properly

## Common Issues and Troubleshooting

1. **Missing Google Services File**:
   - Ensure `google-services.json` is placed in `android/app/`
   - Ensure `GoogleService-Info.plist` is added to your Xcode project

2. **Authentication Issues**:
   - Verify the authentication providers are properly enabled
   - Check user email verification settings

3. **Firestore Access Denied**:
   - Verify your security rules are deployed correctly
   - Check that the queries match the rules' conditions

4. **Storage Permission Issues**:
   - Verify storage rules are deployed correctly
   - Ensure the user is authenticated before uploading files

5. **Index Errors**:
   - If you see an error message about missing indexes, click the link in the error message to create the required index

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview/)
- [Firestore Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)