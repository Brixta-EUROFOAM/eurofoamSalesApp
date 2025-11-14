// lib/screens/contractor/contractor_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assetarchiverflutter/api/firebase_auth.dart';
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'dart:developer' as dev; // Import for better logging

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

  final bool _useRealOtp = true;

  final _auth = FirebaseAuth.instance;
  final _authService = AuthService(
    baseUrl: 'https://myserverbymycoco.onrender.com',
  );

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  // --- NEW: State for Auto-Login Check ---
  bool _isCheckingSession = true; 
  // --- NEW: State for UI adjustment on failed auto-login ---
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
  // ------------------------------------------------------------
  Future<void> _attemptAutoLogin() async {
    dev.log('Starting auto-login attempt.', name: 'AuthDebug');
    
    // 1. Check for stored JWT
    final storedJwt = await _authService.getStoredJwt();
    dev.log('Stored JWT found? ${storedJwt != null}', name: 'AuthDebug'); 
    
    // If no JWT is found, show the manual login screen.
    if (storedJwt == null) {
      setState(() => _isCheckingSession = false);
      dev.log('No stored JWT. Showing manual login.', name: 'AuthDebug');
      return; 
    }

    // 2. Session found: attempt to validate it on backend
    try {
      _toast('Session found. Validating...');
      final serverStub = await _authService.tryAutoLogin(); 
      
      dev.log('Server response received. Null? ${serverStub == null}', name: 'AuthDebug');
      if (serverStub != null) {
        dev.log('Server response has Mason? ${serverStub['mason'] != null}', name: 'AuthDebug');
      }
      
      if (serverStub != null && serverStub['mason'] != null) {
        _toast('Welcome back!');
        
        // Use the validated data from the server
        final masonData = serverStub['mason'];

        final Mason localMason = Mason(
          id: masonData['id'],
          firebaseUid: masonData['firebaseUid'],
          name: masonData['name'] ?? '',
          phoneNumber: masonData['phoneNumber'] ?? '',
          kycStatus: masonData['kycStatus'] ?? 'none',
          pointsBalance: masonData['pointsBalance'] ?? 0,
        );

        if (!mounted) return;
        
        dev.log('Auto-login SUCCESS. Navigating to /contractor_home', name: 'AuthDebug'); // <-- SUCCESS PATH
        
        // Navigate directly to the KYC Router
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/contractor_home', 
          (_) => false,
          arguments: localMason,
        );
        return; // Exit after successful navigation
      }
    } catch (e) {
      dev.log('Auto-login network/parsing error: $e', name: 'AuthDebug');
    }
    
    // 3. Fallback: Show the manual login screen but customize UI
    final storedDetails = await _authService.getStoredMasonDetails();
    
    // If we have stored details, it means the user has logged in before.
    if (storedDetails['masonName'] != null && storedDetails['masonPhone'] != null) {
      _nameController.text = storedDetails['masonName']!;
      _phoneController.text = storedDetails['masonPhone']!;
      // Activate the returning user UI state
      _isReturningUserUI = true;
    } 
    
    dev.log('Auto-login FAILED. Setting _isReturningUserUI: $_isReturningUserUI', name: 'AuthDebug'); // <-- FAILURE PATH
    setState(() => _isCheckingSession = false);
  }

  // ------------------------------------------------------------
  // SEND OTP
  // ------------------------------------------------------------
  Future<void> _sendOtp({bool isResend = false}) async {
    // Only validate phone if we are a returning user, otherwise validate name too.
    if (!_isReturningUserUI && !_formKey.currentState!.validate()) return;
    if (_isReturningUserUI && _phoneController.text.trim().isEmpty) {
      _toast('Please enter your phone number.');
      return;
    }
    
    final phone = _phoneController.text.trim();

    if (!phone.startsWith('+') || phone.length < 10) {
      _toast('Use E.164 format: +91...');
      return;
    }

    setState(() => _isLoading = true);

    if (!_useRealOtp) {
      _toast('DEBUG BYPASS: OTP skipped.');
      setState(() {
        _verificationId = 'dev-bypass';
        _isOtpSent = true;
        _isLoading = false;
      });
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential cred) async {
          try {
            await _auth.signInWithCredential(cred);
            await _finishBackendHandshake();
          } catch (_) {}
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
      _toast('Enter OTP');
      return;
    }

    setState(() => _isLoading = true);

    if (!_useRealOtp) {
      await _finishBackendBypass();
      return;
    }

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
        'session-expired' => 'OTP expired',
        'too-many-requests' => 'Too many attempts',
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
  // BACKEND HANDSHAKE (MODIFIED TO NAVIGATE TO /contractor_home)
  // ------------------------------------------------------------
  Future<void> _finishBackendHandshake() async {
    setState(() => _isLoading = true);

    final idToken = await _auth.currentUser?.getIdToken(true);

    dev.log('idToken null? ${idToken == null}', name: 'Auth');

    if (idToken == null) {
      _toast('No Firebase token');
      setState(() => _isLoading = false);
      return;
    }

    final serverStub = await _authService.sendFirebaseIdToken(idToken);

    if (serverStub != null && serverStub['mason'] != null) {
      _toast('Login successful');

      final masonData = serverStub['mason'];
      
      // Use stored name if not provided by the server/input (for returning users)
      final userName = masonData['name'] ?? _nameController.text.trim();

      final Mason localMason = Mason(
        id: masonData['id'],
        firebaseUid: masonData['firebaseUid'],
        name: userName,
        phoneNumber: _phoneController.text.trim(),
        kycStatus: masonData['kycStatus'] ?? 'none',
        pointsBalance: masonData['pointsBalance'] ?? 0,
      );

      if (!mounted) return;

      // Navigate to /contractor_home which is the KYC Router
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contractor_home', 
        (_) => false,
        arguments: localMason,
      );
    } else {
      _toast('Server auth failed.');
    }

    setState(() => _isLoading = false);
  }

  // ------------------------------------------------------------
  // DEV BYPASS (MODIFIED TO NAVIGATE TO /contractor_home)
  // ------------------------------------------------------------
  Future<void> _finishBackendBypass() async {
    setState(() => _isLoading = true);

    final serverStub =
        await _authService.sendDevBypassLogin(_phoneController.text.trim());

    if (serverStub != null && serverStub['mason'] != null) {
      _toast('DEBUG BYPASS: Login successful');

      final masonData = serverStub['mason'];
      final userName = masonData['name'] ?? _nameController.text.trim();


      final Mason localMason = Mason(
        id: masonData['id'],
        firebaseUid: masonData['firebaseUid'],
        name: userName,
        phoneNumber: _phoneController.text.trim(),
        kycStatus: masonData['kycStatus'] ?? 'none',
        pointsBalance: masonData['pointsBalance'] ?? 0,
      );

      if (!mounted) return;

      // Navigate to /contractor_home which is the KYC Router
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contractor_home', 
        (_) => false,
        arguments: localMason,
      );
    } else {
      _toast('DEBUG BYPASS: Server auth failed');
    }

    setState(() => _isLoading = false);
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
              Text('Checking saved session...'),
            ],
          ),
        ),
      );
    }

    // Original login UI if no session is found
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
            children: [
              Text(
                _isOtpSent 
                    ? 'Verify your number' 
                    : (_isReturningUserUI
                        ? 'Welcome back, ${_nameController.text}!'
                        : 'Sign in with your phone'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // --- FULL NAME FIELD (Hidden for Returning Users) ---
              if (!_isReturningUserUI) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  readOnly: _isOtpSent,
                ),
                const SizedBox(height: 16),
              ],
              // ----------------------------------------------------

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _isReturningUserUI ? 'Your Phone Number' : 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.startsWith('+') || v.length < 10)
                        ? 'Use +91...'
                        : null,
                // Phone is read-only if we detected a returning user
                readOnly: _isOtpSent || _isReturningUserUI,
              ),

              if (_isOtpSent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
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
                  child: Text(_isOtpSent ? 'SIGN IN' : (_isReturningUserUI ? 'GET OTP' : 'SEND OTP')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}