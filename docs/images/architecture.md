# Linkzy Application Architecture Diagram

Below is a simplified ASCII representation of Linkzy's architecture:

```
+---------------------------+
|        UI Layer           |
|---------------------------|
|  - Home Screen            |
|  - Chat Screen            |
|  - Profile Screen         |
|  - Settings Screen        |
+------------||-------------+
             ||
             \/
+---------------------------+
|     Business Logic        |
|---------------------------|
|  - Firebase Service       |
|  - State Management       |
|  - Auth Controllers       |
+------------||-------------+
             ||
             \/
+---------------------------+
|        Data Layer         |
|---------------------------|
|  - Cloud Firestore        |
|  - Firebase Auth          |
|  - Firebase Storage       |
+---------------------------+
```

## Key Interactions

1. User interacts with the UI Layer
2. UI Layer calls methods in Business Logic Layer
3. Business Logic Layer manages state and makes calls to Data Layer
4. Data Layer communicates with Firebase services 
5. Updates flow back up the chain in real-time (Firebase → Data → Logic → UI)

## Folder Structure Mapping

```
lib/
├── core/               # Core utilities and shared components
├── features/
│   ├── auth/           # Authentication (Login, Register)
│   ├── chat/           # Chat screens and components  
│   ├── settings/       # Settings screens
│   └── user/           # User profile features
├── services/
│   └── firebase_service.dart # Interface to Firebase
├── app.dart            # App configuration and theme
├── main.dart           # Entry point
└── firebase_options.dart # Firebase configuration
``` 