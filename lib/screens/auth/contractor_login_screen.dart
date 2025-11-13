import 'package:flutter/material.dart';
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