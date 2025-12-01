// lib/screens/forms/create_leave_form.dart
import 'dart:ui';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/leave_application_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateLeaveFormScreen extends StatefulWidget {
  final Employee employee;
  const CreateLeaveFormScreen({super.key, required this.employee});

  @override
  State<CreateLeaveFormScreen> createState() => _CreateLeaveFormScreenState();
}

class _CreateLeaveFormScreenState extends State<CreateLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _reasonController = TextEditingController();

  // State Management
  bool _isSubmitting = false;
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 

  @override
  void dispose() {
    _reasonController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final now = DateTime.now();
    final firstDate = isStartDate ? now : (_startDate ?? now);
    final initialDate = isStartDate ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _cardNavy, 
              onPrimary: Colors.white, 
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd-MM-yyyy').format(picked);
          // If end date is before new start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      final newApplication = LeaveApplication(
        userId: int.parse(widget.employee.id),
        leaveType: _selectedLeaveType!,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reasonController.text,
        status: 'Pending',
      );

      await _apiService.createLeaveApplication(newApplication);

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Leave application submitted successfully!'),
        backgroundColor: Colors.green,
      ));
      navigator.pop();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Helpers ---

  Widget _buildFintechDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _surfaceWhite,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
          ),
          items: items.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildFintechDateInput({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: (v) => v!.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            suffixIcon: const Icon(Icons.calendar_today_outlined, color: _textGrey, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: (v) => v!.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cardNavy, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Apply for Leave', 
                          style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textGrey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 30),
                    
                    _buildFintechDropdown(
                      label: 'Leave Type',
                      value: _selectedLeaveType,
                      items: ['Sick Leave', 'Casual Leave', 'Paid Leave', 'Other'],
                      onChanged: (value) => setState(() => _selectedLeaveType = value),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildFintechDateInput(
                            controller: _startDateController,
                            label: 'Start Date',
                            onTap: () => _selectDate(context, isStartDate: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFintechDateInput(
                            controller: _endDateController,
                            label: 'End Date',
                            onTap: () => _selectDate(context, isStartDate: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFintechInput(
                      controller: _reasonController,
                      label: 'Reason',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitLeaveApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}