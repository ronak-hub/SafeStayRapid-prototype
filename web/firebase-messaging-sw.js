importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDPYUKUoLrjGyxIYUWTjMd8Wl-ilz2VkbM",
  authDomain: "safestay-rapid-5c29e.firebaseapp.com",
  projectId: "safestay-rapid-5c29e",
  storageBucket: "safestay-rapid-5c29e.firebasestorage.app",
  messagingSenderId: "34147668629",
  appId: "1:34147668629:web:d88637bfaab24a7304819c",
  measurementId: "G-H61V42T2BH"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});