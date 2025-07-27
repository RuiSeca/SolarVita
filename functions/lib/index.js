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
exports.cleanupUserData = exports.cleanupOldNotifications = exports.sendDirectNotification = exports.updateUserToken = exports.sendNotification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// Enhanced notification handler for all notification types
exports.sendNotification = functions.firestore
    .document('users/{userId}/notifications/{notificationId}')
    .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = context.params.userId;
    // Get user's FCM tokens
    const userTokensSnapshot = await db.collection('users').doc(userId).collection('fcm_tokens').get();
    if (userTokensSnapshot.empty) {
        console.log(`No FCM tokens found for user ${userId}`);
        return null;
    }
    const tokens = userTokensSnapshot.docs.map(doc => doc.data().token).filter(Boolean);
    if (tokens.length === 0) {
        console.log(`No valid FCM tokens found for user ${userId}`);
        return null;
    }
    const { title, body, type, data = {}, imageUrl, actionUrl } = notificationData;
    // Configure notification based on type
    const notificationConfig = getNotificationConfig(type);
    const message = {
        notification: Object.assign({ title: title || notificationConfig.defaultTitle, body: body || notificationConfig.defaultBody }, (imageUrl && { imageUrl })),
        data: Object.assign({ id: snap.id, type: type, actionUrl: actionUrl || '', click_action: 'FLUTTER_NOTIFICATION_CLICK' }, data),
        android: {
            notification: Object.assign({ sound: 'default', channelId: notificationConfig.channelId, priority: notificationConfig.priority }, (imageUrl && { imageUrl })),
            data: Object.assign({ id: snap.id, type: type, actionUrl: actionUrl || '' }, Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))),
        },
        apns: {
            payload: {
                aps: {
                    sound: 'default',
                    badge: 1,
                    'content-available': 1,
                },
            },
            fcmOptions: Object.assign({ analyticsLabel: `${type}_notification` }, (imageUrl && { imageUrl })),
        },
    };
    try {
        // Send to all user's devices
        const responses = await Promise.allSettled(tokens.map(token => messaging.send(Object.assign(Object.assign({}, message), { token }))));
        // Log successful/failed sends
        let successCount = 0;
        let failureCount = 0;
        const failedTokens = [];
        responses.forEach((response, index) => {
            if (response.status === 'fulfilled') {
                successCount++;
            }
            else {
                failureCount++;
                failedTokens.push(tokens[index]);
                console.error(`Failed to send to token ${tokens[index]}:`, response.reason);
            }
        });
        console.log(`Notification sent: ${successCount} success, ${failureCount} failures`);
        // Clean up invalid tokens
        if (failedTokens.length > 0) {
            await cleanupInvalidTokens(userId, failedTokens);
        }
        return {
            success: successCount,
            failures: failureCount,
            totalTokens: tokens.length
        };
    }
    catch (error) {
        console.error('Error sending notification:', error);
        throw error;
    }
});
// Helper function to get notification configuration based on type
function getNotificationConfig(type) {
    switch (type) {
        case 'NotificationType.chat':
            return {
                channelId: 'chat_notifications',
                priority: 'high',
                defaultTitle: 'New Message',
                defaultBody: 'You have a new message',
            };
        case 'NotificationType.supportRequest':
            return {
                channelId: 'social_notifications',
                priority: 'high',
                defaultTitle: 'Support Request',
                defaultBody: 'Someone wants to support you',
            };
        case 'NotificationType.supportAccepted':
            return {
                channelId: 'social_notifications',
                priority: 'default',
                defaultTitle: 'Support Accepted',
                defaultBody: 'Your support request was accepted',
            };
        case 'NotificationType.supportRejected':
            return {
                channelId: 'social_notifications',
                priority: 'default',
                defaultTitle: 'Support Declined',
                defaultBody: 'Your support request was declined',
            };
        case 'NotificationType.like':
        case 'NotificationType.comment':
        case 'NotificationType.follow':
        case 'NotificationType.mention':
        case 'NotificationType.post':
            return {
                channelId: 'social_notifications',
                priority: 'default',
                defaultTitle: 'Social Update',
                defaultBody: 'You have a new social notification',
            };
        case 'NotificationType.achievement':
            return {
                channelId: 'achievement_notifications',
                priority: 'default',
                defaultTitle: 'Achievement Unlocked',
                defaultBody: 'You earned a new achievement',
            };
        case 'NotificationType.reminder':
            return {
                channelId: 'reminder_notifications',
                priority: 'high',
                defaultTitle: 'Reminder',
                defaultBody: 'You have a reminder',
            };
        default:
            return {
                channelId: 'social_notifications',
                priority: 'default',
                defaultTitle: 'Notification',
                defaultBody: 'You have a new notification',
            };
    }
}
// Helper function to clean up invalid FCM tokens
async function cleanupInvalidTokens(userId, invalidTokens) {
    const batch = db.batch();
    for (const token of invalidTokens) {
        const tokenQuery = await db.collection('users').doc(userId).collection('fcm_tokens')
            .where('token', '==', token).get();
        tokenQuery.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
    }
    try {
        await batch.commit();
        console.log(`Cleaned up ${invalidTokens.length} invalid tokens for user ${userId}`);
    }
    catch (error) {
        console.error('Error committing batch:', error);
    }
}
exports.updateUserToken = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { token } = data;
    const userId = context.auth.uid;
    try {
        await db.collection('users').doc(userId).collection('fcm_tokens').doc('current').set({
            token: token,
            platform: data.platform || 'unknown',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error updating token:', error);
        throw new functions.https.HttpsError('internal', 'Failed to update token');
    }
});
// Function to send notification to specific user (callable function)
exports.sendDirectNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, title, body, type, notificationData = {}, actionUrl, imageUrl } = data;
    if (!userId || !title || !body) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    try {
        // Create notification document which will trigger the sendNotification function
        const notificationRef = db.collection('users').doc(userId).collection('notifications').doc();
        await notificationRef.set({
            id: notificationRef.id,
            title,
            body,
            type: type || 'NotificationType.system',
            data: notificationData,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            actionUrl: actionUrl || null,
            imageUrl: imageUrl || null,
        });
        return { success: true, notificationId: notificationRef.id };
    }
    catch (error) {
        console.error('Error sending direct notification:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send notification');
    }
});
// Function to clean up old notifications (scheduled function)
exports.cleanupOldNotifications = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    try {
        // Find all users
        const usersSnapshot = await db.collection('users').get();
        let totalDeleted = 0;
        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            // Get old notifications for this user
            const oldNotificationsSnapshot = await db.collection('users').doc(userId).collection('notifications')
                .where('timestamp', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
                .get();
            if (!oldNotificationsSnapshot.empty) {
                const batch = db.batch();
                oldNotificationsSnapshot.docs.forEach(doc => {
                    batch.delete(doc.ref);
                });
                await batch.commit();
                totalDeleted += oldNotificationsSnapshot.docs.length;
            }
        }
        console.log(`Cleaned up ${totalDeleted} old notifications`);
        return { deletedCount: totalDeleted };
    }
    catch (error) {
        console.error('Error cleaning up notifications:', error);
        throw error;
    }
});
// Function to handle user deletion and cleanup
exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
    const userId = user.uid;
    try {
        const batch = db.batch();
        // Delete user's notifications
        const notificationsSnapshot = await db.collection('users').doc(userId).collection('notifications').get();
        notificationsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        // Delete user's FCM tokens
        const tokensSnapshot = await db.collection('users').doc(userId).collection('fcm_tokens').get();
        tokensSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`Cleaned up data for deleted user: ${userId}`);
        return { success: true };
    }
    catch (error) {
        console.error('Error cleaning up user data:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map