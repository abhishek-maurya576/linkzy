# Linkzy Chat Message Flow

This diagram illustrates how messages flow through the system in the Linkzy chat application.

```
User A                                  Firebase                                  User B
  |                                        |                                        |
  |                                        |                                        |
  |  [1] Compose & Send Message            |                                        |
  | ---------------------------------->    |                                        |
  |                                        |                                        |
  |                                        |  [2] Store Message                     |
  |                                        | -------------------> Firestore         |
  |                                        |                         |              |
  |                                        |                         |              |
  |  [3] Confirm Delivery                  |                         |              |
  | <----------------------------------    |                         |              |
  |                                        |                         |              |
  |                                        |                         |              |
  |                                        |                         | [4] Real-time|
  |                                        |                         |    Update    |
  |                                        |                         |              |
  |                                        |                         v              |
  |                                        |                         |              |
  |                                        |                         |              |
  |                                        |  [5] Deliver Message    |              |
  |                                        | <------------------- Firestore         |
  |                                        |                                        |
  |                                        |                                        |
  |                                        |  [6] Push Message                      |
  |                                        | ---------------------------------->    |
  |                                        |                                        |
  |                                        |                                        |
  |                                        |  [7] Update Read Status                |
  |                                        | <----------------------------------    |
  |                                        |                                        |
  |  [8] Show Read Status                  |                                        |
  | <----------------------------------    |                                        |
  |                                        |                                        |
```

## Process Steps

1. **Compose & Send**: User A composes a message and taps the send button
2. **Store Message**: The message is sent to Firestore with "delivered: false" and "seen: false"
3. **Confirm Delivery**: User A's app shows a single checkmark indicating the message reached the server
4. **Real-time Update**: Firestore's listeners detect the new message
5. **Deliver Message**: Firebase delivers the message to User B via active listeners
6. **Push Message**: User B receives the message, UI updates to show new message
7. **Update Read Status**: When User B views the message, the app updates the message status to "seen: true"
8. **Show Read Status**: User A's message now shows double blue checkmarks indicating the message was read

## Implementation in Code

In `firebase_service.dart`:

```dart
// Sending a message
Future<void> sendMessage(
  String senderId,
  String receiverId,
  String content,
) async {
  final timestamp = FieldValue.serverTimestamp();
  
  // Create a message document
  final messageRef = _firestore.collection('messages').doc();
  
  final message = {
    'id': messageRef.id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': timestamp,
    'isDelivered': false,
    'isSeen': false,
  };
  
  await messageRef.set(message);
}

// Marking as seen
Future<void> markMessageAsSeen(String messageId) async {
  await _firestore
      .collection('messages')
      .doc(messageId)
      .update({'isSeen': true});
}
``` 