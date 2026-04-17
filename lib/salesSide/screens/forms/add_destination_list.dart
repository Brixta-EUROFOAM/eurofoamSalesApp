// lib/salesSide/screens/forms/add_destination_list.dart

import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/destination_model.dart'; // Adjust path if needed

class AddDestinationScreen extends StatefulWidget {
  final Employee employee;
  const AddDestinationScreen({super.key, required this.employee});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // State
  bool _isSubmitting = false;
  String? _selectedZone;
  String? _selectedInstitution; // <-- Added state for Institution Dropdown

  // Controllers
  final _districtController = TextEditingController();
  final _destinationController = TextEditingController();

  final List<String> _zones = [
    "All Zone",
    "Kamrup",
    "Upper Assam",
    "Lower Assam",
    "Central Assam",
    "Barak Valley",
    "North Bank",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Tripura",
  ];

  final List<String> _institutions = ["JUD", "JSB"]; // <-- Options for Institution

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void dispose() {
    _districtController.dispose();
    _destinationController.dispose();
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
      final newDestination = DestinationModel(
        institution: _selectedInstitution, // Using dropdown value
        zone: _selectedZone,
        district: _districtController.text.trim(),
        destination: _destinationController.text.trim(),
      );

      await _apiService.createDestination(newDestination);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Destination created successfully!'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _textGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            hintText: hint,
            hintStyle: const TextStyle(color: _textGrey, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGrey, size: 20),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechDropdown({
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? validatorMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: items,
          onChanged: onChanged,
          validator: (val) =>
              (validatorMsg != null && val == null) ? validatorMsg : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textGrey,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Destination",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Destination Details"),
                      const SizedBox(height: 16),
                      
                      // 1. ZONE DROPDOWN
                      _buildFintechDropdown(
                        value: _selectedZone,
                        label: "Zone",
                        validatorMsg: "Please select a zone",
                        items: _zones.map((zone) {
                          return DropdownMenuItem(
                            value: zone,
                            child: Text(
                              zone,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedZone = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. DISTRICT INPUT
                      _buildFintechInput(
                        controller: _districtController,
                        label: "District",
                        hint: "e.g. Kamrup Metropolitan",
                        icon: Icons.map_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 3. DESTINATION NAME INPUT
                      _buildFintechInput(
                        controller: _destinationController,
                        label: "Destination Name",
                        hint: "e.g. Guwahati City Center",
                        icon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 4. INSTITUTION DROPDOWN
                      _buildFintechDropdown(
                        value: _selectedInstitution,
                        label: "Institution",
                        validatorMsg: "Please select an institution",
                        items: _institutions.map((inst) {
                          return DropdownMenuItem(
                            value: inst,
                            child: Text(
                              inst,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedInstitution = val);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: _cardNavy.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SAVE DESTINATION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}