importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCRB2Cxfug0NnyuAzQMgqpD4JU3K_08iKs',
  authDomain: 'coinastra-6e613.firebaseapp.com',
  projectId: 'coinastra-6e613',
  storageBucket: 'coinastra-6e613.firebasestorage.app',
  messagingSenderId: '834752846445',
  appId: '1:834752846445:web:7933fc71f67a3a1683bd64',
});

const messaging = firebase.messaging();

// Background message handler — fires when app tab is not in focus
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (!title) return;
  self.registration.showNotification(title, {
    body,
    icon: '/app/icons/Icon-192.png',
    badge: '/app/icons/Icon-192.png',
    tag: 'coinastra-alert',
    renotify: true,
  });
});
