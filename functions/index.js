const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// 1. Send Push Notification for New Chat Message
exports.onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    const chatId = event.params.chatId;
    const senderId = messageData.senderId;

    const db = getFirestore();
    const messaging = getMessaging();

    // Fetch parent chat doc
    const chatDoc = await db.doc(`chats/${chatId}`).get();
    if (!chatDoc.exists) return;

    const chatData = chatDoc.data();
    const participantIds = chatData.participantIds || [];
    const mutedBy = chatData.mutedBy || [];
    const isGroup = chatData.type === 'group';

    // Get Sender Name
    const senderDoc = await db.doc(`users/${senderId}`).get();
    const senderName = senderDoc.exists
      ? (senderDoc.data().name || senderDoc.data().displayName || 'Student')
      : 'Student';

    // Format Body based on messageType
    let bodyText = messageData.text || '';
    if (messageData.messageType === 'image') {
      bodyText = '📷 Photo';
    } else if (messageData.messageType === 'document') {
      bodyText = `📄 ${messageData.fileName || 'Document'}`;
    } else if (messageData.messageType === 'audio') {
      bodyText = '🎵 Audio file';
    } else if (messageData.messageType === 'voice') {
      bodyText = '🎤 Voice message';
    }

    // Target UIDs: Participants except sender AND users who haven't muted the chat
    const recipients = participantIds.filter(
      (uid) => uid !== senderId && !mutedBy.includes(uid)
    );

    for (const recipientUid of recipients) {
      const recipientDoc = await db.doc(`users/${recipientUid}`).get();
      if (!recipientDoc.exists) continue;

      const fcmToken = recipientDoc.data().fcmToken;
      if (!fcmToken) continue;

      const payload = {
        token: fcmToken,
        notification: {
          title: isGroup ? `${chatData.groupName || 'Group Chat'} (${senderName})` : senderName,
          body: bodyText,
        },
        data: {
          type: 'chat_message',
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          isGroup: String(isGroup),
          participantIds: participantIds.join(','),
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'onecamp_chat_channel',
            sound: 'default',
          },
        },
      };

      try {
        await messaging.send(payload);
      } catch (err) {
        console.error(`Failed to send FCM to user ${recipientUid}:`, err);
      }
    }
  }
);

// 2. Send Push Notification for Incoming WebRTC Call
exports.onCallCreated = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const callData = snap.data();
    const targetId = callData.targetId;
    const callerName = callData.callerName || 'Student';
    const isVideo = callData.isVideo;

    const db = getFirestore();
    const messaging = getMessaging();

    const targetDoc = await db.doc(`users/${targetId}`).get();
    if (!targetDoc.exists) return;

    const fcmToken = targetDoc.data().fcmToken;
    if (!fcmToken) return;

    const payload = {
      token: fcmToken,
      notification: {
        title: `Incoming ${isVideo ? 'Video' : 'Audio'} Call`,
        body: `${callerName} is calling you...`,
      },
      data: {
        type: 'call_invite',
        callId: event.params.callId,
        callerId: callData.callerId,
        callerName: callerName,
        chatId: callData.chatId,
        isVideo: String(isVideo),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'onecamp_call_channel',
          sound: 'default',
        },
      },
    };

    try {
      await messaging.send(payload);
    } catch (err) {
      console.error(`Failed to send Call FCM to user ${targetId}:`, err);
    }
  }
);
