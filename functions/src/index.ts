import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

export const sendChatNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    if (notificationData.type !== 'chat_message') {
      return null;
    }
    
    const { fcmToken, title, body, data } = notificationData;
    
    if (!fcmToken) {
      return null;
    }
    
    const message = {
      notification: {
        title: title || 'New Message',
        body: body || 'You have a new message',
      },
      data: {
        type: 'chat',
        conversationId: data.conversationId || '',
        senderId: data.senderId || '',
        senderName: data.senderName || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
      android: {
        notification: {
          sound: 'default',
          channelId: 'chat_channel',
          priority: 'high' as const,
        },
        data: {
          type: 'chat',
          conversationId: data.conversationId || '',
          senderId: data.senderId || '',
          senderName: data.senderName || '',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
        fcmOptions: {
          analyticsLabel: 'chat_notification',
        },
      },
    };
    
    try {
      const response = await messaging.send(message);
      
      // Delete the notification document after sending
      await snap.ref.delete();
      
      return response;
    } catch (error) {
      throw error;
    }
  });

export const updateUserToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { token } = data;
  const userId = context.auth.uid;
  
  try {
    await db.collection('users').doc(userId).update({
      fcmToken: token,
      lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error updating token:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update token');
  }
});