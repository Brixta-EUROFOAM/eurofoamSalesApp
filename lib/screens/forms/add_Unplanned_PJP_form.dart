// lib/screens/forms/add_Unplanned_PJP_form.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';
import '../../models/pjp_model.dart';

class AddUnplannedPjpFormScreen extends StatefulWidget {
  const AddUnplannedPjpFormScreen({Key? key}) : super(key: key);

  @override
  State<AddUnplannedPjpFormScreen> createState() => _AddUnplannedPjpFormScreenState();
}

class _AddUnplannedPjpFormScreenState extends State<AddUnplannedPjpFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isSubmitting = false;

  // --- Theme Colors ---
  final Color _bgLight = const Color(0xFFF8FAFC);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _unplannedPurple = const Color(0xFF8B5CF6);

  Future<void> _submitUnplannedVisit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Fetch Current User
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user_profile');
      if (userJson == null) throw Exception("User session missing.");
      
      final userMap = jsonDecode(userJson);
      final int userId = userMap['id'];

      // Construct single unplanned payload
      final pjp = PjpModel(
        id: "0",
        userId: userId,
        createdById: userId,
        planDate: DateTime.now(), // Specifically setting for today
        areaToBeVisited: _areaController.text.trim(),
        description: _descController.text.trim(),
        status: "Unplanned", // Bypasses verification
      );

      // Utilize the existing bulk route
      final success = await _apiService.submitBulkJourneyPlans([pjp]);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unplanned visit started!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        throw Exception("Failed to save to server.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          "Unplanned Visit",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: _cardNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Where are you visiting?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _areaController,
                      validator: (v) => v == null || v.trim().isEmpty ? "Required field" : null,
                      decoration: InputDecoration(
                        labelText: "Area / Dealer Name *",
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: _bgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _unplannedPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Description / Objective",
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: _bgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _unplannedPurple, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUnplannedVisit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _unplannedPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          "START VISIT",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}