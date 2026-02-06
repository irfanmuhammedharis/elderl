/* eslint-disable no-undef */
// Firebase Messaging service worker for web push notifications.
// Uses Firebase compat SDK to match web/index.html.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAQGeCD5HnoQVEANvKZ0PNAYA6-IttsJUg',
  authDomain: 'elder-care-995b8.firebaseapp.com',
  projectId: 'elder-care-995b8',
  storageBucket: 'elder-care-995b8.firebasestorage.app',
  messagingSenderId: '163430176460',
  appId: '1:163430176460:web:e75dafa4ef7488c5a85469',
  databaseURL: 'https://elder-care-995b8-default-rtdb.firebaseio.com',
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
firebase.messaging();
