# SolarVita Firebase Cloud Functions

This directory contains Firebase Cloud Functions for handling push notifications and backend operations.

## Functions Overview

### `sendNotification`
- **Trigger**: Firestore document creation at `users/{userId}/notifications/{notificationId}`
- **Purpose**: Automatically sends push notifications when new notifications are created
- **Features**:
  - Supports all notification types (chat, support requests, achievements, etc.)
  - Sends to all user devices
  - Handles invalid token cleanup
  - Proper Android/iOS configuration

### `updateUserToken`
- **Trigger**: HTTPS callable function
- **Purpose**: Updates user's FCM token when they log in or refresh
- **Usage**: Called from Flutter app during initialization

### `sendDirectNotification`
- **Trigger**: HTTPS callable function  
- **Purpose**: Send notifications directly via API call
- **Usage**: For administrative notifications or system messages

### `cleanupOldNotifications`
- **Trigger**: Scheduled (daily)
- **Purpose**: Removes notifications older than 30 days
- **Benefits**: Keeps database clean and reduces storage costs

### `cleanupUserData`
- **Trigger**: User deletion
- **Purpose**: Cleans up user data when account is deleted
- **Features**: Removes notifications and FCM tokens

## Deployment

### Prerequisites
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize project (if not done):
   ```bash
   firebase init functions
   ```

### Deploy Functions
1. Install dependencies:
   ```bash
   cd functions
   npm install
   ```

2. Build TypeScript:
   ```bash
   npm run build
   ```

3. Deploy to Firebase:
   ```bash
   firebase deploy --only functions
   ```

### Local Development
1. Start emulator:
   ```bash
   npm run serve
   ```

2. Test functions locally:
   ```bash
   npm run shell
   ```

## Notification Flow

1. **App Action**: User sends support request, message, etc.
2. **Flutter Service**: Creates notification document in Firestore
3. **Cloud Function**: Automatically triggers and sends push notification
4. **User Devices**: Receive push notification via FCM
5. **App Handling**: Notification tapped → navigation to relevant screen

## Supported Notification Types

- `NotificationType.chat` - New chat messages
- `NotificationType.supportRequest` - Support requests 
- `NotificationType.supportAccepted` - Support request accepted
- `NotificationType.supportRejected` - Support request declined
- `NotificationType.like` - Post likes
- `NotificationType.comment` - Post comments
- `NotificationType.achievement` - Achievement unlocked
- `NotificationType.reminder` - Reminders and alerts

## Security

- All functions require proper authentication
- Token cleanup prevents stale FCM tokens
- User data cleanup ensures privacy compliance
- Rate limiting and error handling included

## Monitoring

- View function logs:
  ```bash
  firebase functions:log
  ```

- Monitor in Firebase Console:
  - Functions → Logs
  - Functions → Metrics
  - Cloud Messaging → Reports