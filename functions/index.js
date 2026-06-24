const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// Trigger: chats/{chatId}/messages/{messageId} -> har naye message par chalega
exports.sendChatNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const {senderId, receiverId, text} = message;

      // Receiver ka FCM token + sender ka naam lao
      const receiverDoc = await db.collection("users").doc(receiverId).get();
      const senderDoc = await db.collection("users").doc(senderId).get();
      const fcmToken = receiverDoc.data()?.fcmToken;
      const senderName = senderDoc.data()?.name || "New message";

      if (!fcmToken) return;

      // Receiver ke total unread messages count karo (badge ke liye)
      const chatsSnap = await db
          .collection("chats")
          .where("participants", "array-contains", receiverId)
          .where("lastSeen", "==", false)
          .where("lastSenderId", "!=", receiverId)
          .get();
      const badgeCount = chatsSnap.size;

      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body: text,
        },
        apns: {
          payload: {
            aps: {badge: badgeCount},
          },
        },
        android: {
          notification: {
            channelId: "chat_messages",
          },
        },
      });
    },
);