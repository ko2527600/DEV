// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
// We will add getStorage later when you have your card
// We don't need to import getAnalytics here unless we use it directly

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAc_9m27QpdWADXHIRx3G2O6dbPdomZHOQ",
  authDomain: "smartstudy-ghana.firebaseapp.com",
  projectId: "smartstudy-ghana",
  storageBucket: "smartstudy-ghana.firebasestorage.app",
  messagingSenderId: "91798494947",
  appId: "1:91798494947:web:6296bd5e7e1de09dc3efd6",
  measurementId: "G-V5VKH7VYGQ"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize and export Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
// export const storage = getStorage(app); // We will uncomment this later
