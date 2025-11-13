README: Contractor Portal (Firebase OTP Login)

This document is a complete guide to the Contractor Portal feature, its "hybrid" authentication system, and a full log of the troubleshooting steps required to make it work.

1. Core Architecture

The goal is to use Firebase for what it's good at (handling phone number OTP verification) while keeping your own backend for what you need (managing user data, sessions, and issuing your own JWT).

The flow is:

Flutter App: Asks user for a phone number.

Flutter App: Calls FirebaseAuth.instance.verifyPhoneNumber(...).

Firebase: Sends an SMS OTP to the user.

Flutter App: User enters the OTP.

Flutter App: Calls _auth.signInWithCredential(...) to verify the OTP with Firebase.

Firebase: Confirms the OTP is valid and sends a Firebase ID Token back to the app.

Flutter App: (This is the hybrid step) Sends this Firebase ID Token to your backend at /api/auth/firebase.

Your Backend: Verifies the token with the firebase-admin SDK, finds or creates a mason (contractor) record, saves a session, and issues its own app-specific JWT.

Flutter App: Saves this app JWT and logs the user into the Contractor Portal.

sequenceDiagram
    participant FlutterApp as Flutter App
    participant Firebase
    participant YourBackend as Your Node.js Backend

    FlutterApp->>+Firebase: 1. Request OTP for +91...
    Firebase-->>FlutterApp: 2. Send SMS to user (Firebase handles this)
    FlutterApp->>+Firebase: 3. Verify OTP ("123456")
    Firebase-->>-FlutterApp: 4. Returns Firebase ID Token
    FlutterApp->>+YourBackend: 5. /api/auth/firebase (sends ID Token)
    YourBackend->>+Firebase: 6. Verify ID Token
    Firebase-->>-YourBackend: 7. Token is Valid (for user: +91...)
    YourBackend->>YourBackend: 8. Upsert `mason` record, create session
    YourBackend-->>-FlutterApp: 9. Returns { jwt: "...", sessionToken: "...", mason: {...} }
    FlutterApp->>FlutterApp: 10. Save tokens, navigate to /contractor_home


2. The Core Code Files

Here are the complete, working files for this authentication flow.

contractor_login_screen.dart: The Flutter UI screen that handles user input and orchestrates the Firebase login.

firebase_auth.dart: The AuthService class that abstracts the backend communication (the "hybrid step").

contractor_server_routes.js: The runnable Node.js/Express code for your backend, translated from your CONTRACTORSERVERSIDE.MD file.

3. The Setup & Troubleshooting Guide (The "Gotchas")

This is the most critical part. Getting this to work required solving three major errors.

Step 1: Backend Setup

Your backend needs the firebase-admin SDK to verify tokens.

Install Dependencies: npm install firebase-admin jsonwebtoken

Get Service Account:

In Firebase Console > Project settings > Service accounts.

Click "Generate new private key". A JSON file will download.

Set Environment Variable:

CRITICAL: Do NOT commit this JSON file. Open it, copy the entire contents, and paste it as a single-line string into your .env file.

.env

FIREBASE_SERVICE_ACCOUNT_JSON={"type": "service_account", "project_id": "...", ...}
JWT_SECRET=your-own-jwt-secret


Use the contractor_server_routes.js file (provided) to handle the /api/auth/firebase endpoint.

Step 2: Firebase Console Setup (Solving the Errors)

This is where we spent all our time. If you get errors, it's 99% certain the problem is one of these steps.

Problem A: CONFIGURATION_NOT_FOUND (Error 17499)

This error means "Firebase doesn't recognize your app."

Solution 1: Add SHA-1 Fingerprints (MANDATORY)

In your Flutter project's android folder, run: ./gradlew signingReport

This will output your SHA-1 and SHA-256 keys. You need the keys from the Variant: debug block. (Your SHA-1 is D5:B3:...:41:A1).

In Firebase Console > Project settings > Your apps > Android, scroll to SHA certificate fingerprints.

Click Add fingerprint and paste your SHA-1 key. Do it again for your SHA-256 key.

Solution 2: Enable Phone Provider

In Firebase Console > Build > Authentication > Sign-in method.

Click Add new provider and enable Phone.

Solution 3: Sync Your Config File

After adding the SHA keys, you MUST download a fresh google-services.json file from your Firebase Project Settings.

Replace the old android/app/google-services.json file with this new one.

Make sure the file android/app/build.gradle contains this line at the very bottom: apply plugin: 'com.google.gms.google-services'

Problem B: BILLING_NOT_ENABLED (Error 17499)

This error means "Your app is configured, but you haven't enabled billing."

Solution: Upgrade to Blaze Plan

Firebase requires a billing account to prevent SMS spam.

Go to Firebase Console > Project settings > Usage and billing.

Click Upgrade and select the "Blaze" (Pay-as-you-go) plan.

This is still free. You only pay if you go over the 10,000 free OTPs per month. This step just verifies you are a real person.

Step 3: Flutter Environment Setup

Emulator vs. Physical Phone (The IP Address)

This is the final piece. Your app needs to talk to your local backend server.

For the Android Emulator:
The special IP 10.0.2.2 means "the computer running this emulator."

In firebase_auth.dart, your baseUrl should be:
baseUrl: 'http://10.0.2.2:4000' (Assuming your server runs on port 4000).

For a Physical Phone:
10.0.2.2 will NOT work. Your phone needs your computer's Wi-Fi IP.

Make sure your phone and computer are on the same Wi-Fi.

Find your computer's IP (e.g., 192.168.1.5) using ipconfig (Windows) or ifconfig (Mac).

Your baseUrl must be:
baseUrl: 'http://192.168.1.5:4000'

Step 4: Debug vs. Release APKs (Your Final Question)

Question: "If I share an APK on WhatsApp, will the debug SHA-1 key work?"

Answer: YES. When you run flutter build apk, Flutter (by default) signs this "release" APK with the same debug key (debug.keystore).

Since you've already added your debug SHA-1 key to Firebase, any APK you build on your machine and share directly will work perfectly. You only need a production key when you publish to the Google Play Store.