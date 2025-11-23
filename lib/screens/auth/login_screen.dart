import 'dart:ui';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Flag to track which door they entered from
  bool _isTechnicalLogin = false; 
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Read the arguments passed from AppSelectorScreen
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('isTechnical')) {
        _isTechnicalLogin = args['isTechnical'];
      }
      _isInit = true;
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    // 1. Normalize Input (Uppercase for prefix check)
    final enteredLoginId = _loginIdController.text.trim().toUpperCase(); 
    final password = _passwordController.text;

    if (enteredLoginId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter Login ID and Password.');
      return;
    }

    // --- 2. PATTERN ENFORCEMENT ---
    if (_isTechnicalLogin) {
      if (!enteredLoginId.startsWith('TSE')) {
        setState(() => _errorMessage = 'Technical IDs must start with "TSE".');
        return;
      }
    } else {
      if (!enteredLoginId.startsWith('EMP')) {
        setState(() => _errorMessage = 'Sales IDs must start with "EMP".');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 3. Authenticate with Backend
      // Note: We pass the exact text the user typed (trimmed)
      final Employee employee = await AuthService().login(_loginIdController.text.trim(), password);
      
      if (!mounted) return;

      // 4. ROLE VALIDATION (Security Check)
      if (_isTechnicalLogin) {
        // User entered via "Technical" door, but is their role actually technical?
        if (!employee.isTechnicalRole) {
           throw Exception("Access Denied: This account is not authorized for Technical Access.");
        }
        
        // Save preference for auto-login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_technical_mode', true);

        // Go to Tech App
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/technical_home', 
          (route) => false,
          arguments: employee,
        );

      } else {
        // User entered via "Sales" door.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_technical_mode', false);

        // Go to Sales App
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
          arguments: employee,
        );
      }

    } catch (e) {
      dev.log('Login failed: $e');
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // UI Color Tweak based on mode
    final primaryGradient = _isTechnicalLogin 
        ? const Color(0xFF00695C) // Teal for Tech
        : const Color(0xFF0D47A1); // Blue for Sales

    return Scaffold(
      body: Container(
        // --- FIX 1: Removed 'const' from BoxDecoration because primaryGradient is variable ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGradient, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      // --- FIX 1: Removed 'const' here as well just in case, though mostly fine if properties are const ---
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.white.withAlpha(51)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isTechnicalLogin ? 'Technical Portal' : 'Sales Portal', 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isTechnicalLogin ? 'Enter your TSE ID' : 'Enter your EMP ID', 
                            style: const TextStyle(color: Colors.white70)
                          ),
                          const SizedBox(height: 32),
                          
                          // Login ID Field
                          TextField(
                            controller: _loginIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _isTechnicalLogin ? 'Technical ID (TSE...)' : 'Sales ID (EMP...)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(_errorMessage!, style: const TextStyle(color: Colors.amberAccent), textAlign: TextAlign.center),
                            ),
                            
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTechnicalLogin ? Colors.tealAccent : Colors.blueAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('LOGIN'),
                            ),
                          ),                          
                        ],
                      ),
                    ),
                  ),
                ), // --- FIX 2: Added missing closing parenthesis for ClipRRect
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}