// lib/screens/contractor/contractor_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assetarchiverflutter/api/firebase_auth.dart'; // Import the new AuthService
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'dart:developer' as dev;

class ContractorLoginScreen extends StatefulWidget {
  const ContractorLoginScreen({super.key});

  @override
  State<ContractorLoginScreen> createState() => _ContractorLoginScreenState();
}

class _ContractorLoginScreenState extends State<ContractorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();

  // --- ⬇️ START DEV BYPASS SWITCH ⬇️ ---
  // Set this to 'true' to bypass OTP and log in instantly
  final bool _useDevBypass = false; // <-- ❄️ YOUR DEV SWITCH ❄️
  // --- ⬆️ END DEV BYPASS SWITCH ⬆️ ---

  final _auth = FirebaseAuth.instance;
  final _authService = AuthService(
    // Ensure this URL is correct for your emulator/device
    // Use 'http://10.0.2.2:8000' for local dev with Android Emulator
    baseUrl: 'https://myserverbymycoco.onrender.com',
  );

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  // --- NEW: State for Auto-Login Check ---
  bool _isCheckingSession = true;
  // --- NEW: State for UI adjustment on failed auto-login ---
  // This flag controls whether we show the "Name" field.
  // If true, we assume it's a returning user just logging in.
  // If false, we assume it's a new user signing up.
  bool _isReturningUserUI = false;
  // ---------------------------------------

  @override
  void initState() {
    super.initState();
    // Start checking for an existing session immediately
    _attemptAutoLogin();
  }

  // ------------------------------------------------------------
  // NEW: AUTO-LOGIN HANDLER
  // This runs on init. It tries to log you in without an OTP.
  // ------------------------------------------------------------
  Future<void> _attemptAutoLogin() async {
    dev.log('Starting auto-login attempt.', name: 'AuthDebug');
    setState(() => _isCheckingSession = true);

    try {
      // tryAutoLogin() handles the full validate/refresh logic
      final serverResponse = await _authService.tryAutoLogin();

      if (serverResponse != null && serverResponse['mason'] != null) {
        _toast('Welcome back!');
        final masonData = serverResponse['mason'];

        // We have a valid session, go straight to the app
        _navigateToHome(masonData);
        return; // Exit after successful navigation
      }
    } catch (e) {
      dev.log('Auto-login network/parsing error: $e', name: 'AuthDebug');
      // Fall through to show manual login
    }

    // --- AUTO-LOGIN FAILED ---
    // 3. Fallback: Show the manual login screen but customize UI
    final storedDetails = await _authService.getStoredMasonDetails();

    // If we have stored details, it means the user has logged in before.
    if (storedDetails['masonName'] != null &&
        storedDetails['masonPhone'] != null) {
      _nameController.text = storedDetails['masonName']!;
      _phoneController.text = storedDetails['masonPhone']!;

      // Activate the returning user UI state
      // This will hide the "Name" field and lock the "Phone" field
      setState(() => _isReturningUserUI = true);
    }

    dev.log(
        'Auto-login FAILED. Showing manual login. Returning User: $_isReturningUserUI',
        name: 'AuthDebug');
    setState(() => _isCheckingSession = false);
  }

  // ------------------------------------------------------------
  // NAVIGATION HELPER
  // ------------------------------------------------------------
  void _navigateToHome(Map<String, dynamic> masonData) {
    if (!mounted) return;

    // The backend provides the mason data. We create a local model.
    final Mason localMason = Mason(
      id: masonData['id'],
      firebaseUid: masonData['firebaseUid'],
      name: masonData['name'] ??
          _nameController.text.trim(), // Use controller as fallback
      phoneNumber: masonData['phoneNumber'] ?? _phoneController.text.trim(),
      kycStatus: masonData['kycStatus'] ?? 'none',
      pointsBalance: masonData['pointsBalance'] ?? 0,
      // Add other fields from your model if they exist in masonData
    );

    // --- ✅ FIX: Updated log message ---
    dev.log(
        'Navigating to /contractor_nav with mason: ${localMason.name}, Status: ${localMason.kycStatus}',
        name: 'AuthDebug');

    // Navigate to /contractor_nav which is the KYC Router
    // main.dart will see this route, check the kycStatus,
    // and send the user to the correct screen (Onboarding, Pending, or Dashboard)
    Navigator.of(context).pushNamedAndRemoveUntil(
      // --- ✅ FIX: This route must match main.dart's onGenerateRoute ---
      '/contractor_nav',
      (_) => false,
      arguments: localMason, // Pass the strongly-typed Mason object
    );
  }

  // ------------------------------------------------------------
  // SEND OTP
  // ------------------------------------------------------------
  Future<void> _sendOtp({bool isResend = false}) async {
    // Validate form (name and phone for new user, just phone for returning)
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    if (!phone.startsWith('+') || phone.length < 10) {
      _toast('Use E.164 format: +91...');
      return;
    }

    setState(() => _isLoading = true);

    // --- ⬇️ DEV BYPASS LOGIC ⬇️ ---
    if (_useDevBypass) {
      _toast('DEBUG BYPASS: Logging in...');
      await _finishBackendBypass();
      return;
    }
    // --- ⬆️ END DEV BYPASS LOGIC ⬆️ ---

    // This code only runs if _useDevBypass is false
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

  // ------------------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------------------
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if ((_verificationId ?? '').isEmpty || code.length < 4) {
      _toast('Enter the 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase credential
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      // 2. Sign in to Firebase
      await _auth.signInWithCredential(cred);
      // 3. Sign in to our backend
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

  // ------------------------------------------------------------
  // BACKEND HANDSHAKE (Real)
  // This is called after Firebase OTP is confirmed.
  // ------------------------------------------------------------
  Future<void> _finishBackendHandshake() async {
    setState(() => _isLoading = true);
    final idToken = await _auth.currentUser?.getIdToken(true);
    if (idToken == null) {
      _toast('Could not get Firebase token');
      setState(() => _isLoading = false);
      return;
    }

    final name = _nameController.text.trim();

    final serverResponse =
        await _authService.sendFirebaseIdToken(idToken, name);

    if (serverResponse != null && serverResponse['mason'] != null) {
      _toast('Login successful');
      _navigateToHome(serverResponse['mason']); // Navigate to KYC Router
    } else {
      _toast('Server auth failed. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------------------------
  // DEV BYPASS
  // ------------------------------------------------------------
  Future<void> _finishBackendBypass() async {
    setState(() => _isLoading = true);

    // --- ⬇️ *** FIX *** ⬇️ ---
    // Send both name and phone
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final serverResponse = await _authService.sendDevBypassLogin(phone, name);
    // --- ⬆️ *** END FIX *** ⬆️ ---

    if (serverResponse != null && serverResponse['mason'] != null) {
      _toast('DEBUG BYPASS: Login successful');
      _navigateToHome(serverResponse['mason']); // Navigate to KYC Router
    } else {
      _toast('DEBUG BYPASS: Server auth failed. Is backend running?');
      setState(() => _isLoading = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI - Conditional Render
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Show splash/loading screen while checking session
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking session...'),
            ],
          ),
        ),
      );
    }

    // --- Session check complete, show login form ---
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isOtpSent
                    ? 'Verify your number'
                    // If it's a returning user, welcome them by name
                    : (_isReturningUserUI
                        ? 'Welcome back!'
                        : 'Sign Up / Sign In'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                    : (_isReturningUserUI
                        // Show their name if we have it
                        ? 'Welcome, ${_nameController.text}.\nPlease verify your number to log in.'
                        : 'Enter your name and phone number to begin.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- FULL NAME FIELD (Hidden for Returning Users) ---
              // This field is only shown if it's a new user (sign up)
              if (!_isReturningUserUI) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                  readOnly: _isOtpSent, // Lock when OTP is sent
                ),
                const SizedBox(height: 16),
              ],
              // ----------------------------------------------------

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.startsWith('+') || v.length < 10)
                        ? 'Use E.164 format (e.g., +91...)'
                        : null,
                // Phone is read-only if we detected a returning user OR if OTP is sent
                readOnly: _isOtpSent || _isReturningUserUI,
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
                  onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  // Text changes based on context
                  child: Text(_isOtpSent
                      ? 'SIGN IN'
                      : (_isReturningUserUI
                          ? 'GET OTP TO LOG IN'
                          : 'GET OTP TO SIGN UP')),
                ),

              // --- NEW: Switch between Sign Up / Login ---
              if (!_isOtpSent && !_isLoading)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isReturningUserUI = !_isReturningUserUI;
                      // Clear fields when switching
                      if (!_isReturningUserUI) {
                        _nameController.clear();
                        _phoneController.text = '+91';
                      }
                    });
                  },
                  child: Text(_isReturningUserUI
                      ? 'Not you? Sign up as a new user'
                      : 'Already have an account? Log in'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}