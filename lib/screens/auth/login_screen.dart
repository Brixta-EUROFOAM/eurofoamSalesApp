import 'dart:ui';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/api/auth_service.dart';
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

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight     = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark    = Color(0xFF111827); // Navy/Black
  static const Color _textGrey    = Color(0xFF6B7280); // Subtitle Grey
  
  // Dynamic Colors based on role
  Color get _activeColor => _isTechnicalLogin ? const Color(0xFF0F766E) : const Color(0xFF0F172A); // Teal vs Navy
  Color get _activeBg    => _isTechnicalLogin ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9); // Light Teal vs Light Blue

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
      final Employee employee = await AuthService().login(enteredLoginId, password);
      
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
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // --- 1. Header Icon ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _activeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTechnicalLogin ? Icons.engineering : Icons.business_center, 
                  size: 40, 
                  color: _activeColor
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Title Texts ---
              Text(
                _isTechnicalLogin ? 'Technical Portal' : 'Sales Portal', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: _textDark,
                  letterSpacing: -0.5,
                )
              ),
              const SizedBox(height: 8),
              Text(
                _isTechnicalLogin ? 'Please enter your TSE credentials' : 'Please enter your EMP credentials', 
                style: const TextStyle(color: _textGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- 3. Login Card ---
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(color: Colors.white),
                ),
                child: Column(
                  children: [
                    // Login ID Field
                    _buildFintechInput(
                      controller: _loginIdController,
                      label: _isTechnicalLogin ? 'Technical ID' : 'Sales ID',
                      hint: _isTechnicalLogin ? 'TSE...' : 'EMP...',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    _buildFintechInput(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!, 
                                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'SECURE LOGIN',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                      ),
                    ), 
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // --- 4. Footer ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: _textGrey),
                  const SizedBox(width: 6),
                  Text(
                    "End-to-End Encrypted",
                    style: TextStyle(color: _textGrey.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper for cleaner input fields
  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: _textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Very light grey
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _activeColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}