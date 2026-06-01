importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

try {
  importScripts('/firebase-config.js');
} catch (_) {
  // firebase-config.js is injected by deployment. Without it, web push is disabled.
}

const firebaseConfig = self.VAULTED_FIREBASE_CONFIG;

if (firebaseConfig) {
  firebase.initializeApp(firebaseConfig);

  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const { title, body } = payload.notification ?? {};
    if (!title) return;
    self.registration.showNotification(title, {
      body: body ?? '',
      icon: '/icons/Icon-192.png',
    });
  });
}
