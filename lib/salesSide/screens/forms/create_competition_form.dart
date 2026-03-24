// lib/screens/forms/create_competition_form.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🚀 Premium Animations
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/competition_report_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';

class CreateCompetitionFormScreen extends StatefulWidget {
  final Employee employee;
  const CreateCompetitionFormScreen({super.key, required this.employee});

  @override
  State<CreateCompetitionFormScreen> createState() =>
      _CreateCompetitionFormScreenState();
}

class _CreateCompetitionFormScreenState
    extends State<CreateCompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _brandNameController = TextEditingController();
  final _billingController = TextEditingController();
  final _nodController = TextEditingController();
  final _retailController = TextEditingController();
  final _avgSchemeCostController = TextEditingController();
  final _remarksController = TextEditingController();

  // State
  bool _isSubmitting = false;
  String? _selectedSchemeOption;

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void dispose() {
    _brandNameController.dispose();
    _billingController.dispose();
    _nodController.dispose();
    _retailController.dispose();
    _avgSchemeCostController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      final newReport = CompetitionReport(
        userId: int.parse(widget.employee.id),
        reportDate: DateTime.now(),
        brandName: _brandNameController.text,
        billing: _billingController.text,
        nod: _nodController.text,
        retail: _retailController.text,
        schemesYesNo: _selectedSchemeOption!,
        avgSchemeCost: double.parse(_avgSchemeCostController.text),
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
      );

      await _apiService.createCompetitionReport(newReport);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Competition report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helper Widgets ---

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Roboto',
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: isRequired
              ? (v) => v!.isEmpty ? '$label is required' : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Roboto',
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
          ),
          items: items
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: onChanged,
          validator: isRequired ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to look like a dialog
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child:
                Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: _surfaceWhite,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Header ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Competition Form',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: _textGrey,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFF3F4F6), height: 30),

                            // 🚀 Staggered Input Fields
                            _buildFintechInput(
                                  controller: _brandNameController,
                                  label: 'Brand Name',
                                  hint: 'e.g. Star Cement',
                                )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechInput(
                                  controller: _billingController,
                                  label: 'Billing',
                                  hint: 'Billing details',
                                )
                                .animate()
                                .fadeIn(delay: 150.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechInput(
                                  controller: _nodController,
                                  label: 'NOD (Net of Distributor)',
                                  hint: 'Enter NOD value',
                                )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechInput(
                                  controller: _retailController,
                                  label: 'Retail',
                                  hint: 'Retail details',
                                )
                                .animate()
                                .fadeIn(delay: 250.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechDropdown(
                                  label: 'Schemes Active?',
                                  value: _selectedSchemeOption,
                                  items: ['Yes', 'No'],
                                  onChanged: (val) => setState(
                                    () => _selectedSchemeOption = val,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechInput(
                                  controller: _avgSchemeCostController,
                                  label: 'Average Scheme Cost',
                                  hint: '0.0',
                                  keyboardType: TextInputType.number,
                                )
                                .animate()
                                .fadeIn(delay: 350.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 16),

                            _buildFintechInput(
                                  controller: _remarksController,
                                  label: 'Remarks',
                                  hint: 'Additional observations...',
                                  isRequired: false,
                                  maxLines: 3,
                                )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideX(
                                  begin: -0.1,
                                  curve: Curves.easeOutCubic,
                                ),

                            const SizedBox(height: 24),

                            // 🚀 Emphasized Submit Button
                            SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _cardNavy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'SUBMIT REPORT',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms)
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  curve: Curves.easeOutBack,
                                ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .scale(curve: Curves.easeOutBack, duration: 400.ms)
                    .fadeIn(duration: 400.ms), // 🚀 Main Card Spring-in
          ),
        ),
      ),
    );
  }
}
