const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onCall } = require("firebase-functions/v2/https");

initializeApp();
const db = getFirestore();

exports.sendRepairNotification = onDocumentCreated(
  "repair_requests/{requestId}",
  async (event) => {
    const repairRequestData = event.data.data();
    const shopId = repairRequestData.shopId;
    const customerId = repairRequestData.customerId;

    if (!shopId) {
      console.log("❌ shopId missing");
      return;
    }

    const shopDoc = await db.collection("users").doc(shopId).get();
    if (!shopDoc.exists) {
      console.log("❌ Shop not found:", shopId);
      return;
    }

    const fcmToken = shopDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("❌ Shop has no FCM token.");
      return;
    }

    // ✅ Get customer name
    let customerName = "A customer";
    if (customerId) {
      const customerDoc = await db.collection("users").doc(customerId).get();
      if (customerDoc.exists) {
        customerName = customerDoc.data().fullName || customerName;
      }
    }

    const payload = {
      notification: {
        title: "New Repair Request",
        body: `${customerName} submitted a new request for ${repairRequestData.deviceName || "a device"}`,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        target: "requests"
      },
      token: fcmToken,
    };

    try {
      const res = await getMessaging().send(payload);
      console.log("✅ Notification sent:", res);
    } catch (error) {
      console.error("❌ Failed to send notification:", error);
    }
  }
);

exports.sendChatNotification = onCall(async (req) => {
  const { receiverId, message } = req.data;

  if (!receiverId || !message) {
    throw new Error("receiverId and message are required");
  }

  const userDoc = await db.collection("users").doc(receiverId).get();
  if (!userDoc.exists) {
    console.log("❌ Receiver not found:", receiverId);
    return;
  }

  const fcmToken = userDoc.data().fcmToken;
  if (!fcmToken) {
    console.log("❌ Receiver has no FCM token.");
    return;
  }

  const payload = {
    notification: {
      title: "New Message",
      body: message,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      target: "chat"
    },
    token: fcmToken,
  };

  try {
    const res = await getMessaging().send(payload);
    console.log("✅ Chat Notification sent:", res);
    return { success: true };
  } catch (err) {
    console.error("❌ Failed to send chat notification:", err);
    throw new Error("Notification failed");
  }
});

exports.sendStatusUpdateNotification = onCall(async (req) => {
  const { receiverId, status } = req.data;

  if (!receiverId || !status) {
    throw new Error("receiverId and status are required");
  }

  const userDoc = await db.collection('users').doc(receiverId).get();
  if (!userDoc.exists) {
    console.log("❌ Receiver not found:", receiverId);
    return;
  }

  const fcmToken = userDoc.data().fcmToken;
  if (!fcmToken) {
    console.log("❌ Receiver has no FCM token.");
    return;
  }

  const payload = {
    notification: {
      title: "Repair Status Updated",
      body: `Your repair status is now: ${status}`,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      target: "track"
    },
    token: fcmToken,
  };

  try {
    const res = await getMessaging().send(payload);
    console.log("✅ Status Update Notification sent:", res);
    return { success: true };
  } catch (err) {
    console.error("❌ Failed to send status update notification:", err);
    throw new Error("Notification failed");
  }
});

const { getAuth } = require("firebase-admin/auth");

exports.deleteUserAccountByAdmin = onCall(async (req) => {
  const { uid } = req.data;

  if (!uid) {
    throw new Error("UID is required.");
  }

  try {
    await getAuth().deleteUser(uid);
    console.log(`✅ Successfully deleted auth user: ${uid}`);
    return { success: true };
  } catch (error) {
    console.error("❌ Error deleting auth user:", error);
    throw new Error("Failed to delete auth user");
  }
});
