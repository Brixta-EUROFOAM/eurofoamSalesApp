// lib/screens/forms/add_Dealer_form.dart

import 'package:flutter/material.dart';

import '../../api/api_service.dart';
import '../../models/dealer_model.dart';
import '../../widgets/ReusableFunctions.dart';

class AddDealerForm extends StatefulWidget {
  const AddDealerForm({super.key});

  @override
  State<AddDealerForm> createState() => _AddDealerFormState();
}

class _AddDealerFormState extends State<AddDealerForm> {
  // =========================================================
  // THEME
  // =========================================================

  final Color _bgLight = const Color(0xFFF3F4F6);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _surfaceWhite = Colors.white;

  // =========================================================
  // FORM
  // =========================================================

  final _formKey = GlobalKey<FormState>();

  final ApiService _api = ApiService();

  final TextEditingController _businessNameController =
      TextEditingController();

  final TextEditingController _contactPersonController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _gstController =
      TextEditingController();

  final TextEditingController _panController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  final TextEditingController _areaController =
      TextEditingController();

  bool _isSubmitting = false;

  String? _selectedZone;

  final List<String> _zones = [
    'Uppser Assam', 'Lower Assam 1', 'Lower Assam 2', 'Barak Valley', 
    'Central Assam', 'Guwahati', 'North Bank 1', 'North Bank 2',
    'Meghalaya', 'Tripura', 'Nagaland', 'Others'
  ];

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select zone"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // =====================================================
      // GPS + ADDRESS
      // =====================================================

      final location =
          await ReusableFunctions.getCurrentLocationAndAddress();

      final dealer = DealerModel(
        id: 0,

        dealerPartyName:
            _businessNameController.text.trim(),

        contactPersonName:
            _contactPersonController.text.trim().isEmpty
                ? null
                : _contactPersonController.text.trim(),

        contactPersonNumber:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),

        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),

        gstNo:
            _gstController.text.trim().isEmpty
                ? null
                : _gstController.text.trim(),

        panNo:
            _panController.text.trim().isEmpty
                ? null
                : _panController.text.trim(),

        zone: _selectedZone,

        area:
            _areaController.text.trim().isEmpty
                ? null
                : _areaController.text.trim(),

        pinCode:
            _pinCodeController.text.trim().isEmpty
                ? null
                : _pinCodeController.text.trim(),

        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
      );

      final success = await _api.addDealer(dealer);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dealer added successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add dealer"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // =========================================================
  // REUSABLE TEXTFIELD
  // =========================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool requiredField = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: requiredField
            ? (v) =>
                v == null || v.trim().isEmpty
                    ? 'Required'
                    : null
            : null,
        decoration: InputDecoration(
          labelText: label,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _cardNavy,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _pinCodeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,

      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          "Add Dealer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: _surfaceWhite,

            borderRadius: BorderRadius.circular(24),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Dealer Information",
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "GPS location and address will be captured automatically during submission.",
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 24),

                // =====================================================
                // FORM FIELDS
                // =====================================================

                _buildTextField(
                  label: "Business Name *",
                  controller: _businessNameController,
                  requiredField: true,
                ),

                _buildTextField(
                  label: "Contact Person Name",
                  controller: _contactPersonController,
                ),

                _buildTextField(
                  label: "Phone Number",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),

                _buildTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),

                _buildTextField(
                  label: "GST Number",
                  controller: _gstController,
                ),

                _buildTextField(
                  label: "PAN Number",
                  controller: _panController,
                ),

                _buildTextField(
                  label: "Pincode",
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),

                  child: DropdownButtonFormField<String>(
                    value: _selectedZone,

                    decoration: InputDecoration(
                      labelText: "Zone *",

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _cardNavy,
                          width: 1.5,
                        ),
                      ),
                    ),

                    items: _zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        _selectedZone = value;
                      });
                    },
                  ),
                ),

                _buildTextField(
                  label: "Area",
                  controller: _areaController,
                ),

                const SizedBox(height: 12),

                // =====================================================
                // SUBMIT BUTTON
                // =====================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _submit,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardNavy,
                      foregroundColor: Colors.white,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),

                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Submit Dealer",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
