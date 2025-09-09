const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Enregistrer le token FCM côté serveur
exports.registerToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const token = data.token;
  if (!token) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Token is required'
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();

  if (userSnap.exists) {
    await userRef.set({ fcmToken: token }, { merge: true });
  } else {
    await db.collection('agents').doc(uid).set({ fcmToken: token }, { merge: true });
  }

  return { success: true };
});

// Envoyer une notification aux utilisateurs via FCM
exports.sendAdminNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin privileges required'
    );
  }

  const title = data.title;
  const message = data.message;
  const targetType = data.targetType || 'all';

  const db = admin.firestore();

  // Sauvegarder la notification
  await db.collection('notifications').add({
    title,
    message,
    targetType,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'sent'
  });

  let tokens = [];

  if (targetType === 'all' || targetType === 'users') {
    const usersSnapshot = await db
      .collection('users')
      .where('fcmToken', '!=', null)
      .get();
    tokens = tokens.concat(usersSnapshot.docs.map(doc => doc.data().fcmToken));
  }

  if (targetType === 'all' || targetType === 'agents') {
    const agentsSnapshot = await db
      .collection('agents')
      .where('fcmToken', '!=', null)
      .get();
    tokens = tokens.concat(agentsSnapshot.docs.map(doc => doc.data().fcmToken));
  }

  if (tokens.length === 0) {
    return { success: true, recipients: 0 };
  }

  await admin.messaging().sendMulticast({
    tokens,
    notification: { title, body: message }
  });

  return { success: true, recipients: tokens.length };
});

