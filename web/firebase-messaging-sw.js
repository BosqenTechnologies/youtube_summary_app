importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-sw.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-sw.js");

firebase.initializeApp({
  apiKey: "AIzaSyDzsrIQ_8mNVONnU2fePTQpVuyRBaIDUQg",
  authDomain: "summary-6ffef.firebaseapp.com",
  projectId: "summary-6ffef",
  storageBucket: "summary-6ffef.firebasestorage.app",
  messagingSenderId: "723380008177",
  appId: "1:723380008177:web:e395724531c3a8895c6550",
  measurementId: "G-9K41JMV26D"
});

const messaging = firebase.messaging();
