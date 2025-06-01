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
               request.resource.data.username is string &&
               (request.resource.data.displayName == null || 
                request.resource.data.displayName is string);
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
    
    // Contacts collection rules
    match /contacts/{contactId} {
      // Allow users to read their own contacts
      allow read: if request.auth != null && 
                  resource.data.ownerUserId == request.auth.uid;
      
      // Allow users to create contacts where they are the owner
      allow create: if request.auth != null && 
                    request.resource.data.ownerUserId == request.auth.uid &&
                    validContactData();
      
      // Allow users to update their contacts
      allow update: if request.auth != null &&
                    resource.data.ownerUserId == request.auth.uid;
      
      // Allow users to delete their contacts
      allow delete: if request.auth != null &&
                    resource.data.ownerUserId == request.auth.uid;
      
      // Validate contact data
      function validContactData() {
        return request.resource.data.keys().hasAll(['ownerUserId', 'contactUserId']) &&
               request.resource.data.ownerUserId is string &&
               request.resource.data.contactUserId is string &&
               (request.resource.data.contactName == null || 
                request.resource.data.contactName is string);
      }
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
    },
    {
      "collectionGroup": "contacts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "ownerUserId", "order": "ASCENDING" },
        { "fieldPath": "contactUserId", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## 10. Securing Firebase Configuration

For security reasons, Firebase configuration files containing API keys and other sensitive information should not be committed to your repository. Follow these steps to handle Firebase configuration securely:

### Setting up firebase_options.dart

1. The `firebase_options.dart` file is excluded from git via the `.gitignore` file
2. An example template `firebase_options.example.dart` is provided in the repository
3. When setting up the project locally:
   - Copy the example file: `cp lib/firebase_options.example.dart lib/firebase_options.dart`
   - Update it with your own Firebase project credentials
   - Never commit your actual `firebase_options.dart` file

### Handling Google Services Files

Similarly, the Android and iOS configuration files are excluded:
- `google-services.json` for Android
- `GoogleService-Info.plist` for iOS

These files should be obtained from your Firebase console and added to your local project, but not committed to the repository.

### Using Environment Variables (Alternative Approach)

For CI/CD pipelines or deployment automation, consider using environment variables:

```dart
// Example of using environment variables instead of hardcoded values
final firebaseOptions = FirebaseOptions(
  apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
  appId: const String.fromEnvironment('FIREBASE_APP_ID'),
  messagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID'),
  projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
  // Other options...
);
```

Then provide these during build:

```bash
flutter build apk --dart-define=FIREBASE_API_KEY=your_api_key ...
```

This approach keeps sensitive data out of your codebase entirely.