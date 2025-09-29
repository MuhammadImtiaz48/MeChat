const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  const {
    targetToken,
    title,
    body,
    type,
    senderId,
    chatId,
    callId,
    callType,
    senderName,
    senderEmail,
    senderImage,
    extraData,
  } = data;

  const payload = {
    token: targetToken,
    notification: { title, body },
    data: {
      type,
      senderId,
      senderName,
      chatId,
      callId,
      callType: callType || '',
      senderEmail: senderEmail || '',
      senderImage: senderImage || '',
      ...extraData,
    },
    android: {
      notification: {
        sound: type === 'call' ? 'ringtone' : 'default',
        channelId: 'chat_channel_v1',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: type === 'call' ? 'ringtone.caf' : 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(payload);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});