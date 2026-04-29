importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: '%%FIREBASE_WEB_API_KEY%%',
  authDomain: '%%FIREBASE_AUTH_DOMAIN%%',
  projectId: '%%FIREBASE_PROJECT_ID%%',
  storageBucket: '%%FIREBASE_STORAGE_BUCKET%%',
  messagingSenderId: '%%FIREBASE_MESSAGING_SENDER_ID%%',
  appId: '%%FIREBASE_WEB_APP_ID%%',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (!title) return;
  self.registration.showNotification(title, {
    body: body ?? '',
    icon: '/icons/Icon-192.png',
  });
});
