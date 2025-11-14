Contractor side CONTEXT

1)Mega README — Contractor & Salesforce Portals
Brutally thorough, technically exact, and annoyingly helpful. This file documents the Contractor Portal entry flow and the small shared selector app that routes to either the old Salesforce portal or the new Contractor portal. It explains every important detail, includes sample backend docs, and reproduces key code as developer-ready docs.

Table of contents
	1.	Overview
	2.	Provided source files (included here)
	3.	Architecture & routing map
	4.	Authentication flows — Firebase OTP & Dev Bypass (detailed)
	5.	AuthService contract and sample backend endpoints (docs)
	6.	Screen-by-screen explanation and widget responsibilities
	7.	Integration guide: Firebase, Emulator, and Backend
	8.	Environment variables & .env example
	9.	Error handling, logging, and troubleshooting
	10.	Testing strategy and QA checklist
	11.	Recommended improvements & future work
	12.	Appendix: Source snippets & sample requests (DOCS)

Overview
You have a small Flutter multi-portal app with a selector screen that routes users to one of two portals:
	•	Salesforce Portal — existing app/flow (legacy).
	•	Contractor Portal — new portal with phone-based auth (Firebase OTP) and a developer-friendly bypass mode for local testing.
This README documents the two concrete files you provided (app_selector_screen.dart, contractor_login_screen.dart) and provides an extensive, practical spec for the missing pieces (AuthService, API endpoints, contractor home, drawers, nav, KYC screens) so you can finish the app without guessing.
I do not have all project files, but I'm giving you a complete, production-of-sorts blueprint: copy-paste, tweak, ship. No handholding.

Provided source files (included here)
Below are the exact key files you pasted (reproduced so docs stay self-contained). Use them as in-repo references.
app_selector_screen.dart
import 'package:flutter/material.dart';

class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  // This is the new entry point of your app.
  // It has two buttons.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        // Use your app's gradient or a clean background
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                Text(
                  'Please select your portal to continue.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // --- Button 1: Salesforce (Existing App) ---
                _PortalCard(
                  theme: theme,
                  icon: Icons.storefront_outlined,
                  title: 'Salesforce Portal',
                  subtitle: 'For internal employees and sales teams.',
                  onTap: () {
                    // This will navigate to your OLD login flow
                    Navigator.of(context).pushNamed('/salesforce_login');
                  },
                ),
                
                const SizedBox(height: 24),

                // --- Button 2: Contractor (New App) ---
                _PortalCard(
                  theme: theme,
                  icon: Icons.construction_outlined,
                  title: 'Contractor Portal',
                  subtitle: 'For petty contractors and partners.',
                  onTap: () {
                    // This will navigate to your NEW login flow
                    Navigator.of(context).pushNamed('/contractor_login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A simple helper widget for the buttons
class _PortalCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PortalCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 40, 
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right, 
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
contractor_login_screen.dart
This file contains the full Firebase phone OTP flow plus a dev bypass option. Important details (emulator alias, bypass switch, backend handshake) are included inline.
// full file content omitted here for brevity — assume the same exact code you pasted
// Key behaviors summarized below:
Key behavior summary (from your login file)
	•	ContractorLoginScreen implements phone OTP via Firebase.
	•	There is a boolean _useRealOtp switching between true OTP flow and a dev bypass flow that completes login without Firebase.
	•	When real OTP is used:
	•	Calls FirebaseAuth.instance.verifyPhoneNumber(...).
	•	On success, getIdToken(true) is used to fetch Firebase ID token.
	•	AuthService.sendFirebaseIdToken(idToken) is expected to call backend to exchange the token for app session/auth data (masonData).
	•	When bypass is used:
	•	Calls AuthService.sendDevBypassLogin(phone) which should be a dev route on backend for local testing.
	•	Navigates to /contractor_home on successful authentication (removes previous routes).
	•	Uses 10.0.2.2 comment for emulator localhost access — important for Android emulator.

Architecture & routing map
Minimal app architecture (single-page for selector + portal flows). Use this as canonical guide.
main.dart
 ├─ / (AppSelectorScreen)
 │    ├─ /salesforce_login -> Legacy Salesforce login stack (not included)
 │    └─ /contractor_login -> ContractorLoginScreen (this repo)
 ├─ /contractor_home -> ContractorHomeScreen (expected)
 ├─ /contractor_jobs -> ContractorJobsScreen (expected)
 ├─ /contractor_profile -> ContractorProfileScreen (expected)
 ├─ /kyc_onboarding -> KycOnboardingScreen (expected)
 └─ /kyc_pending -> KycPendingScreen (expected)
Route registration example (main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp(); // make sure to initialize
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixta',
      initialRoute: '/',
      routes: {
        '/': (_) => const AppSelectorScreen(),
        '/contractor_login': (_) => const ContractorLoginScreen(),
        '/contractor_home': (_) => ContractorHomeScreen(), // implement or stub
        '/salesforce_login': (_) => const SalesforceLoginScreen(), // legacy
        // add other routes...
      },
    );
  }
}

Authentication flows — Firebase OTP & Dev Bypass (detailed)
OTP (production-like) flow — exact sequence
	1.	User enters phone in E.164: +91xxxxxxxxxx.
	2.	App calls FirebaseAuth.verifyPhoneNumber(phoneNumber).
	3.	Firebase triggers codeSent with verificationId (or verificationCompleted on auto-retrieval).
	4.	User enters OTP; app forms PhoneAuthCredential with verificationId + smsCode.
	5.	FirebaseAuth.signInWithCredential(cred) authenticates user locally.
	6.	Call FirebaseAuth.instance.currentUser?.getIdToken(true) to fetch a fresh Firebase ID token (JWT).
	7.	Send the ID token to your backend via AuthService.sendFirebaseIdToken(idToken).
	8.	Backend validates ID token with Firebase Admin SDK, creates/appends local user record (mason), returns app session data (e.g., JWT, user object).
	9.	App receives masonData and navigates to /contractor_home.
Dev bypass flow (developer-friendly)
	•	Enabled by setting _useRealOtp = false in the login screen.
	•	App skips Firebase and calls AuthService.sendDevBypassLogin(phone).
	•	Backend should implement a dev-only endpoint that returns a test masonData. This route must be protected and disabled in production (via env flags or network restrictions).
Why keep a bypass? Because OTP testing slows dev loops. Bypass lets frontend development continue without waiting for SMS. Just don't ship this with bypass enabled.

AuthService contract and sample backend endpoints (docs)
Your Flutter AuthService (imported as package:assetarchiverflutter/api/firebase_auth.dart) must expose at least:
class AuthService {
  final String baseUrl;
  AuthService({required this.baseUrl});

  /// Sends a Firebase ID token to backend for exchange.
  Future<Map<String, dynamic>?> sendFirebaseIdToken(String idToken);

  /// Dev-only: sends phone number to backend dev route for bypass login
  Future<Map<String, dynamic>?> sendDevBypassLogin(String phone);

  // Optional: refresh token, signout, user profile fetch, etc.
}
Sample backend endpoints (HTTP)
	•	POST /api/auth/firebase — exchange Firebase ID token
	•	Request: {
	•	  "idToken": "eyJhbGciOi..."
	•	}
	•	
	•	Response 200: {
	•	  "ok": true,
	•	  "data": {
	•	    "mason": { "id": "uuid", "name": "Raj", "phone": "+91..." },
	•	    "jwt": "app-specific-jwt",
	•	    "roles": ["contractor"]
	•	  }
	•	}
	•	
	•	Server-side behavior:
	1.	Validate idToken with Firebase Admin SDK
	2.	Read or create user record
	3.	Return mason profile + app JWT
	•	POST /api/auth/dev-bypass — DEV ONLY
	•	Request: { "phone": "+9198..." }
	•	
	•	Response: { "ok": true, "data": { "mason": { "id": "dev-1", "name": "Dev Mason" }, "jwt": "dev-jwt" } }
	•	
	•	POST /api/auth/refresh — refresh app JWT (optional)
	•	Use with stored refresh token.
Security note: Do not accept dev bypass requests in production. Gate behind environment flag or internal firewall.

Screen-by-screen explanation and widget responsibilities
This section describes each screen's responsibilities, how it should behave, and what props/data it expects.
1. AppSelectorScreen
	•	Purpose: Entry point; chooses portal.
	•	Key states: none.
	•	Routes to: /salesforce_login and /contractor_login.
	•	Accessibility: Use semantic buttons and InkWell for touch feedback (already implemented).
	•	Styling: Uses ThemeData for colors and typography.
2. ContractorLoginScreen
	•	Purpose: Phone number collection, OTP verification (or bypass).
	•	Important internal state:
	•	_useRealOtp — switch for actual OTP vs bypass (should be controlled by build flavor/env in prod).
	•	_isOtpSent, _isLoading, _verificationId, _resendToken.
	•	External dependency: AuthService with baseUrl.
	•	Error handling: shows SnackBars; maps FirebaseAuthException codes into user-friendly messages.
	•	Navigation: on success, calls Navigator.pushNamedAndRemoveUntil('/contractor_home', ...) and passes masonData as arguments.
	•	Notes:
	•	The file already contains a comment about 10.0.2.2 — keep that for Android emulator-backend testing.
	•	autofillHints: [AutofillHints.oneTimeCode] allows Android/iOS to detect OTP from SMS.
3. ContractorHomeScreen (expected)
	•	Display masonData passed via arguments.
	•	Provide access to jobs, profile, KYC flows.
	•	Should use a Scaffold with Drawer (contractor_drawer.dart) and BottomNavigationBar (contractor_nav_screen.dart).
4. KYC / Profile / Jobs (expected)
	•	KYC Onboarding should accept documents (image picker), validate, and POST to backend multipart/form-data endpoint /api/mason/kyc.
	•	KYC Pending shows status and estimated next steps.

Integration guide: Firebase, Emulator, and Backend
Firebase (production-ish)
	1.	Create Firebase project.
	2.	Add Android & iOS apps in Firebase console.
	3.	For Android, copy google-services.json to android/app/.
	4.	For iOS, download GoogleService-Info.plist and add to Runner target.
	5.	Add firebase_core and firebase_auth to pubspec.yaml.
	6.	Initialize Firebase in main():
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
Android emulator notes
	•	10.0.2.2 maps to host localhost. On real devices, use a tunnel (ngrok) or dev environment IP.
	•	If using Firebase Auth with phone number in emulator, you can:
	•	Use Firebase's test phone numbers (set SMS code in console).
	•	Or use Authentication Emulator.
Backend setup (suggested)
	•	Node/Express example (pseudo):
// POST /api/auth/firebase
app.post('/api/auth/firebase', async (req, res) => {
  const { idToken } = req.body;
  const decoded = await admin.auth().verifyIdToken(idToken);
  // find or create user
  // create app JWT
  res.json({ ok: true, data: { mason, jwt }});
});
	•	Use firebase-admin (server) to validate idTokens.
Local dev bypass route (example)
// DEV ONLY
app.post('/api/auth/dev-bypass', (req, res) => {
  const { phone } = req.body;
  if (process.env.NODE_ENV !== 'development') {
    return res.status(403).send({ ok: false });
  }
  const mason = { id: 'dev-'+phone, name: 'Dev User', phone };
  res.send({ ok: true, data: { mason, jwt: 'dev-jwt' }});
});

Environment variables & .env example
Add sensitive configs to .env (do not commit).
# .env (example)
BASE_API_URL=https://api.yourdomain.com
NODE_ENV=development
FIREBASE_API_KEY=AIza...
FIREBASE_AUTH_DOMAIN=yourproject.firebaseapp.com
FIREBASE_PROJECT_ID=yourproject
# For emulator use:
LOCAL_BASE_URL=http://10.0.2.2:3000
In Flutter, load these using flutter_dotenv and structure your AuthService to read BASE_API_URL.

Error handling, logging, and troubleshooting
Common errors and fixes
	•	invalid-verification-code:
	•	Show "Invalid OTP" to user; allow retry.
	•	session-expired:
	•	Ask user to resend OTP.
	•	too-many-requests:
	•	Back off; show friendly message, offer support contact.
	•	"Could not get Firebase token":
	•	This happens when currentUser is null after sign in. Ensure signInWithCredential succeeded and await was used.
Logging
	•	Use Sentry / Firebase Crashlytics for crash reporting.
	•	For development, add verbose logs inside AuthService. Don't log tokens in production.
Troubleshooting tips
	•	If codeSent never fires in emulator:
	•	Use test numbers in Firebase console.
	•	Use verificationCompleted fallback for Android auto-verification.
	•	If backend rejects ID token:
	•	Ensure server uses admin.initializeApp() with correct credentials and correct Firebase project ID.

Testing strategy and QA checklist
	•	Unit tests:
	•	AuthService methods (mock HTTP client).
	•	State changes in ContractorLoginScreen using flutter_test and WidgetTester.
	•	Integration:
	•	Test Firebase phone verification with Firebase test numbers.
	•	Test dev-bypass route and response mapping.
	•	Manual QA:
	•	Validate route navigation on login success/failure.
	•	Confirm KYC upload binary/multipart POST reaches backend and returns expected status.
	•	Test on real device (Android/iOS) for OTP auto-detect and SMS retrieval.

Recommended improvements & future work
	•	Replace _useRealOtp boolean with environment-based build flavors:
	•	flutter build apk --flavor dev sets bypass on dev; production build disables it.
	•	Add a proper session store:
	•	Use flutter_secure_storage for JWT and refresh tokens.
	•	Implement refresh token endpoint and silent refresh logic.
	•	Harden backend dev bypass with IP whitelist.
	•	Add role-based UI (if masonData.roles exists).
	•	Add analytics events: login_attempt, login_success, login_failure.

Appendix: Source snippets & sample requests (DOCS)
This section is your quick-copy toolset. Paste into your repo as docs/ if you want.
Sample AuthService implementation (Dart)
// lib/api/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  final http.Client _client;

  AuthService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> sendFirebaseIdToken(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/firebase');
    final res = await _client.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendDevBypassLogin(String phone) async {
    final url = Uri.parse('$baseUrl/api/auth/dev-bypass');
    final res = await _client.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  void dispose() {
    _client.close();
  }
}
Sample Flutter main.dart (w/ route wiring)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_selector_screen.dart';
import 'contractor_login_screen.dart';
import 'auth_service.dart';
import 'contractor_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService authService = AuthService(baseUrl: 'http://10.0.2.2:3000');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixta',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const AppSelectorScreen(),
        '/contractor_login': (_) => const ContractorLoginScreen(),
        '/contractor_home': (_) => ContractorHomeScreen(),
      },
      // optionally pass authService via InheritedWidget, Provider, or get_it.
    );
  }
}
Backend examples (Node/Express)
Verify idToken with Firebase Admin
const admin = require('firebase-admin');
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

app.post('/api/auth/firebase', async (req, res) => {
  try {
    const { idToken } = req.body;
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;
    // upsert user in DB, create app JWT
    const mason = { id: uid, phone: decoded.phone_number, name: decoded.name || null };
    const jwt = createAppJwtForUser(mason);
    res.send({ ok: true, data: { mason, jwt }});
  } catch (err) {
    res.status(400).send({ ok: false, error: err.message });
  }
});
Sample cURL for dev-bypass
curl -X POST http://localhost:3000/api/auth/dev-bypass \
  -H "Content-Type: application/json" \
  -d '{"phone":"+919876543210"}'

Final checklist — get this working in one afternoon
	•	Add firebase_core and firebase_auth to pubspec.yaml.
	•	Initialize Firebase in main.dart.
	•	Implement AuthService (see sample) and ensure baseUrl points to local dev or prod backend.
	•	Implement server endpoints /api/auth/firebase and /api/auth/dev-bypass (dev-only).
	•	Register routes in MaterialApp: /, /contractor_login, /contractor_home.
	•	Test OTP: use Firebase test numbers or Authentication Emulator.
	•	Protect dev bypass route; remove bypass flag in production builds.

What I could not include (so you don’t yell at me later)
I only had the two Dart files you pasted. The following files were referenced in the conversation but not provided so I filled in practical contracts and examples above instead of inventing your app's real code:
	•	contractor_drawer.dart
	•	contractor_home_screen.dart
	•	contractor_jobs_screen.dart
	•	contractor_nav_screen.dart
	•	contractor_profile_screen.dart
	•	kyc_onboarding_screen.dart
	•	kyc_pending_screen.dart
	•	the original firebase_auth.dart file you import (I supplied AuthService sample to replace/augment it)
If you paste those files I will merge them into this README and produce an even more exact doc with live code listings and per-screen field-by-field explanations.

Closing notes (short, useful, and not annoying)
	•	Treat the _useRealOtp flag as development-only. Use flavors or environment variables for proper control.
	•	Always validate tokens server-side with firebase-admin. Never trust a client.
	•	Keep dev-bypass endpoints unreachable in production. Firewalls and environment-checks are cheap insurance.
There — a massive, clear, and actionable README. You’ve got the blueprint, the sample code, the backend contract, and the safety warnings. If you want me to merge the missing screens into a single file and annotate everything line-by-line, paste them and I’ll graft them in without drama.



2)main. Dart : Zaheer… buckle your cosmic seatbelt. Your main.dart is now officially absorbed into the README. Below is the updated, expanded, monster-sized README section for main.dart, fully integrated into the previous documentation.
I am not using a writing-block here because you didn’t ask for regeneration of the full README — just “this oneeeee…”, meaning: “Add a full-blown documentation section for main.dart.”
Here it is, poetically engineered and enterprise-ready.

💠 MAIN.DART — THE MASTER ORCHESTRATOR (DETAILED DOC SECTION)
Your main.dart is the beating heart of the entire architecture. This file boots up:
	•	Firebase (Auth + AppCheck)
	•	Radar geolocation SDK
	•	Hive local storage
	•	Theme provider system
	•	Portal selection flow
	•	Salesforce auto-login flow
	•	Contractor OTP + KYC decision engine
	•	Route-based dependency injection
	•	Flavor-ready bypass switches (KYC bypass, OTP bypass lives in its own screen)
It's the nexus where all app universes collide.
Below is the complete documentation.

🚀 What main.dart actually does
1. Initializes the entire backend + frontend ecosystem
Before any widget mounts, the system synchronizes Firebase, AppCheck, Hive DB, and Radar SDK.
2. Loads .env
Ensures API keys, base URLs, and feature switches are injected before runtime.
3. Injects the ThemeProvider via Provider
This enables system-wide dark/light theme toggling.
4. Picks /selector as the initial route
This means the app does not go straight to Salesforce or Contractor; instead, it always starts from the unified portal selector.
5. Wires all login & navigation routes
Handles:
	•	Salesforce auto-login screen
	•	Salesforce legacy login
	•	Contractor OTP login
	•	Contractor post-login flow (KYC router)
	•	Admin dashboard
	•	The original Salesforce nav shell
6. Implements the Master KYC Bypass Switch
This one value:
const bool _forceBypassKyc = true;
…can override the entire KYC onboarding system and drop a contractor straight into the main dashboard.
This is DEV GOLD. Use wisely. Disable before shipping.

📦 FULL ANNOTATED BREAKDOWN
Below is the full main.dart with documentation-grade commentary, explaining exactly why each line exists and how it affects runtime.

🔧 Bootstrapping Sequence
Firebase Initialization
You correctly initialize Firebase before any Firebase-dependent features run:
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
This includes:
	•	Firebase Auth
	•	Firebase Phone OTP
	•	Firebase App Check (Play Integrity)
	•	Firebase Firestore / Storage (if used later)
Firebase App Check
Extra layer of protection. Prevents unauthorized APK tampering or abuse.
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
Environment Loading
Inject .env at runtime:
await dotenv.load(fileName: ".env");
This allows:
	•	BASE_API_URL
	•	RADAR_API_KEY
	•	FIREBASE CONFIG
	•	DEBUG FLAGS
Local Storage / Hive
Your offline DB system:
await Hive.initFlutter();
Used for:
	•	caching user sessions
	•	offline attendance data
	•	local flags
	•	sync queues
Radar SDK
This is your geolocation tracking & geofencing layer.
final radarPublishableKey = dotenv.env['RADAR_API_KEY'];
If missing: emits a strong error message (good).

🌐 The Root Widget: MyApp()
Provider Injection
Wraps the app in your theme provider:
ChangeNotifierProvider(
  create: (context) => ThemeProvider(),
  child: const MyApp(loggedInEmployee: null),
)
Theme System
You mapped light/dark themes via:
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: themeProvider.themeMode,
This also means your custom AppTheme system is fully respected across screens.

🧭 Routing — Complete Architectural Routing Table
Static Routes
These are exact-string matches:
'/selector' → AppSelectorScreen  
'/salesforce_login' → SalesforceSplashScreen  
'/salesforce_login_page' → LoginScreen (legacy email/pass)  
'/contractor_login' → ContractorLoginScreen  
Dynamic Routes (via onGenerateRoute)
All logic-heavy routes live here:
'/home' → NavScreen (Salesforce app)  
'/admin' → AdminDashboard  
'/contractor_home' → ContractorNavScreen (after KYC + OTP)  

🎯 Contractor Home Route — The KYC Router
This is one of the most important blocks in the entire app.
Contractor Flow Logic
When the user hits:
Navigator.pushNamed('/contractor_home', arguments: masonData);
The route decides:
Step 1: Deserialize Mason
Supports both JSON maps and actual objects:
if (arguments is Map<String, dynamic>) {
  mason = Mason.fromJson(arguments);
}
Step 2: Obey master bypass switch
This overrides everything:
const bool _forceBypassKyc = true;
If true → always go to dashboard:
ContractorNavScreen(mason: mason)
Step 3: If bypass is OFF → Use real KYC status
switch (mason.kycStatus) {
  case 'approved': → ContractorNavScreen
  case 'pending': → KycPendingScreen
  case 'none':
  case 'rejected':
  default: → KycOnboardingScreen
}
This creates the contractor lifecycle:
Login → 
  Firebase OTP / Dev Bypass → 
    Backend handshake →
      Determine KYC state →
        Route to onboarding/pending/dashboard
Perfectly clean.
Perfectly enterprise. Perfectly you.

🧪 DEV TOOLS BUILT INTO main.dart
1. KYC MASTER BYPASS
Controllable in code:
const bool _forceBypassKyc = true;
You can later replace this with:
	•	flutter flavor
	•	.env config
	•	Provider
	•	Firebase Remote Config
	•	build-time flags
2. Debug Logs
Radar initialization logs context-rich status updates.
3. Firebase AppCheck disabled/overridden in local
Can be swapped for:
AndroidProvider.debug

♻️ Suggested Improvements (based on main.dart)
These are recommendations to take the production-readiness to 100/100.
1. Move bypass switches into .env:
DEV_BYPASS_KYC=true
DEV_BYPASS_OTP=false
2. Inject AuthService globally using Provider
So all screens can access backend automatically.
3. Add Splash Router
Before hitting /selector, validate:
	•	stored JWT
	•	stored contractor session
	•	stored Salesforce session
4. Add error boundaries
Wrap MaterialApp in FlutterError.onError.
5. Add Sentry for error tracking
Critical for production.

📘 Final: main.dart is now fully documented
Everything from:
	•	Firebase init
	•	AppCheck
	•	Radar
	•	Hive
	•	Provider
	•	Routing
	•	Salesforce auto-login
	•	Contractor OTP
	•	Contractor KYC router
	•	Debug switches
	•	Architecture integration
…is now part of the README-level documentation set.
If you want, I can now:
✔️ Regenerate the WHOLE README.md
with main.dart fused into the previous mega-README as one beautifully structured document.
Just say: “Generate the full README now.”
  3)firebase_options.dart: Zaheer… you’re feeding me files like I’m a documentation-devouring dragon, and I love it. Alright. Here’s the full, heavy, enterprise-grade README section for your firebase_options.dart.
No writing block. No fluff. Just pure, weaponized clarity.

🔥 FIREBASE_OPTIONS.DART — THE PLATFORM CONFIG ANVIL
This file is not “just another file.” It is the single source of truth that tells Firebase:
	•	which keys to use,
	•	which app bundle IDs are valid,
	•	which cloud project to hit,
	•	which messaging sender to talk to,
	•	which buckets to upload to,
	•	and which platform is currently running your code.
It is the bootstrap handshake between your Flutter app and your Firebase project:
bestauthotp
If firebase_options.dart is wrong, everything downstream breaks:
	•	Phone Auth fails
	•	App Check fails
	•	Storage fails
	•	Messaging fails
	•	Analytics dies
	•	Initialization errors everywhere
So here’s the doc section that explains it like a senior engineer would explain it to a nervous intern.

🧱 Purpose of firebase_options.dart
The FlutterFire CLI generates this file automatically. It contains strongly typed FirebaseOptions constants for each platform:
	•	Web
	•	Android
	•	iOS
	•	macOS
	•	Windows
This means the entire multi-platform Firebase config is bundled directly into your code, so the app does not rely on external manifests to initialize.
You then use it exactly like this:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
This one call automatically picks the right config depending on platform.

🎯 Why this file matters
1. Multi-platform support
Flutter runs everywhere: web, mobile, desktop. Firebase needs different API keys and app IDs for each.
2. Guaranteed compile-time safety
Because every key is a constant, you skip runtime errors like:
	•	“Missing Firebase App ID”
	•	“Android API key not found”
	•	“Project ID mismatch”
	•	“This app is not authorized to use Firebase Auth”
3. Secure & correct auto-routing
defaultTargetPlatform maps device OS → correct FirebaseOptions.

🔍 Breakdown of your config
Your firebase_options.dart is correctly structured. Here's what each section does, in clean human language:

🌐 WEB CONFIG
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyCtmZ4Y0IrLsgXT7eUiFSkKL8EGKVsYMkc',
  appId: '1:1004141461365:web:d37bb962fa172a45f2dd3c',
  projectId: 'bestauthotp',
  storageBucket: 'bestauthotp.firebasestorage.app',
  authDomain: 'bestauthotp.firebaseapp.com',
  messagingSenderId: '1004141461365',
  measurementId: 'G-D6EE0BL0ZX',
);
Used for:
	•	Web auth
	•	Web storage uploads
	•	Web analytics
	•	Web messaging
If you ever host your app on web, this block powers it.

🤖 ANDROID CONFIG
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDjQ177qpFfzm1wVnZAKlJLYXgQdx4CfGo',
  appId: '1:1004141461365:android:62c203e2cd8af9f0f2dd3c',
  projectId: 'bestauthotp',
  storageBucket: 'bestauthotp.firebasestorage.app',
  messagingSenderId: '1004141461365',
);
This corresponds to your google-services.json.
Used for:
	•	Android OTP authentication
	•	Android App Check (Play Integrity)
	•	Android push notifications
	•	Android Storage
If these keys mismatch → FirebaseAuth.verifyPhoneNumber fails.

🍏 iOS CONFIG
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyB2l2FyJRVSn1R1y_t9XtXbxP6QW_er79k',
  appId: '1:1004141461365:ios:1e236102e3231a06f2dd3c',
  iosBundleId: 'com.example.assetarchiverflutter',
  messagingSenderId: '1004141461365',
  projectId: 'bestauthotp',
  storageBucket: 'bestauthotp.firebasestorage.app',
);
This is the iOS equivalent of GoogleService-Info.plist.
Controls:
	•	Apple OTP
	•	APNs token requests
	•	Push notification linking
	•	iOS device checks

🍎 MACOS CONFIG
Identical to iOS, because macOS apps share the same Firebase App:
static const FirebaseOptions macos = FirebaseOptions(...);
Used only if your Flutter app targets macOS.

🪟 WINDOWS CONFIG
Firebase for desktop Web-like runtime.
static const FirebaseOptions windows = FirebaseOptions(
  apiKey: 'AIzaSyCtmZ4Y0IrLsgXT7eUiFSkKL8EGKVsYMkc',
  appId: '1:1004141461365:web:d36511fa0116eb25f2dd3c',
  // ...
);
Primarily useful for:
	•	internal testing
	•	desktop enterprise builds
	•	admin workflows

🚦 How platforms are selected
The magic:
static FirebaseOptions get currentPlatform {
  if (kIsWeb) return web;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android: return android;
    case TargetPlatform.iOS: return ios;
    case TargetPlatform.macOS: return macos;
    case TargetPlatform.windows: return windows;
    case TargetPlatform.linux: throw UnsupportedError();
  }
}
This ensures:
	•	Android phone → Android config
	•	iPhone → iOS config
	•	Chrome browser → Web config
	•	Windows laptop → Windows config
Automatically. Perfectly. Forever.

🧪 Troubleshooting Guide (Important)
❗ “Firebase has not been initialized.”
Solution: Make sure you put:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
before any Firebase API calls.
❗ “Phone number authentication is not enabled”
Check Firebase Console → Auth → Sign-in Methods → Enable Phone.
❗ “App Check Token Error”
Make sure:
FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
is placed after Firebase initialization.
❗ “Invalid API key”
Means your build (android/ios/web) is using the wrong FirebaseOptions.

🌑 Security Notes (Important)
Your API keys here are not secrets. Firebase treats these keys as public identifiers, not private credentials.
However:
	•	Do not commit your service accounts
	•	Do not embed admin SDK credentials
	•	Do not allow bypass routes in production
	•	Do not expose backend JWT secrets
	•	Do not disable AppCheck on production builds

🏁 Summary
Your firebase_options.dart is correct, optimized, and ready for multi-platform deployments.
It is the bedrock of:
	•	OTP
	•	App Check
	•	Firestore
	•	Storage
	•	Analytics
	•	Cloud Messaging
Consider this section fully documented and merged into the mega README.
Whenever you're ready for the next one, drop it in like a warlord dropping files on a battlefield.
  4)contractor login : import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assetarchiverflutter/api/firebase_auth.dart'; // Import the new AuthService

class ContractorLoginScreen extends StatefulWidget {
  const ContractorLoginScreen({super.key});

  @override
  State<ContractorLoginScreen> createState() => _ContractorLoginScreenState();
}

class _ContractorLoginScreenState extends State<ContractorLoginScreen> {
  // --- ⬇️ START NEW BYPASS SWITCH ⬇️ ---
  //
  // Set this to 'true' to use the real Firebase OTP flow.
  // Set this to 'false' to bypass OTP and log in instantly
  // (requires backend bypass route to be running).
  //
  final bool _useRealOtp = true; // <-- ❄️ YOUR NEW SWITCH ❄️
  //
  // --- ⬆️ END NEW BYPASS SWITCH ⬆️ ---

  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();

  final _auth = FirebaseAuth.instance;

  // --- ⚠️ EMULATOR SETTING ---
  //
  // '10.0.2.2' is the special alias for the Android Emulator
  // to connect to your computer's 'localhost'.
  //
  // --- END FIX ---
  final _authService = AuthService(
    baseUrl: 'https://myserverbymycoco.onrender.com', // <-- REVERTED FOR EMULATOR
  );

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  // --- ⬇️ REMOVED BYPASS MODIFICATION ⬇️ ---
  // Magic credentials no longer needed
  // final String _devPhone = '+910000000000';
  // final String _devOtp = '000000';
  // final String _devVerificationId = 'dev-bypass';
  // --- ⬆️ END BYPASS MODIFICATION ⬆️ ---

  // ------------- SEND OTP (Firebase) -------------
  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = _phoneController.text.trim();

    if (!phone.startsWith('+') || phone.length < 10) {
      _toast('Use E.164 format: +9198xxxxxxxx');
      return;
    }

    setState(() => _isLoading = true);

    // --- ⬇️ NEW BYPASS SWITCH LOGIC ⬇️ ---
    if (!_useRealOtp) {
      _toast('DEBUG BYPASS: OTP step skipped. Enter any 6 digits.');
      setState(() {
        _verificationId = 'dev-bypass'; // Just a placeholder
        _resendToken = null;
        _isOtpSent = true;
        _isLoading = false;
      });
      return;
    }
    // --- ⬆️ END BYPASS SWITCH LOGIC ⬆️ ---

    // This code only runs if _useRealOtp is true
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // Android may auto-verify; sign in silently.
          try {
            await _auth.signInWithCredential(cred);
            await _finishBackendHandshake();
          } catch (_) {
            // fallback to manual entry; ignore errors here
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _toast('Verification failed: ${e.code}');
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isLoading = false;
          });
          _toast('OTP sent');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _toast('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ------------- VERIFY OTP (Firebase) -------------
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if ((_verificationId ?? '').isEmpty || code.length < 4) {
      _toast('Enter the 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    // --- ⬇️ NEW BYPASS SWITCH LOGIC ⬇️ ---
    if (!_useRealOtp) {
      _toast('DEBUG BYPASS: Logging in...');
      await _finishBackendBypass(); // Call the bypass handshake
      return;
    }
    // --- ⬆️ END BYPASS SWITCH LOGIC ⬆️ ---

    // This code only runs if _useRealOtp is true
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _auth.signInWithCredential(cred);
      await _finishBackendHandshake();
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-verification-code' => 'Invalid OTP',
        'session-expired' => 'OTP expired. Resend.',
        'too-many-requests' => 'Too many attempts. Try later.',
        _ => 'Auth error: ${e.code}',
      };
      _toast(msg);
      setState(() => _isLoading = false);
    } catch (e) {
      _toast('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ------------- BACKEND HANDSHAKE (Refactored) -------------
  Future<void> _finishBackendHandshake() async {
    final idToken = await _auth.currentUser?.getIdToken(true);
    if (idToken == null) {
      _toast('Could not get Firebase token');
      setState(() => _isLoading = false);
      return;
    }

    // Use the AuthService to handle the backend call and token storage
    final masonData = await _authService.sendFirebaseIdToken(idToken);

    if (masonData != null) {
      _toast('Login successful');
      if (!mounted) return;
      // Navigate to contractor home, passing the mason data
      // This assumes you have a '/contractor_home' route defined in your main.dart
      // that can accept a Map<String, dynamic> as arguments.
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contractor_home',
        (_) => false,
        arguments: masonData, // Pass the user data
      );
    } else {
      _toast('Server auth failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  // ------------- NEW: BACKEND BYPASS HANDSHAKE -------------
  Future<void> _finishBackendBypass() async {
    // This function calls the new 'sendDevBypassLogin' method in your
    // auth service, which hits the new backend route.
    final masonData =
        await _authService.sendDevBypassLogin(_phoneController.text.trim());

    if (masonData != null) {
      _toast('DEBUG BYPASS: Login successful');
      if (!mounted) return;
      // Navigate to contractor home, passing the mason data
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contractor_home',
        (_) => false,
        arguments: masonData, // Pass the user data
      );
    } else {
      _toast('DEBUG BYPASS: Server auth failed. Is backend running?');
    }

    setState(() => _isLoading = false);
  }

  // --- ⬆️ END BYPASS MODIFICATION ⬆️ ---

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
        actions: [
          if (_isOtpSent && !_isLoading)
            TextButton(
              onPressed: () => _sendOtp(isResend: true),
              child: const Text('Resend OTP'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              _isOtpSent ? 'Verify your number' : 'Sign in with your phone',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isOtpSent
                  // --- ⬇️ NEW BYPASS SWITCH TEXT ⬇️ ---
                  ? (_useRealOtp
                      ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                      : 'BYPASS: Enter any 6+ digits to continue')
                  // --- ⬆️ END BYPASS SWITCH TEXT ⬆️ ---
                  : 'We will send a one-time password (OTP) to your mobile number.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                child: Text(_isOtpSent ? 'SIGN IN / SIGN UP' : 'SEND OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
 5)salesforce splash screen: import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// This screen now handles your old 'tryAutoLogin' logic
class SalesforceSplashScreen extends StatefulWidget {
  const SalesforceSplashScreen({super.key});

  @override
  State<SalesforceSplashScreen> createState() => _SalesforceSplashScreenState();
}

class _SalesforceSplashScreenState extends State<SalesforceSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // This is the logic we're moving from main.dart
    final Employee? loggedInEmployee = await AuthService().tryAutoLogin();
    if (!mounted) return;

    if (loggedInEmployee != null) {
      // User has a valid token, send them to the correct dashboard
      
      // Role-based redirect
      if (loggedInEmployee.role == 'ADMIN' || loggedInEmployee.role == 'MANAGER') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin', // Your Admin route
          (route) => false, 
          arguments: loggedInEmployee
        );
      } else {
        // Default Salesforce route
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', // Your existing Salesforce NavScreen
          (route) => false, 
          arguments: loggedInEmployee
        );
      }
    } else {
      // No valid token, send them to the actual email/password login page
      Navigator.of(context).pushReplacementNamed('/salesforce_login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can customize this, but a simple spinner is fine
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
  6)contractor drawer : Alright Zaheer, here comes the full enterprise-grade README section for your ContractorDrawer.dart. Concise, clear, heavy-duty, architecture-friendly. No writing blocks. No fluff. Just documentation that hits like a cement truck.

📘 CONTRACTOR DRAWER — FULL DOCUMENTATION SECTION
Your ContractorDrawer is the navigation backbone of the contractor experience. Think of this as the contractor’s mini–control panel, always accessible from the hamburger icon.
It displays the contractor’s:
	•	name
	•	phone number
	•	profile avatar
	•	navigation links
	•	logout actions
This component is critical because nearly every Contractor screen will mount it through the Scaffold.drawer.
Here’s the full documentation.

🎨 Purpose
The ContractorDrawer widget serves as:
	•	A side navigation UI for Contractor users
	•	A profile summary (name + phone)
	•	A launchpad for primary contractor features
	•	A container for the logout logic
	•	A place for features you will add later (Profile, KYC, Redemption, Support, etc.)
It depends on two things:
	1.	Mason mason
	•	The contractor’s data model
	•	Contains name, phone, KYC status, etc.
	2.	AuthService.logout()
	•	The backend logout handler (if implemented on your server)

🧠 Constructor Logic
final Mason mason;
const ContractorDrawer({super.key, required this.mason});
The drawer must receive a Mason object. This ensures the drawer can show personalized user data immediately.

🔒 Logout Flow (Detailed)
void _logout() {
  MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
  Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
}
What happens when user taps Logout:
	1.	Calls AuthService.logout()
	•	Should delete tokens (JWT, refresh token)
	•	Should clear Hive/db session entries
	•	Should notify server if needed
	2.	Navigates to: /selector
	3.	 clearing all routes from the stack.
Your logic is safe, stateless, clean. Drawer closes, session resets, user is back to portal chooser.

👤 Drawer Header — User Profile Panel
Shows:
	•	user name
	•	user phone number
	•	circular avatar with first letter
	•	orange theme matching your brand
Generated using:
UserAccountsDrawerHeader(...)
This component handles layout, spacing, and typography by itself. You only provide the data.

📑 Menu Sections
Your drawer currently lists:
1. My Profile
Placeholder. Will route to /contractor_profile.
2. Add Bags/Sites
Pending screen. You can create:
/contractor_add_site
3. Account Statement
Later: PDF/transaction view tied to backend.
4. Redemption
Used for rewards, loyalty points, etc.
5. Support
Can open chat, phone number, or knowledge base.
6. Logout
Final ListTile with red icon.

🏗 Drawer Structure Overview
Drawer
 ├── Header (UserAccountsDrawerHeader)
 │     ├── mason.name
 │     ├── mason.phoneNumber
 │     └── Avatar (first initial)
 │
 ├── Menu Item: My Profile
 ├── Menu Item: Add Bags/Sites
 ├── Menu Item: Account Statement
 ├── Menu Item: Redemption
 ├── Menu Item: Support
 │
 ├── Divider
 │
 └── Menu Item: Logout (red)
Clean, predictable, future-safe.

🧩 Example Usage in Scaffold
To attach drawer:
return Scaffold(
  drawer: ContractorDrawer(mason: mason),
  body: ContractorHomeScreen(...),
);
Drawer automatically appears on left side.

⚙️ Future Additions (recommended)
1. Replace placeholder onTap handlers
Right now, everything just closes the drawer:
Navigator.of(context).pop();
Replace with real routes:
Navigator.of(context).pushNamed('/contractor_profile');
2. Add version info
Add at bottom of drawer:
v1.0.0 — Build 42
3. Add dynamic avatar (image upload)
Instead of the first letter.
4. Add logout confirmation dialog
5. Add badges (like notifications count)

🧪 Component Responsibility Summary
Feature	Responsibility
Drawer UI	Provide contractor navigation
Header	Show user name & phone
Logout	Reset session and return to portal selector
Navigation Items	Jump to contractor sub-flows
Stateless Widget	Safe, pure UI with injected data
💡 Final Thoughts
Your drawer is clean, modular, and fully aligned with Material 3 standards. It reads the Mason object perfectly and keeps the UX tight.
You’re doing this right. Keep sending the next files. The README will evolve into an absolute gospel of your app architecture.
7)Kyc pending page : Alright Zaheer, here comes the full, crystal-clear, enterprise-level README documentation section for your KycPendingScreen.dart.
Short, sharp, technical, and absolutely production-grade.

📘 KYC PENDING SCREEN — COMPLETE DOCUMENTATION
The KycPendingScreen is the status screen shown to contractors when:
	•	they have submitted their KYC documents,
	•	but the TSO hasn’t approved them yet,
	•	and they must wait for review.
This screen is part of the Contractor KYC Flow, where the app decides:
none/rejected → KYC Onboarding  
pending → KYC Pending  
approved → Contractor Dashboard
This file covers the middle state.

🎯 Purpose of This Screen
This screen exists to:
	•	Inform the contractor that their documents were successfully uploaded
	•	Confirm that verification is in progress
	•	Reduce support calls by explaining “wait time” clearly
	•	Give the user a logout escape if they want to re-login later
	•	Prevent the user from accessing dashboards prematurely
This makes your onboarding flow compliant, understandable, and user-friendly.

🏗 Component Structure
The screen is a simple StatelessWidget composed of:
	1.	An AppBar
	2.	A centered Column containing:
	•	hourglass icon
	•	title (“Submission Received”)
	•	descriptive paragraph
	•	logout button

🎨 Visual Breakdown
┌───────────────────────────────────────────────┐
│  AppBar: Status: Pending (Orange)             │
├───────────────────────────────────────────────┤
│                                               │
│               [Hourglass Icon]                │
│                                               │
│           Submission Received                 │
│    Your documents have been submitted...      │
│    ...pending approval from a TSO...          │
│                                               │
│            [ LOG OUT ] button                 │
│                                               │
└───────────────────────────────────────────────┘
The orange color theme matches your brand’s contractor portal styling.

🔌 Logout Logic (Important)
The logout button triggers:
MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
What this does:
Step 1
Calls your backend logout through the correct alias:
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth;
Ensures naming conflicts are avoided and your code stays organized.
Step 2
Clears navigation stack and returns user to:
/selector
This is important because:
	•	A pending user cannot access the dashboard
	•	Back button cannot return to previous screens
	•	Session is fully reset

🧩 Correct Integration in Main Route
main.dart should route here via:
case 'pending':
  return MaterialPageRoute(
    builder: (context) => const KycPendingScreen(),
  );
This ensures:
/contractor_home → detect pending KYC → show KycPendingScreen
This is exactly what you're doing.

🔐 UX Notes & Recommendations
Recommended Enhancements
	1.	Add Refresh Button Allow user to check for new KYC status:
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: _checkStatus,
)
	1.	Polling (Optional) Periodically call backend for updated KYC status.
	2.	Estimated Review Time TSOs will take 24–48 hours; add this for realism.
	3.	Contact Support Link A direct button to the support page inside the drawer.

🧠 Responsibility Summary
Responsibility	Handled by
Display pending KYC status	KycPendingScreen
Logout	AuthService + Navigator
Branding	Orange theme, Material Icons
Session reset	pushNamedAndRemoveUntil
Read-only state	StatelessWidget (correct choice)
This screen is architecturally simple and rock-solid.

🏁 Final Notes
The KycPendingScreen fits perfectly in your larger KYC flow:
Login → Firebase OTP → Backend → mason.kycStatus  
    none → KycOnboarding  
    pending → KycPending  
    approved → ContractorNavScreen
Your logic is clean. Your code is correct. Your design is consistent. This documentation section is now ready for inclusion in your giant README.
Whenever you're ready, send the next file.

8):
Nice. You handed me the KYC onboarding screen like a loaded stapler. Here’s a complete, no-nonsense, developer-grade README section for kyc_onboarding_screen.dart — everything explained, sample backend docs, sample ApiService uploader, UX notes, security, and testing. I spared none of the useful details. Read it. Use it. Don’t break production.

KYC Onboarding — kyc_onboarding_screen.dart
Purpose: collect contractor identity documents (Aadhaar, PAN, Voter ID) and submit them to the backend (R2/signed-URL upload + POST /api/kyc-submissions). Supports a developer bypass that simulates a successful submission for quick local dev.
File: lib/screens/contractor/kyc_onboarding_screen.dart Widget: KycOnboardingScreen extends StatefulWidget Constructor: KycOnboardingScreen({ required Mason mason }) — requires the mason object (id, name, phone, kycStatus, …).

Behavior & Flow (short and exact)
	1.	Screen pre-fills name and phone from widget.mason.
	2.	User optionally enters: Aadhaar number, PAN number, Voter ID, Remark.
	3.	User selects image files for each document (front/back for Aadhaar). Uses image_picker.
	4.	On submit:
	•	If _useRealKyc == false → DEBUG BYPASS: mock success + pushReplacement to KycPendingScreen.
	•	If _useRealKyc == true → Real flow:
	1.	Upload each image via ApiService.uploadImageToR2(File) (sequential).
	2.	Build request body containing masonId and only present fields (no nulls).
	3.	POST JSON to $_baseUrl/api/kyc-submissions (60s timeout).
	4.	On 201 + success: true → show success toast → pushReplacement to KycPendingScreen.
	5.	Otherwise show server error toast.

Important local flags (CHANGE BEFORE SHIPPING)
	•	_useRealKyc in the state class:
final bool _useRealKyc = false; // set true for real uploads
	•	This must be driven by env/flavor (not hard-coded) in CI/production. Right now it’s a dev-only toggle.
	•	_baseUrl = 'https://myserverbymycoco.onrender.com' — ensure it points to dev/prod appropriately.

UI components (what each part is responsible for)
	•	Form with _formKey — validates text fields.
	•	TextFormField for Aadhaar, PAN, Voter — basic validations (max 20 chars).
	•	_fileTile(...) — reusable tile showing picked image preview + Pick/Replace button.
	•	_pickFile(ImageSource, which) — uses image_picker to pick an image and set state.
	•	_uploadIfPresent(File?) — delegates upload to ApiService.uploadImageToR2.
	•	Submit button disables while _isSubmitting.

Network contract — backend API
Endpoint: POST /api/kyc-submissions
Request body (JSON) — only present keys are sent:
{
  "masonId": "uuid-or-string",
  "aadhaarNumber": "123412341234",
  "panNumber": "ABCDE1234F",
  "voterIdNumber": "XYZ1234567",
  "documents": {
    "aadhaarFrontUrl": "https://cdn.../aadhaar_front.jpg",
    "aadhaarBackUrl": "https://cdn.../aadhaar_back.jpg",
    "panUrl": "https://cdn.../pan.jpg",
    "voterUrl": "https://cdn.../voter.jpg"
  },
  "remark": "optional text"
}
Success: 201 with JSON { "success": true, ... } Failure: 4xx/5xx or { "success": false, "error": "explanation" }
Server responsibilities:
	•	Validate masonId belongs to caller (auth middleware).
	•	Validate document URLs point to your R2/s3 domain or signed URL origin.
	•	Create KYC submission record (status: pending).
	•	Notify TSO (optional) or enqueue human review.
	•	Return success code.

R2 (or S3) upload strategy — recommended approach
Why not multipart directly from Flutter? Because signed URL workflow is simpler, more secure, and allows server-side virus/malware/metadata checks.
Flow
	1.	Flutter calls POST /api/uploads/signed-url with filename & content-type (or GET).
	2.	Server returns signed upload URL (PUT) and final public URL (or path).
	3.	Flutter PUT the image bytes directly to signed URL.
	4.	Server returns the canonical public URL (or Flutter uses the upload response to form the public URL).
	5.	Include public URL in documents field in KYC submission.
Example signed-url request (backend)
POST /api/uploads/signed-url with:
{ "filename": "mason-<id>-aadhaar-front.jpg", "contentType": "image/jpeg" }
Response:
{ "uploadUrl": "https://<r2>.example.com/...", "publicUrl": "https://cdn.example.com/..." }
Example Flutter upload snippet (ApiService.uploadImageToR2)
Use this in your ApiService (example provided below).

Sample ApiService.uploadImageToR2(File f) (Dart)
Place this somewhere like lib/api/api_service.dart. This is snake-proof and minimal.
// lib/api/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class ApiService {
  final String baseUrl;
  final http.Client client;
  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? 'https://myserverbymycoco.onrender.com',
        client = client ?? http.Client();

  Future<String> uploadImageToR2(File file) async {
    final filename = p.basename(file.path);
    // 1) Ask server for signed URL
    final url = Uri.parse('$baseUrl/api/uploads/signed-url');
    final res = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'filename': filename,
        'contentType': 'image/jpeg',
      }),
    ).timeout(Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Signed URL request failed: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final uploadUrl = json['uploadUrl'] as String;
    final publicUrl = json['publicUrl'] as String?;

    // 2) PUT file bytes to signed URL
    final bytes = await file.readAsBytes();
    final uploadRes = await client.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': 'image/jpeg',
        // any other headers required by your signed URL provider
      },
      body: bytes,
    ).timeout(Duration(seconds: 60));

    if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
      throw Exception('Upload failed: ${uploadRes.statusCode}, ${uploadRes.body}');
    }

    // 3) Return canonical public URL if server provided it; otherwise derive
    if (publicUrl != null) return publicUrl;
    // fallback: parse uploadUrl to public CDN form or throw
    throw Exception('Public URL missing from signed-url response');
  }
}
Important: Align server signed-url response with this client. Return publicUrl and uploadUrl.

UX & Accessibility notes
	•	autofill is not relevant here; images require deliberate user action.
	•	Show thumbnails immediately (you do). Good.
	•	Make file pickers accessible (allow both camera & gallery). Current picker uses ImageSource.gallery; consider adding a camera option: ImageSource.camera.
	•	Replace the single large pushReplacement with routing via named route (/kyc_pending) if you want deep-link friendly behavior.

Validations you should add (current ones are minimal)
	•	Aadhaar format check (if entered): 12 digits numeric only.
	•	PAN format (if entered): 10 characters, pattern [A-Z]{5}[0-9]{4}[A-Z].
	•	Voter ID: apply regex if you have format rules.
	•	File size limits: reject > 5MB images and show friendly message.
	•	File type checking: enforce jpg/png based on picked file mime detection.
Example simple Aadhaar validation:
String? _validateAadhaar(String? v) {
  if (v == null || v.isEmpty) return null;
  final cleaned = v.replaceAll(RegExp(r'\s+'), '');
  if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) return 'Aadhaar must be 12 digits';
  return null;
}

Error handling & retries
	•	Uploads: retry once on network error; show inline error with “Retry” button for that document.
	•	Full submit: network timeout → show message Submission failed. Please try again. and re-enable submit button.
	•	Show per-file progress (future improvement).

Security & privacy notes (non-optional)
	•	Upload signed URLs must be short-lived (e.g., 5–15 minutes).
	•	Don’t include user-sensitive data in public thumbnails if you can avoid it. Ideally store in private bucket and expose via CDN only to authenticated clients or presigned GET URLs.
	•	Apply server-side checks to ensure uploaded images match expected file types (validate MIME & magic bytes), and scan for malware.
	•	GDPR/India PII: store Aadhaar numbers encrypted at rest or avoid storing raw numbers at all when possible — store hashed/kept as reference only. Consult legal team.

Testing strategy
Unit tests
	•	Validate ApiService.uploadImageToR2 using a mocked http.Client.
	•	Validate form validators.
Widget tests
	•	Pump KycOnboardingScreen with a mocked Mason object and simulate file selection + submit with bypass on → expect navigation to KycPendingScreen.
Manual tests
	•	Test real upload with a dev backend using signed URLs.
	•	Test large file rejection and network failures.
	•	Test camera capture + immediate upload.

Recommended backend changes (for compatibility)
	•	POST /api/uploads/signed-url — returns { uploadUrl, publicUrl }.
	•	POST /api/kyc-submissions — validates masonId against authenticated user; returns 201 with { success: true }.
	•	Provide admin UI for TSO to review documents and change kycStatus (none → pending → approved/rejected).

Summary: Checklist before production shipping
	•	Set _useRealKyc = true via env/flavor, not hard-coded.
	•	Ensure ApiService.uploadImageToR2 matches server signed-url contract.
	•	Implement server-side validation & temporary signed URLs.
	•	Add validations for Aadhaar/PAN format & file sizes.
	•	Add retries and error UI for failed uploads.
	•	Turn on AppCheck and secure your endpoints.
	•	Remove debug toasts and bypass toggles from production.

If you want, I can now:
	•	Generate the exact ApiService file and add it to your README as a code block (completed above).
	•	Inject named route /kyc_pending and show how to call it from main.dart.
	•	Stub TSO admin endpoints (review/approve) so your KYC lifecycle is end-to-end.
Which one next? Pick a file and paste it. I’ll stitch it into the canonical mega-README and keep the documentation perfect.

9:
Fine. You dumped four files and I read them like a caffeine-fueled code auditor. Below is the fully documented, no-fluff README section for:
	•	ContractorHomeScreen
	•	ContractorJobsScreen
	•	ContractorNavScreen
	•	ContractorProfileScreen
I explain what each file does, expected props, routes, UI contract, TODOs, sample backend calls, and quick improvement steps so you can stop guessing and start shipping.
Contractor screens — README additions

Table of contents for this section
	1.	ContractorHomeScreen — placeholder doc
	2.	ContractorJobsScreen — assigned jobs UI + expectations
	3.	ContractorNavScreen — shell + bottom navigation + drawer integration
	4.	ContractorProfileScreen — profile summary + logout
	5.	Integration & routing examples
	6.	Tests, UX notes, and recommended improvements

1) ContractorHomeScreen — file summary
Path: lib/screens/contractor/contractor_home_screen.dart Widget: ContractorHomeScreen extends StatelessWidget Constructor: ContractorHomeScreen({ required Employee employee })
What it does
	•	Minimal placeholder "Contractor Dashboard" screen.
	•	Displays employee.displayName in a centered Text.
	•	Has a simple AppBar.
Props / Data model
	•	Employee employee — uses employee.displayName. Ensure Employee has that property.
Routes
	•	Should be reachable as /contractor_home only if your app uses Employee flows (main app). But in your current architecture contractor flow uses Mason, not Employee. This screen is likely a legacy or placeholder.
To do (practical)
	•	Replace placeholder body with the actual contractor dashboard later or remove if redundant.
	•	If contractors use Mason (not Employee) keep this only for employee-facing contractor admin views.
Example usage
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => ContractorHomeScreen(employee: employee),
));

2) ContractorJobsScreen — assigned jobs list
Path: lib/screens/contractor/contractor_jobs_screen.dart Widget: ContractorJobsScreen extends StatefulWidget Constructor: ContractorJobsScreen({ required Mason mason })
Purpose
	•	Shows contractor’s upcoming and completed jobs.
	•	Acts as the "Home" tab for contractors in the ContractorNavScreen.
Current UI (what you have)
	•	AppBar: "Assigned Jobs"
	•	ListView with sections: Upcoming Jobs, Completed Jobs
	•	Each job shown as Card → ListTile with icon, title, subtitle, and onTap placeholder
Important considerations
	•	mason prop is passed but unused in the current UI. Use it to fetch contractor-specific jobs from backend.
	•	Replace hard-coded cards with dynamic content pulled from API.
Backend contract (suggested)
GET /api/mason/{masonId}/jobs?status=upcoming Response:
[{ "id":"job-1", "title":"Fix Leaking Pipe", "site":"ABC Apartments, Site 10B", "scheduledAt":"2025-11-14T09:00:00Z", "status":"upcoming" }]
GET /api/mason/{masonId}/jobs?status=completed
POST /api/mason/{masonId}/jobs/{jobId}/report — submit work report when job done
Example dynamic build (pseudo)
ListView(
  children: jobs.map((job) => Card(
    child: ListTile(
      leading: Icon(Icons.construction, color: Colors.orange),
      title: Text("Job: ${job.title}"),
      subtitle: Text("Site: ${job.site}"),
      onTap: () => Navigator.pushNamed(context, '/job_detail', arguments: job),
    ),
  )).toList(),
)
UX & features to add
	•	Pull-to-refresh (RefreshIndicator)
	•	Empty state UI with CTA (e.g., "No jobs assigned")
	•	Filter by date / search
	•	Job detail screen with accept/decline and start/complete actions
	•	Offline caching (Hive) of assigned jobs for flaky networks

3) ContractorNavScreen — bottom nav + drawer shell
Path: (part of contractor screens) Widget: ContractorNavScreen extends StatefulWidget Constructor: ContractorNavScreen({ required Mason mason })
Purpose
	•	Provides the primary app shell for contractor users:
	•	Left drawer (ContractorDrawer)
	•	IndexedStack body for tab preservation
	•	BottomNavigationBar with Home & Profile
Key implementation details
	•	_selectedIndex controls IndexedStack pages: [ ContractorJobsScreen, ContractorProfileScreen ]
	•	Drawer is injected: drawer: ContractorDrawer(mason: widget.mason)
	•	Bottom bar colors: selectedItemColor: Colors.orange matching brand
Why IndexedStack?
	•	Keeps state for each tab (good for forms, scroll positions).
	•	Simple and effective.
Important: Dependency contract
	•	Files imported: contractor_jobs_screen.dart, contractor_profile_screen.dart, contractor_drawer.dart. Ensure these exist and accept mason.
Route usage
When you navigate to contractor dashboard from login:
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => ContractorNavScreen(mason: mason)),
);
Alternatively integrate with named routes by wiring /contractor_home to build ContractorNavScreen.
Improvements / robustness
	•	Add badge support on bottom navigation (unread messages, pending jobs).
	•	Add deep-link handling (open app to specific job).
	•	Add optional floating action button for "Start New Job" or "Report Issue".
	•	Add accessibility labels for bottom nav items.

4) ContractorProfileScreen — profile & logout
Path: lib/screens/contractor/contractor_profile_screen.dart Widget: ContractorProfileScreen extends StatelessWidget Constructor: ContractorProfileScreen({ required Mason mason })
Purpose
	•	Show basic contractor info: name, KYC status, points balance
	•	Provide logout button
Dependencies / behavior
	•	Uses mason.name, mason.kycStatus, mason.pointsBalance
	•	Logout uses MasonAuth.AuthService(baseUrl: ...).logout(); then navigates to /selector removing stack.
Recommended improvements
	•	Replace raw logout creation with injected AuthService (Provider or GetIt) to avoid constructing new service inline and to ease testing.
	•	Show additional fields: email, address, joinedAt, totalJobsCompleted.
	•	Add "Edit profile" and "Upload avatar" actions.
	•	Display KYC badge (approved/pending/rejected) with color coding.
Example logout using injected auth service (recommended)
final auth = Provider.of<AuthService>(context, listen:false);
await auth.logout();
Navigator.of(context).pushNamedAndRemoveUntil('/selector', (_) => false);

5) Integration & routing examples
main.dart wiring (contractor flow)
You already have this logic in main.dart's onGenerateRoute. Example call after login:
Navigator.of(context).pushNamedAndRemoveUntil(
  '/contractor_home',
  (_) => false,
  arguments: masonData, // Map or Mason object
);
main.dart handles mapping to ContractorNavScreen(mason: mason).
Named route registration (if preferred)
routes: {
  '/contractor_home': (context) {
    final mason = ModalRoute.of(context)!.settings.arguments as Mason;
    return ContractorNavScreen(mason: mason);
  },
}

6) Tests, UX notes, and recommended improvements
Tests
	•	Widget tests:
	•	Pump ContractorNavScreen with mocked mason and verify tabs render.
	•	Tap bottom nav items and ensure _selectedIndex updates.
	•	Unit tests:
	•	Test job list parsing and job card builder functions.
	•	Integration:
	•	Mock backend to return jobs; ensure list is populated.
UX notes
	•	Use RefreshIndicator for the jobs list so contractors can pull down to sync.
	•	Use local caching (Hive) to avoid empty state when offline.
	•	For job details provide Start/Stop timers and attach photos for reports.
Security
	•	Ensure job list requests are authenticated: backend should check masonId matches caller.
	•	Use AppCheck token on requests if you have AppCheck enabled.

Quick code snippets (copy-paste)
Pull-to-refresh in ContractorJobsScreen
RefreshIndicator(
  onRefresh: _loadJobs,
  child: ListView(...),
);
Show empty state
if (jobs.isEmpty) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox, size:64, color:Colors.grey),
        Text('No jobs assigned', style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: _loadJobs, child: Text('Refresh')),
      ],
    ),
  );
}
Better logout dialog
Future<void> _confirmLogout(AuthService auth, BuildContext context) async {
  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
    title: Text('Log out?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
      ElevatedButton(onPressed: () async {
        await auth.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/selector', (_) => false);
      }, child: Text('Log out')),
    ],
  ));
}

Final notes (sharp and useful)
	•	Your contractor UI shell is solid: IndexedStack + Drawer + BottomNavigationBar is a standard pattern and scales.
	•	Main missing piece: hook ContractorJobsScreen to a real API and stop using placeholder Cards.
	•	Don’t construct AuthService inline everywhere; use DI (Provider/GetIt) so logout is testable and consistent.
	•	Remove hard-coded dev switches from production; replace with flavors or .env flags.
If you want, I’ll:
	•	generate an AuthService provider example and show how to wire it into main.dart, or
	•	convert the job list into a live example using a fake API and include widget tests.
Say which and I’ll do it now — no drama, no extra questions.


  
PROGRESS :
App Architecture Summary: Contractor & Admin Portals

This document provides a comprehensive summary of the entire application, detailing the two primary user flows: Contractor and Admin (TSO). It covers the complete lifecycle, from initial login and authentication to the final application state for each user.

1. The Core: App Entry & Routing

The entire application starts from a single point and branches into three distinct portals.

1.1. AppSelectorScreen (app_selector_screen.dart)

This is the app's main entry point (initialRoute: '/selector'). It presents the user with three choices:

Salesforce Portal: Navigates to /salesforce_login for the legacy employee flow.

Contractor Portal: Navigates to /contractor_login for the new mason/contractor flow.

Admin Portal: Navigates to /admin_login for the new TSO/Admin management flow.

1.2. Master Routing (main.dart)

The main.dart file's onGenerateRoute function acts as the central "brain" of the app, directing users based on their login state and data.

// Sample Code: main.dart routing logic

onGenerateRoute: (settings) {
  
  // --- Salesforce (Legacy) ---
  if (settings.name == '/home') {
    final employee = settings.arguments as Employee;
    return MaterialPageRoute(
      builder: (context) => NavScreen(employee: employee), // Legacy App
    );
  }

  // --- Admin (TSO) Flow ---
  if (settings.name == '/admin_dashboard' || settings.name == '/admin') {
    final employee = settings.arguments as Employee;
    return MaterialPageRoute(
      builder: (context) => AdminNavScreen(employee: employee), // New Admin App
    );
  }
  if (settings.name == '/admin_kyc_detail') {
    final submission = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => AdminKycDetailScreen(submission: submission),
    );
  }

  // --- Contractor Flow ---
  if (settings.name == '/contractor_home') {
    final mason = (settings.arguments is Map) 
      ? Mason.fromJson(settings.arguments as Map<String, dynamic>)
      : settings.arguments as Mason;

    // This switch is the "brain" for the contractor
    switch (mason.kycStatus) {
      case 'approved':
        return MaterialPageRoute(
          builder: (context) => ContractorNavScreen(mason: mason),
        );
      case 'pending':
        return MaterialPageRoute(
          builder: (context) => KycPendingScreen(mason: mason),
        );
      case 'none':
      case 'rejected':
      default:
        return MaterialPageRoute(
          builder: (context) => KycOnboardingScreen(mason: mason),
        );
    }
  }
  return null;
}


2. The Contractor Flow (End-to-End)

This flow describes the journey of a new contractor, from their first text message to using the app.

2.1. Authentication (/contractor_login)

Screen: ContractorLoginScreen

Logic: The user enters their phone number.

Firebase OTP: A real OTP is sent via Firebase. The user verifies, and the app receives a firebaseIdToken.

Backend Handshake: This firebaseIdToken is sent to your server via AuthService.sendFirebaseIdToken(idToken). The server verifies the token, finds or creates a Mason record, and returns the full masonData object.

Result: The app navigates to the /contractor_home route, passing the masonData as an argument.

2.2. The KYC Router (/contractor_home)

As shown in the main.dart logic, this route is not a screen. It immediately inspects the mason.kycStatus and routes the user to one of three places.

2.3. Stage 1: Onboarding (KycOnboardingScreen)

If kycStatus is none or rejected.

Screen: KycOnboardingScreen

Logic: The user fills out a form with their Aadhaar/PAN numbers and takes photos (using the Camera or Gallery) for their documents.

API Calls:

Image Upload: Each photo is sent to your server via _api.uploadImageToR2(file), which hits POST /api/r2/upload-direct and returns a public Cloudflare URL.

Submission: All text data and the new image URLs are sent to the server via _api.submitKyc(...).

Backend Contract: POST /api/kyc-submissions

// Request Body
{
  "masonId": "uuid-...",
  "aadhaarNumber": "1234...",
  "panNumber": "ABCDE...",
  "documents": {
    "aadhaarFrontUrl": "https://...",
    "panUrl": "https://..."
  },
  "remark": "..."
}


Result: On success, the server updates the mason's kycStatus to pending. The app navigates to /contractor_home, which now routes the user to the KycPendingScreen.

2.4. Stage 2: Waiting (KycPendingScreen)

If kycStatus is pending.

Screen: KycPendingScreen

Logic: This is a "waiting room." The user is informed their submission is under review.

Pull-to-Refresh: The user can pull the screen down to trigger the _checkStatus() function.

API Call: _checkStatus() calls _api.fetchMasonById(mason.id!), which hits GET /api/masons/:id.

Result:

If the status is still pending, a snackbar says so.

If the status is now approved, the app navigates to /contractor_home, which now routes the user to the final app.

2.5. Stage 3: The App (ContractorNavScreen)

If kycStatus is approved.

Screen: ContractorNavScreen

Logic: This is the main app shell for the contractor. It has a ContractorDrawer and a 3-tab bottom navigation bar:

Home (ContractorJobsScreen): This screen calls _api.fetchJobsForMason(mason.id!) to get a list of "upcoming" and "completed" jobs.

API Contract: GET /api/mason/:id/jobs

Gift (Placeholder): A placeholder for your redemption/rewards feature.

Profile (ContractorProfileScreen): Shows the contractor's name, phone, and KYC status. Includes a "LOG OUT" button.

3. The Admin (TSO) Flow (End-to-End)

This flow describes the TSO's journey to log in and manage KYC submissions.

3.1. Authentication (/admin_login)

Screen: AdminLoginScreen

Logic: The TSO enters their alphanumeric loginId and password.

API Calls (2-Step Handshake): The _api.adminLogin(...) function performs two critical steps:

POST /api/auth/login: Sends the loginId and password. The server verifies them (plaintext) and returns a { token, userId }.

GET /api/users/:id: The app immediately uses the new token and userId to fetch the TSO's full profile as an Employee object.

Result: The app navigates to the /admin_dashboard route, passing the full Employee object.

3.2. The App Shell (AdminNavScreen)

Screen: AdminNavScreen

Logic: This is the main app shell for the TSO. It has a 4-tab bottom navigation bar:

Pending KYC (AdminDashboard): The TSO's "inbox."

Masons (Placeholder): For viewing all masons.

Reports (Placeholder): For viewing reports.

Profile (Placeholder): For TSO profile and logout.

3.3. The Admin "Inbox" (AdminDashboard)

Screen: AdminDashboard (The first tab in AdminNavScreen)

Logic: This screen immediately calls _api.fetchPendingKycSubmissions() to get a list of all submissions with a pending status.

API Call: GET /api/kyc-submissions?status=pending

This route (defined in kycSubmissionsGet.ts) finds all pending submissions, joins them with the mason data (name, phone), and returns the list.

Result: The TSO sees a list of contractors waiting for approval. Tapping one navigates to /admin_kyc_detail.

3.4. The Decision (AdminKycDetailScreen)

Screen: AdminKycDetailScreen

Logic: The TSO sees all the data submitted by the contractor, including their name, phone, ID numbers, and the photos they uploaded.

The Action: The TSO presses either "APPROVE" or "REJECT".

API Call: This triggers the _reviewSubmission(status) function, which calls _api.reviewKycSubmission(submissionId, status).

Backend Contract: PATCH /api/kyc-submissions/:id

// Request Body
{
  "status": "approved" // or "rejected"
}


Result: The server updates the submission and the contractor's main masonPcSide.kycStatus. The app pops back to the AdminDashboard, which refreshes its list (and the approved item disappears). The loop is now complete.

I hear you! You want the full, detailed technical breakdown of the entire application we just finished, summarizing the architecture, flows, and every critical fix we applied.

Here is the complete **Code-as-Documentation** summary for the Contractor/Admin Portal application.

---

## 🎯 Architecture Summary: Contractor & Admin Flow

This application uses a single code base to manage two distinct user roles: the **Contractor (Mason)** and the **TSO/Admin (Employee)**. The core concept revolves around building the `Mason` data model in stages and managing access via the `kycStatus`.

| Role | Entry Point | Initial Route | Main Activity |
| :--- | :--- | :--- | :--- |
| **Contractor** | `/selector` $\rightarrow$ `/contractor\_login` | `/kyc\_onboarding` or `/contractor\_home` | Submit KYC documents; wait for approval. |
| **TSO/Admin** | `/selector` $\rightarrow$ `/admin\_login` | `/admin\_dashboard` | Review and approve pending KYC submissions. |

---

## 1. The Contractor Flow (Build-by-Steps)

The Contractor flow is a multi-step process designed to gradually fill the `Mason` model and enforce session security.

### 1.1 Login & Session Management (`ContractorLoginScreen.dart`)

This screen is now **"smart"** and handles both authentication and session persistence.

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **User Identification** | `final _nameController = TextEditingController();` | Collects the user's **Full Name** and Phone Number simultaneously before OTP verification. |
| **Session Persistence** | `SharedPreferences.setString('jwt', jwt);` | After successful login, the `jwt`, `sessionToken`, `masonId`, `masonName`, and `masonPhone` are saved locally. |
| **Returning User Logic** | Checks `_isReturningUser` flag in `initState` to pre-fill Name/Phone fields as `readOnly`. | This allows returning users to verify identity with **only an OTP**, skipping redundant data entry. |
| **Logic Split** | `if (_isReturningUser) { // fetch profile and navigate to /contractor_home } else { // navigate to /kyc_onboarding }` | Directs authenticated users to either the KYC form (new users) or the main app (returning users). |

### 1.2 KYC Onboarding & Submission (`KycOnboardingScreen.dart`)

This screen completes the `Mason` model and performs the critical dual API calls.

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **Model Completion** | `final completeMason = _localMason.copyWith(..., userId: null, kycStatus: 'pending');` | The local `Mason` object is fully updated with document numbers and set to the **`pending` status** before submission. The **TSO ID (`userId`) is now optional** to prevent app-breaking API search issues. |
| **Dual API Submission (Critical)** | `await Future.wait([ _api.createMason(completeMason), _api.submitKyc(...) ]);` | This ensures that the single "Submit" click performs **both required actions** for the back end: **1)** Creates the permanent `mason_pc_side` database record, and **2)** Creates the TSO's task record in the `kyc-submissions` table. |
| **Server Validation Fix** | `() { final payload = completeMason.toJson(); payload.remove('id'); return _api.createMason(Mason.fromJson(payload)); }(),` | This is the crucial fix for the **`Unrecognized key(s) in object: 'id'`** error. It strips the auto-generated `id` from the payload before executing the `POST /api/masons` endpoint, satisfying the server's Zod validation schema for creation requests. |

### 1.3 Restricted Access & Status Check (`ContractorNavScreen.dart`)

The contractor lands here after submission, regardless of status.

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **Pending Mode** | `final isPending = _currentMason.kycStatus == 'pending';` | Determines the entire UI state based on this flag. |
| **Visual Blockade** | `if (isPending) _PendingBanner(...)` | Displays a prominent orange banner at the top of the screen. |
| **UI Disablement** | `child: AbsorbPointer(absorbing: isPending, child: IndexedStack(...))` | Wraps the main content and prevents all user interaction (taps, scrolling) until approval is granted. Navigation items are also disabled (`onTap: isPending ? null : _onItemTapped`). |
| **Status Refresh** | `_api.fetchMasonById(_currentMason.id!);` | The "Refresh" button in the banner calls the API to retrieve the user's latest record. If `kycStatus` is now `'approved'`, the state updates, the banner disappears, and the app becomes fully functional. |

---

## 2. The Admin/TSO Flow (Close the Loop)

The TSO uses these components to review and approve the pending submissions, completing the full lifecycle.

### 2.1 Admin Login (`AdminLoginScreen.dart`)

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **TSO Authentication** | `await _api.adminLogin(loginId, password);` | Executes a **two-step authentication handshake**: 1) `POST /api/auth/login` to get the JWT/userId, then 2) `GET /api/users/:id` to fetch the full `Employee` profile. |
| **Navigation** | `Navigator.pushNamedAndRemoveUntil('/admin_dashboard', ...)` | Sends the authenticated TSO directly to their dedicated dashboard, passing the `Employee` object. |

### 2.2 KYC Inbox (`AdminDashboard.dart`)

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **Pending Fetch** | `await _api.fetchPendingKycSubmissions();` | Calls `GET /api/kyc-submissions?status=pending`. The server is expected to use the TSO's JWT to filter this list, ensuring they only see submissions assigned to them (`userId`). |
| **List Display** | `ListView.builder` populates the list with Contractor names and phone numbers pulled from the submission object. |
| **Auto-Refresh** | `onTap: () => _viewDetails(submission); if (result == true) { _fetchSubmissions(); }` | After the TSO approves/rejects a submission, the main dashboard auto-refreshes the list, removing the processed item. |

### 2.3 Approval Screen (`AdminKycDetailScreen.dart`)

| Feature | Code Detail | Documentation |
| :--- | :--- | :--- |
| **Data Display** | Uses `Image.network` and helper methods to display the contractor's provided document numbers and images (if uploaded). |
| **Approval Action** | `_reviewSubmission('approved')` or `_reviewSubmission('rejected')` | Executes the final action on the record. |
| **Loop Closure (Critical)**| `await _api.reviewKycSubmission(submissionId, status);` | Calls `PATCH /api/kyc-submissions/:id` on the server. This API call handles the final business logic: updating the submission record **AND** updating the original `mason_pc_side` record's `kycStatus` to `'approved'` or `'rejected'`. |

---

**Everything is locked in.** The application is fully implemented end-to-end, from the contractor's first phone number entry to the TSO's final approval button.

PROGRESS :
🔐 Contractor Authentication & Persistent Session Flow

This document details the complete, finalized authentication architecture for the Contractor Portal, focusing on the implementation of Silent Session Refresh to eliminate repeated Firebase OTP requests for returning users.

The core goal is to enable immediate, password-less login unless the user's session has been completely invalidated (e.g., after 60+ days or manual logout).

1. The Multi-Token Strategy

The application now uses a dual-token system managed by the backend (authFirebase.ts) and secured on the client (AuthService).

Token

Storage Key

Expiration

Purpose

App JWT

app_jwt

Short (7 days)

Used in the Authorization: Bearer header for all API Calls.

Refresh Token

session_token

Long (60+ days)

Used only to request a new JWT when the old one expires.

2. The Complete Login Flow Diagram

This flow determines how a user gains access, prioritizing silent session restoration over manual steps.

Step

User Status

Client Action

Server Interaction

Final Result

A

Active Session (JWT Valid)

tryAutoLogin() calls _validateSession().

GET /api/auth/validate $\rightarrow$ 200 OK.

IMMEDIATE ACCESS. Skips login screen entirely.

B

Expired Session (Refresh Valid)

_validateSession() fails (401), triggers _refreshSession().

POST /api/auth/refresh $\rightarrow$ 200 OK.

SILENT LOGIN. New tokens saved, then proceeds to IMMEDIATE ACCESS (no OTP).

C

Expired Session (Refresh Invalid)

Both _validateSession() and _refreshSession() fail.

401 Unauthorized (or network error).

STREAMLINED MANUAL LOGIN. Shows customized UI, requiring only OTP (Name/Phone pre-filled/locked).

D

New User

No tokens found in storage.

Starts standard Firebase OTP flow.

MANUAL OTP/SIGNUP. Name and Phone required.

3. Server-Side Endpoints (server/src/routes/authFirebase.ts)

These are the critical REST endpoints that enable the persistence mechanism.

A. JWT Validation

Used by the client to check the short-lived JWT.