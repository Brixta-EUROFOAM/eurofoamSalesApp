import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart'; // Using the main ApiService
import 'package:assetarchiverflutter/models/employee_model.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // --- ✅ CHANGED TO LOGIN ID ---
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // --- ✅ API CALL IS ALREADY CORRECT ---
      // This calls adminLogin with the loginId and password
      final Employee employee = await _api.adminLogin(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        // Navigate to the admin dashboard, passing the Employee object
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin_dashboard', // This route is handled in main.dart
          (route) => false,
          arguments: employee, // Pass the logged-in Employee object
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TSO / Admin Access',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your company-issued ID.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  // --- ✅ UPDATED CONTROLLER ---
                  controller: _loginIdController,
                  decoration: const InputDecoration(
                    labelText: 'Login ID', // --- ✅ UPDATED LABEL ---
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  // --- ✅ UPDATED KEYBOARD TYPE ---
                  keyboardType: TextInputType.text, 
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter your Login ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _login,
                    child: const Text('SIGN IN'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}