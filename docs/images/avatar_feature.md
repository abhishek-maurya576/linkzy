# Predefined Avatar Feature

This document describes the implementation of the predefined avatar selection feature in Linkzy.

## Overview

The predefined avatar feature allows users to select from a collection of default avatar images instead of uploading their own profile pictures. This feature provides users with appealing profile image options while reducing the need for storage space and image upload functionality.

## Implementation Details

### Avatar Model

The avatar feature is implemented using a dedicated model class (`Avatar`) that represents each predefined avatar:

```dart
class Avatar {
  final String id;
  final String path;

  Avatar({
    required this.id,
    required this.path,
  });

  static List<Avatar> getDefaultAvatars() {
    return [
      Avatar(id: '1', path: 'assets/images/avatar/avatar_1_img.png'),
      Avatar(id: '2', path: 'assets/images/avatar/avatar_2_img.png'),
      // Additional avatars...
    ];
  }
}
```

### Avatar Selection Screen

A dedicated screen allows users to browse and select from available avatars:

```dart
class AvatarSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatars = Avatar.getDefaultAvatars();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar'),
      ),
      body: GridView.builder(
        // Grid implementation for avatar selection
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.pop(context, avatars[index].path);
            },
            // Avatar display implementation
          );
        },
      ),
    );
  }
}
```

### Avatar Integration

The avatar feature is integrated into the user profile system:

1. **Profile Screen**: Users can choose between uploading an image or selecting an avatar
2. **Firebase Service**: Modified to support both network images and asset images
3. **Image Display**: Updated to handle both image types in all UI components

### Avatar Storage

Unlike custom profile pictures, avatars are stored as asset references rather than URLs:

- **Custom Images**: Stored in Firebase Storage and referenced by URL
- **Predefined Avatars**: Stored as asset paths (e.g., 'assets/images/avatar/avatar_1_img.png')

### UI Display

The UI differentiates between avatar types:

```dart
// Example of image display logic
Widget buildProfileImage(String profilePicUrl) {
  if (profilePicUrl.isNotEmpty) {
    return profilePicUrl.startsWith('assets/')
        ? Image.asset(profilePicUrl)
        : Image.network(profilePicUrl);
  } else {
    return FallbackImageWidget();
  }
}
```

## User Flow

1. User navigates to their profile
2. User taps on their profile picture or the camera icon
3. User selects "Choose Avatar" from the options
4. User is presented with a grid of available avatars
5. User selects an avatar
6. The selected avatar is set as their profile picture
7. The avatar is displayed in chat lists, conversations, and profile screens

## Technical Considerations

- **Assets Management**: Avatars are included in the app bundle
- **Performance**: Asset images load faster than network images
- **Offline Support**: Asset images are available offline
- **Consistency**: Same avatars are available to all users

## Future Enhancements

Possible future enhancements to the avatar feature:

1. **More Avatar Options**: Expanding the collection of available avatars
2. **Categorized Avatars**: Organizing avatars into categories (e.g., animals, characters)
3. **Animated Avatars**: Adding support for animated avatars
4. **Custom Avatar Creation**: Tools to create personalized avatars
5. **Seasonal Avatars**: Special avatars for holidays and events 