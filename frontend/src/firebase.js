import { initializeApp } from 'firebase/app'
import { getAuth, GoogleAuthProvider } from 'firebase/auth'

const firebaseConfig = {
  apiKey: "AIzaSyAX3Iw8m-ax9o5hbLXlXcoz8hvbWRloQqI",
  authDomain: "finsense-finance-app.firebaseapp.com",
  projectId: "finsense-finance-app",
  storageBucket: "finsense-finance-app.firebasestorage.app",
  messagingSenderId: "604608810400",
  appId: "1:604608810400:web:37d3c13625eb963018e8c5",
  measurementId: "G-ZKCXBVNMFY",
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)

export const googleProvider = new GoogleAuthProvider()
googleProvider.addScope('email')
googleProvider.addScope('profile')
// Always show the account picker so users can switch accounts
googleProvider.setCustomParameters({ prompt: 'select_account' })

export default app
