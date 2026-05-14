// lib/screens/forms/add_Leave_form.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';
import '../../models/leaves_model.dart';
import '../../models/users_model.dart';

class AddLeaveFormScreen extends StatefulWidget {
  const AddLeaveFormScreen({Key? key}) : super(key: key);

  @override
  State<AddLeaveFormScreen> createState() => _AddLeaveFormScreenState();
}

class _AddLeaveFormScreenState extends State<AddLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // --- Theme Colors ---
  static const Color _cardNavy = Color(0xFF0F172A); // Deep Navy
  static const Color _bgLight = Color(0xFFF5F5F7);
  static const Color _surfaceWhite = Colors.white;

  UserModel? _currentUser;
  bool _isInitializing = true;
  bool _isSubmitting = false;

  String _leaveType = 'Casual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user_profile');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (_startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(
        const Duration(days: 1),
      ), // Allow slightly backdated
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _cardNavy,
              onPrimary: Colors.white,
              onSurface: _cardNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // Reset end date if it's now before the new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showError('Please select both start & end dates');
      return;
    }
    if (_currentUser == null) {
      _showError('User session error. Please login again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final leave = LeaveModel(
        id: "0", // Backend will generate the actual UUID
        userId: _currentUser!.id,
        leaveType: _leaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reason,
        status: 'Pending',
        appRole: _currentUser!.role,
      );

      final success = await _apiService.applyForLeave(leave);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave Application Submitted!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Return true to trigger refresh on previous screen
        }
      } else {
        _showError('Failed to submit application. Please try again.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: _bgLight,
        body: Center(child: CircularProgressIndicator(color: _cardNavy)),
      );
    }

    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          'Apply Leave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _surfaceWhite,
        foregroundColor: _cardNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // --- LEAVE TYPE DROPDOWN ---
                    DropdownButtonFormField<String>(
                      value: _leaveType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Casual Leave',
                          child: Text('Casual Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'Sick Leave',
                          child: Text('Sick Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'Emergency Leave',
                          child: Text('Emergency Leave'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _leaveType = v!),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Leave Type',
                        labelStyle: TextStyle(
                          color: _cardNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _cardNavy, width: 2),
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: _cardNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- START DATE ---
                    _buildDateTile(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                      formatter: df,
                    ),

                    const SizedBox(height: 20),

                    // --- END DATE ---
                    _buildDateTile(
                      label: 'End Date',
                      date: _endDate,
                      onTap: _startDate == null ? null : () => _pickDate(false),
                      formatter: df,
                    ),

                    const SizedBox(height: 24),

                    // --- REASON TEXT FIELD ---
                    TextFormField(
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        labelStyle: TextStyle(
                          color: _cardNavy,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _cardNavy, width: 2),
                        ),
                        prefixIcon: Icon(Icons.edit_note, color: _cardNavy),
                        alignLabelWithHint: true,
                        hintText:
                            "Briefly describe the reason for your leave...",
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter a reason'
                          : null,
                      onChanged: (v) => _reason = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SUBMIT APPLICATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
    required DateFormat formatter,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: _cardNavy,
            fontWeight: FontWeight.bold,
          ),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _cardNavy, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          prefixIcon: const Icon(
            Icons.calendar_month_rounded,
            color: _cardNavy,
          ),
        ),
        child: Text(
          date == null ? 'Tap to select date' : formatter.format(date),
          style: TextStyle(
            color: date == null ? Colors.grey.shade500 : Colors.black87,
            fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
