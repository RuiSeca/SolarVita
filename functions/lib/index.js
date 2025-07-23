"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUserToken = exports.sendChatNotification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
exports.sendChatNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
    console.log('🔥 Cloud Function triggered for notification:', context.params.notificationId);
    const notificationData = snap.data();
    console.log('📄 Notification data:', JSON.stringify(notificationData, null, 2));
    if (notificationData.type !== 'chat_message') {
        console.log('❌ Not a chat message notification, skipping');
        return null;
    }
    const { fcmToken, title, body, data } = notificationData;
    console.log('🎯 FCM Token:', fcmToken ? 'Present' : 'Missing');
    console.log('📝 Title:', title);
    console.log('📝 Body:', body);
    if (!fcmToken) {
        console.log('❌ No FCM token found for user');
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
                priority: 'high',
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
    console.log('📤 Sending FCM message:', JSON.stringify(message, null, 2));
    try {
        const response = await messaging.send(message);
        console.log('✅ Successfully sent FCM message:', response);
        // Delete the notification document after sending
        await snap.ref.delete();
        console.log('🗑️ Notification document deleted');
        return response;
    }
    catch (error) {
        console.error('❌ Error sending FCM message:');
        console.error('🔍 Error details:', error);
        throw error;
    }
});
exports.updateUserToken = functions.https.onCall(async (data, context) => {
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
    }
    catch (error) {
        console.error('Error updating token:', error);
        throw new functions.https.HttpsError('internal', 'Failed to update token');
    }
});
//# sourceMappingURL=index.js.map