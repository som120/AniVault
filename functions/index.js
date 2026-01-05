const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 🔔 Test push notification (Android)
 * Usage:
 * https://<region>-<project-id>.cloudfunctions.net/sendTestNotification?uid=USER_UID
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  try {
    const uid = req.query.uid;

    if (!uid) {
      return res.status(400).send("❌ Missing uid parameter");
    }

    // Get user document
    const userSnap = await admin.firestore().collection("users").doc(uid).get();

    if (!userSnap.exists) {
      return res.status(404).send("❌ User not found");
    }

    const data = userSnap.data();
    const fcmToken = data && data.fcmToken;

    if (!fcmToken) {
      return res.status(400).send("❌ No FCM token found for user");
    }

    // Send push notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "🔥 Test Notification",
        body: "AniVault notifications are working perfectly!",
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
        },
      },
    });

    return res.send("✅ Test notification sent successfully!");
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    return res.status(500).send(error.toString());
  }
});
