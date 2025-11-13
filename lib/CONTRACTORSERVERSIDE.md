# Contractor OTP Login (Firebase) + Backend JWT — README

A complete, end-to-end guide to implement phone-number OTP login with Firebase on Flutter, verified on your Node/Express backend, and issued as your own JWT + session. Includes setup, code samples, routes, schema, and edge cases. No screenshots, only code and text.

---

## 1) What you’re building

* **Frontend (Flutter)** uses **Firebase Phone Auth** to verify the user owns a phone number.
* **Backend (Express + Drizzle + Postgres)** verifies the Firebase ID Token, **upserts the contractor (mason)**, creates a short **session row**, and returns:

  * **your JWT** (used for your APIs)
  * a short-lived **sessionToken** (for refresh/logout)
  * the **contractor (mason)** payload

You **do not store OTPs**. Firebase takes care of them. Your DB stores the **phone**, **firebaseUid**, **KYC status**, and **session**.

---

## 2) Architecture at a glance

```
Flutter ──(OTP via Firebase Auth)──► Firebase
   │                                   │
   │(Firebase ID Token)                 │ Verifies phone ownership
   └────────────► /api/auth/firebase ───┘
                     │
                     ▼
              Backend verifies token with Firebase Admin
                     │
               Upsert mason (by uid/phone)
                     │
           Create session row (auth_sessions)
                     │
   ◄────────── Return { jwt, sessionToken, mason } ───────────
```

---

## 3) Prerequisites

* Flutter app set up with:

  * `firebase_core`, `firebase_auth`
  * Android SHA-1/256 added in Firebase console
  * `google-services.json` in `android/app`
  * `GoogleService-Info.plist` in `ios/Runner`

* Node server with:

  * `firebase-admin`, `jsonwebtoken`, `dotenv`, `express`
  * Drizzle ORM hooked to Postgres
  * `.env` containing:

    * `FIREBASE_SERVICE_ACCOUNT_JSON={...}` as one line (escaped `\\n` in private key)
    * `JWT_SECRET=super-secret`
    * `DATABASE_URL=postgres://...`

---

## 4) Backend: Files & Code

### 4.1 Install packages

```bash
npm i firebase-admin jsonwebtoken dotenv
```

### 4.2 Firebase Admin bootstrap

`server/src/firebase/admin.ts`

```ts
import admin from "firebase-admin";

if (!admin.apps.length) {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON missing");
  const creds = JSON.parse(raw);
  if (creds.private_key?.includes("\\n")) {
    creds.private_key = creds.private_key.replace(/\\n/g, "\n");
  }

  admin.initializeApp({
    credential: admin.credential.cert(creds),
  });
}

export const firebaseAdmin = admin;
```

Load it near the top of your server entry (after `dotenv.config(...)`):

```ts
// index.ts
import dotenv from 'dotenv';
dotenv.config();
import './src/firebase/admin';
```

### 4.3 Drizzle schema (key tables)

You already have these in your schema; ensure they exist:

```ts
// mason_pc_side: contractor master
export const masonPcSide = pgTable("mason_pc_side", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 100 }).notNull(),
  phoneNumber: text("phone_number").notNull(),
  firebaseUid: varchar("firebase_uid", { length: 128 }).unique(),
  kycStatus: varchar("kyc_status", { length: 50 }).default("none"),
  pointsBalance: integer("points_balance").notNull().default(0),
  // ... dealerId, userId, timestamps, etc.
});
```

```ts
// auth_sessions: short session for refresh/logout
export const authSessions = pgTable("auth_sessions", {
  sessionId: uuid("session_id").primaryKey().defaultRandom(),
  masonId: uuid("mason_id").notNull().references(() => masonPcSide.id, { onDelete: "cascade" }),
  sessionToken: varchar("session_token", { length: 128 }).notNull().unique(),
  createdAt: timestamp("created_at", { withTimezone: true, precision: 6 }).defaultNow().notNull(),
  expiresAt: timestamp("expires_at", { withTimezone: true, precision: 6 }).notNull(),
}, (t) => [
  index("idx_auth_sessions_mason_id").on(t.masonId),
  index("idx_auth_sessions_session_token").on(t.sessionToken),
]);
```

> If `auth_sessions` doesn’t exist yet, create via SQL:

```sql
CREATE TABLE IF NOT EXISTS auth_sessions (
  session_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mason_id uuid NOT NULL REFERENCES mason_pc_side(id) ON DELETE CASCADE,
  session_token varchar(128) NOT NULL UNIQUE,
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  expires_at timestamptz(6) NOT NULL,
  CONSTRAINT auth_sessions_session_token_unique UNIQUE (session_token)
);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_mason_id ON auth_sessions(mason_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_session_token ON auth_sessions(session_token);
```

### 4.4 Auth routes (Firebase → your JWT)

`server/src/routes/authFirebase.ts`

```ts
import { Express, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { getAuth } from "firebase-admin/auth";
import crypto from "crypto";
import { db } from "../db/db";
import { masonPcSide } from "../db/schema";
import { authSessions } from "../db/schema";
import { eq } from "drizzle-orm";

const JWT_TTL_SECONDS = 60 * 60 * 24 * 7; // 7 days

export default function setupAuthFirebaseRoutes(app: Express) {
  // 1) Exchange Firebase ID token -> your JWT + session
  app.post("/api/auth/firebase", async (req: Request, res: Response) => {
    try {
      const { idToken } = req.body;
      if (!idToken) return res.status(400).json({ success: false, error: "idToken required" });

      const decoded = await getAuth().verifyIdToken(idToken);
      const firebaseUid = decoded.uid;
      const phone = decoded.phone_number || null;
      if (!phone) return res.status(400).json({ success: false, error: "Phone missing in Firebase token" });

      // upsert mason
      let mason = (await db.select().from(masonPcSide).where(eq(masonPcSide.firebaseUid, firebaseUid)).limit(1))[0];
      if (!mason) {
        mason = (await db.select().from(masonPcSide).where(eq(masonPcSide.phoneNumber, phone)).limit(1))[0];
        if (!mason) {
          const created = await db.insert(masonPcSide).values({
            id: crypto.randomUUID(),
            name: "New Contractor",
            phoneNumber: phone,
            firebaseUid,
            kycStatus: "none",
            pointsBalance: 0,
          }).returning();
          mason = created[0];
        } else if (!mason.firebaseUid) {
          await db.update(masonPcSide).set({ firebaseUid }).where(eq(masonPcSide.id, mason.id));
        }
      }

      // create session
      const sessionToken = crypto.randomBytes(32).toString("hex");
      const expiresAt = new Date(Date.now() + JWT_TTL_SECONDS * 1000);
      await db.insert(authSessions).values({
        sessionId: crypto.randomUUID(),
        masonId: mason.id,
        sessionToken,
        createdAt: new Date(),
        expiresAt,
      });

      // issue your JWT
      const jwtToken = jwt.sign(
        { sub: mason.id, role: "mason", phone, kyc: mason.kycStatus },
        process.env.JWT_SECRET!,
        { expiresIn: JWT_TTL_SECONDS }
      );

      return res.status(200).json({
        success: true,
        jwt: jwtToken,
        sessionToken,
        sessionExpiresAt: expiresAt,
        mason: { id: mason.id, phoneNumber: mason.phoneNumber, kycStatus: mason.kycStatus, pointsBalance: mason.pointsBalance },
      });
    } catch (e) {
      console.error("auth/firebase error:", e);
      return res.status(401).json({ success: false, error: "Invalid Firebase token" });
    }
  });

  // 2) Logout: delete session
  app.post("/api/auth/logout", async (req: Request, res: Response) => {
    try {
      const token = req.header("x-session-token");
      if (!token) return res.status(400).json({ success: false, error: "x-session-token required" });
      await db.delete(authSessions).where(eq(authSessions.sessionToken, token));
      return res.status(200).json({ success: true, message: "Logged out" });
    } catch (e) {
      return res.status(500).json({ success: false, error: "Logout failed" });
    }
  });

  // 3) Refresh: rotate session token, issue new JWT
  app.post("/api/auth/refresh", async (req: Request, res: Response) => {
    try {
      const token = req.header("x-session-token");
      if (!token) return res.status(400).json({ success: false, error: "x-session-token required" });

      const [session] = await db.select().from(authSessions).where(eq(authSessions.sessionToken, token)).limit(1);
      if (!session || !session.expiresAt || session.expiresAt < new Date()) {
        return res.status(401).json({ success: false, error: "Session expired" });
      }

      const [mason] = await db.select().from(masonPcSide).where(eq(masonPcSide.id, session.masonId)).limit(1);
      if (!mason) return res.status(401).json({ success: false, error: "Unknown user" });

      const newToken = crypto.randomBytes(32).toString("hex");
      const newExp = new Date(Date.now() + JWT_TTL_SECONDS * 1000);
      await db.update(authSessions).set({ sessionToken: newToken, expiresAt: newExp }).where(eq(authSessions.sessionId, session.sessionId));

      const jwtToken = jwt.sign(
        { sub: mason.id, role: "mason", phone: mason.phoneNumber, kyc: mason.kycStatus },
        process.env.JWT_SECRET!,
        { expiresIn: JWT_TTL_SECONDS }
      );

      return res.status(200).json({ success: true, jwt: jwtToken, sessionToken: newToken, sessionExpiresAt: newExp });
    } catch (e) {
      return res.status(500).json({ success: false, error: "Refresh failed" });
    }
  });
}
```

### 4.5 Register routes in `index.ts`

```ts
import setupAuthFirebaseRoutes from './src/routes/authFirebase';

// ... after app + middleware:
setupAuthFirebaseRoutes(app); // register before protected endpoints
```

### 4.6 Sample cURL

```bash
# Exchange Firebase ID token -> your JWT
curl -X POST http://localhost:8000/api/auth/firebase \
  -H "Content-Type: application/json" \
  -d '{"idToken":"<FIREBASE_ID_TOKEN_FROM_APP>"}'
```

---

## 5) Flutter: Setup & Code

### 5.1 Dependencies

`pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  http: ^1.2.0
  shared_preferences: ^2.2.2
```

### 5.2 Initialize Firebase

`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // use FlutterFire CLI to generate this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

> Generate `firebase_options.dart` using FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5.3 OTP UI (updated hybrid logic)

`lib/screens/auth/contractor_login_screen.dart`

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContractorLoginScreen extends StatefulWidget {
  const ContractorLoginScreen({super.key});

  @override
  State<ContractorLoginScreen> createState() => _ContractorLoginScreenState();
}

class _ContractorLoginScreenState extends State<ContractorLoginScreen> {
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final phoneNumber = _phoneController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Optional: auto-completion path
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed'))
          );
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e'))
      );
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    final otp = _otpController.text.trim();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCred.user!.getIdToken();

      final res = await http.post(
        Uri.parse('http://localhost:8000/api/auth/firebase'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      if (res.statusCode != 200) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${res.body}'))
        );
        return;
      }

      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', data['jwt']);
      await prefs.setString('sessionToken', data['sessionToken']);
      await prefs.setString('masonId', data['mason']['id']);
      await prefs.setString('kycStatus', data['mason']['kycStatus'] ?? 'none');

      setState(() => _isLoading = false);

      // Navigate to contractor home
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contractor_home',
        (r) => false,
        arguments: data['mason'],
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e'))
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Portal'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              _isOtpSent ? 'Verify your number' : 'Sign in with your phone',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isOtpSent
                ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                : 'We will send a one-time password (OTP) to your mobile number.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+919876543210',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              readOnly: _isOtpSent,
            ),
            if (_isOtpSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.password),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                child: Text(_isOtpSent ? 'SIGN IN / SIGN UP' : 'SEND OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 5.4 Persisting session and auto-login

On app start:

```dart
Future<bool> restoreSession() async {
  final prefs = await SharedPreferences.getInstance();
  final jwt = prefs.getString('jwt');
  final sessionToken = prefs.getString('sessionToken');
  if (jwt == null || sessionToken == null) return false;

  // optionally call /api/auth/refresh to rotate tokens
  // if refresh OK, save new tokens and return true
  return true;
}
```

If `restoreSession()` returns `false`, show the OTP login screen.

### 5.5 Logout

```dart
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('sessionToken');

  if (token != null) {
    await http.post(
      Uri.parse('http://localhost:8000/api/auth/logout'),
      headers: {"x-session-token": token},
    );
  }

  await prefs.remove('jwt');
  await prefs.remove('sessionToken');
  await prefs.remove('masonId');
  await prefs.remove('kycStatus');

  await FirebaseAuth.instance.signOut();
}
```

---

## 6) Requesting protected APIs

Attach your **JWT**:

```
GET /api/some-protected
Authorization: Bearer <jwt>
```

On 401/403, you can attempt `/api/auth/refresh` with `x-session-token`.

---

## 7) KYC gating logic

* **Allow** creating/updating a contractor record at first login (kycStatus starts as `none`).
* Gate sensitive features:

  * If `kycStatus != "approved"`, show KYC flow.
  * Only when `kycStatus == "approved"` grant access to dashboard, claims, redemptions, etc.

Backend can also enforce KYC by checking `req.user.kyc` inside middleware for specific routes.

---

## 8) Environment configuration

`.env`

```
DATABASE_URL=postgres://user:pass@host:5432/db
JWT_SECRET=replace-with-strong-secret
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n","client_email":"...","token_uri":"https://oauth2.googleapis.com/token"}
```

Rules:

* Entire JSON must be **one line**.
* `private_key` newlines are **escaped** as `\\n`.

---

## 9) Common pitfalls & fixes

* **“Cannot find module 'firebase-admin'”**
  Install it: `npm i firebase-admin` and ensure `dotenv.config()` runs before `import './src/firebase/admin'`.

* **JSON parse error in admin.ts**
  Your `.env` JSON is multiline or has quotes around it.
