importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB-HgQixM9sZG6MNzgpIQbJxzHsyQ7RmGE',
  authDomain: 'vaulted-prod-2026.firebaseapp.com',
  projectId: 'vaulted-prod-2026',
  storageBucket: 'vaulted-prod-2026.firebasestorage.app',
  messagingSenderId: '729564960430',
  appId: '1:729564960430:web:e502f79b1b66c7b8a47f3f',
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
