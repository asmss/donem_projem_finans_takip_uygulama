const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendReminderNotification = functions.firestore
  .document("fcmMessages/{messageId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const token = data.token;
    const title = data.title || "Hatırlatma";
    const body = data.body || "";

    const message = {
      notification: { title, body },
      token: token,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Bildirim gönderildi:", response);
    } catch (error) {
      console.error("Bildirim hatası:", error);
    }
  });
