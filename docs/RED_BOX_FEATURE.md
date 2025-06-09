# Red Box Secure Messaging

## Overview
Red Box is a PIN-protected secure messaging environment within Linkzy that provides users with an enhanced level of privacy and security for sensitive communications. It creates a fully isolated messaging container that protects conversations from unauthorized access, even if someone gains access to the user's device.

## Security Model

### Key Security Principles
- **Complete Message Isolation**: Red Box messages are stored separately from regular chats, in a dedicated encrypted storage area.
- **PIN Protection**: Access requires a numeric PIN that only the user knows.
- **Plausible Deniability**: The decoy PIN system allows users to protect sensitive content even under duress.
- **Independent Authentication**: Red Box authentication is separate from the main app authentication.
- **Zero Access Without PIN**: No API, backdoor, or recovery method exists to access Red Box contents without the PIN.

### Privacy by Design
- No screenshots permitted within Red Box
- No message sync across devices
- No backup to cloud services
- Option for local-only storage with no server transmission

## Key Features

### 1. PIN Authentication
- Numeric PIN required for access (minimum 6 digits)
- Configurable auto-lock after inactivity (1-30 minutes)
- PIN change capability with current PIN verification

### 2. Decoy PIN System
- Secondary "decoy" PIN that shows fake conversations
- User configures two separate PINs:
  - Regular PIN - Shows actual secure messages
  - Decoy PIN - Shows AI-generated fake conversations
- System cannot distinguish between real and decoy PINs (both appear valid)

### 3. Enhanced Decoy Mode
- AI-generated realistic fake conversations 
- Multiple conversation types (casual, business, family)
- Fake contacts with realistic names and conversations
- Complete isolation from real contacts and messages

### 4. Panic Button
- Emergency exit mechanism for immediately leaving Red Box
- Configurable gestures:
  - Triple tap (anywhere on screen)
  - Shake device
  - Double tap back button
- Customizable sensitivity settings
- Exits to home screen or other app based on configuration

### 5. End-to-End Encryption
- Messages encrypted on-device before transmission
- Local and server copies remain encrypted
- Only decrypted with correct PIN entry
- Encryption keys never leave the device

### 6. Offline Mode
- Fully functional without internet connection
- Local caching of messages
- Background sync when connection returns
- Visual indicator of connection status
- Pending message status tracking

## User Guide

### Accessing Red Box
1. From the main app, tap the Red Box icon in the navigation menu
2. Enter your Red Box PIN when prompted
3. For decoy mode, enter your decoy PIN instead

### Setting Up Red Box (First Use)
1. Create a secure PIN (minimum 6 digits)
2. Create a decoy PIN (different from secure PIN)
3. Configure auto-lock timeout
4. Configure panic button gesture

### Starting a New Secure Conversation
1. Enter Red Box with your regular PIN
2. Tap the "+" button to view contacts
3. Select a contact to start a secure conversation
4. Send messages as normal - they will be encrypted and stored securely

### Using Decoy Mode
1. Enter Red Box with your decoy PIN
2. Navigate through the fake conversations
3. You can send and receive messages within decoy mode, but these are simulated
4. Decoy conversations are completely isolated from your real secure messages

### Using the Panic Button
1. When in Red Box, use your configured gesture (e.g., triple tap)
2. The app will immediately exit Red Box
3. No trace of Red Box usage will remain in the app's recent screens

### Offline Usage
1. Red Box works fully offline
2. Messages sent while offline are marked as "Pending"
3. When connection returns, messages sync automatically
4. An indicator shows connection status

## Technical Implementation

### Functional Flow Diagram

The following diagram illustrates the user flow and key components of the Red Box feature:

Source file: [Red Box Flow Diagram](images/screens/redbox_flow_diagram.mmd)

### Architecture
Red Box is implemented as an isolated feature within the app with its own:
- Database instances
- Message models
- UI components
- Authentication system
- Encryption services

### Component Architecture

The Red Box feature is built using the following component architecture:

Source file: [Red Box Component Architecture](images/screens/redbox_component_diagram.mmd)

### Key Components
1. **RedBoxService**: Core service managing all Red Box functionalities
   - Authentication
   - Message encryption/decryption
   - Message storage and retrieval
   - PIN verification

2. **PanicButtonService**: Handles emergency exit functionalities
   - Gesture detection
   - Quick app exit
   - Configuration storage

3. **DecoyMessageService**: Manages the decoy PIN system
   - Fake contact generation
   - AI-powered fake message creation
   - Conversation simulation

4. **ConnectivityService**: Manages offline capabilities
   - Connection monitoring
   - Message caching
   - Synchronization

### Data Flow
1. User enters PIN
2. System checks if it's a real or decoy PIN (without revealing which)
3. Based on PIN type, appropriate data source is selected
4. For real PIN: Actual messages are fetched, decrypted and displayed
5. For decoy PIN: Generated fake conversations are displayed

### Security Considerations
- PINs are never stored directly, only secure hashes
- Message encryption uses AES-256 with PIN-derived keys
- No server-side ability to decrypt messages
- Database is compartmentalized to prevent data leakage

## Best Practices
1. Choose a PIN that is easy to remember but hard to guess
2. Configure a realistic decoy PIN and use it occasionally to maintain "live" looking conversations
3. Set up the panic button gesture that feels natural but won't trigger accidentally
4. Enable auto-lock for short durations when handling particularly sensitive information
5. Remember there is no PIN recovery - if you forget both your regular and decoy PINs, data will be permanently inaccessible

## Limitations
- Red Box messages only exist on the current device
- No cross-device message sync
- No cloud backup of Red Box messages
- Once deleted, messages cannot be recovered 