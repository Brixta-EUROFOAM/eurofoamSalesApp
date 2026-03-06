import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/leave_application_model.dart';

class CreateLeaveFormScreen extends StatefulWidget {
  final int userId; // Changed to int userId to match List Screen
  final String appRole;

  const CreateLeaveFormScreen({super.key, required this.userId, required this.appRole,});

  @override
  State<CreateLeaveFormScreen> createState() => _CreateLeaveFormScreenState();
}

class _CreateLeaveFormScreenState extends State<CreateLeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // --- Theme Colors ---
  static const Color _cardNavy = Color(0xFF0F172A); // Deep Navy
  static const Color _bgLight = Color(0xFFF5F5F7);
  static const Color _surfaceWhite = Colors.white;

  String _leaveType = 'Casual Leave'; // Default value matching dropdown options
  DateTime? _startDate;
  DateTime? _endDate;
  String _reason = '';
  bool _submitting = false;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
      _toast('Please select start & end date');
      return;
    }

    setState(() => _submitting = true);

    try {
      final leave = LeaveApplication(
        userId: widget.userId,
        appRole: widget.appRole,
        leaveType: _leaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        reason: _reason,
        status: 'Pending',
      );

      await _apiService.createLeaveApplication(leave);

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      _toast('Failed to submit leave: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Apply Leave'),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _leaveType,
                      items: const [
                        DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave')),
                        DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
                        DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _leaveType = v!),
                      decoration: const InputDecoration(
                        labelText: 'Leave Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined, color: _cardNavy),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Date
                    _buildDateTile(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                      formatter: df,
                    ),
                    
                    const SizedBox(height: 16),

                    // End Date
                    _buildDateTile(
                      label: 'End Date',
                      date: _endDate,
                      onTap: _startDate == null ? null : () => _pickDate(false),
                      formatter: df,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note, color: _cardNavy),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      onChanged: (v) => _reason = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: const Icon(Icons.calendar_month_rounded, color: _cardNavy),
        ),
        child: Text(
          date == null ? 'Select Date' : formatter.format(date),
          style: TextStyle(
            color: date == null ? Colors.grey.shade600 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}