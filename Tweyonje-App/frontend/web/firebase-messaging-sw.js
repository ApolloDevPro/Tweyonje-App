// Web Firebase Cloud Messaging service worker.
//
// This runs independently of the Flutter app in the browser background and is
// what actually receives push notifications for web. Replace the config values
// below with the ones from your Firebase console (Web app) FIRST, then unregister
// the placeholder (see comments in web/index.html).
//
// Reference: https://firebase.google.com/docs/cloud-messaging/js/send-message
//            https://firebase.google.com/docs/cloud-messaging/js/receive

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

const CONFIG_PLACEHOLDER =
  '_PLACEHOLDER_MESSAGING_SENDER_ID_MAKE_SURE_YOU_REPLACE_THIS_';

const firebaseConfig = {
  apiKey: 'AIzaSyCYab7dFMw_UR9gk4mg0H9YHlqMvsPt0rE',
  authDomain: 'tweyonje-8f1ea.firebaseapp.com',
  projectId: 'tweyonje-8f1ea',
  storageBucket: 'tweyonje-8f1ea.firebasestorage.app',
  messagingSenderId: '427328126917',
  appId: '1:427328126917:web:ce354d2e5a83e07a0c15ac',
};

const hasValidConfig =
  firebaseConfig.messagingSenderId !== CONFIG_PLACEHOLDER &&
  !firebaseConfig.projectId.startsWith('YOUR_');

if (hasValidConfig) {
  try {
    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
      console.log('[firebase-messaging-sw.js] Received background message:', payload);

      const notification = payload.notification || payload.data || {};
      const title = notification.title || 'Tweyonje';
      const options = {
        body: notification.body || '',
        icon: notification.icon || '/favicon.png',
        data: payload.data || {},
      };
      return self.registration.showNotification(title, options);
    });
  } catch (e) {
    console.warn('[firebase-messaging-sw.js] init skipped:', e);
  }
} else {
  console.warn(
    '[firebase-messaging-sw.js] Placeholder config detected. ' +
      'Replace it before enabling web push, or remove this file if unused.',
  );
}
