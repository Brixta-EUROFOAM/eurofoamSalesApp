// lib/screens/forms/create_daily_task_form.dart
import 'dart:ui';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:salesmanapp/screens/forms/add_pjp_form.dart';

class CreateDailyTaskScreen extends StatefulWidget {
  final Employee employee;
  const CreateDailyTaskScreen({super.key, required this.employee});

  @override
  State<CreateDailyTaskScreen> createState() => _CreateDailyTaskScreenState();
}

class _CreateDailyTaskScreenState extends State<CreateDailyTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _siteNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  bool _isSubmitting = false;
  String? _selectedVisitType;
  Pjp? _selectedPjp;

  late Future<List<Pjp>> _pjpFuture;
  List<Pjp> _pjpList = [];

  // --- 🎨 FINTECH THEME PALETTE ---
  static const Color _surfaceWhite  = Colors.white;
  static const Color _cardNavy      = Color(0xFF0F172A); 
  static const Color _textDark      = Color(0xFF111827); 
  static const Color _textGrey      = Color(0xFF6B7280); 
  static const Color _inputFill     = Color(0xFFF9FAFB); 
  static const Color _accentOrange  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _fetchTodaysPjps();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchTodaysPjps() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          int.parse(widget.employee.id), 
          status: 'pending',
          startDate: today,
          endDate: today,
        );
        _pjpFuture.then((pjps) {
          if (mounted) {
            setState(() => _pjpList = pjps);
          }
        });
      });
    }
  }

  Future<void> _showAddPjpFormAndRefresh() async {
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPjpForm(
        employee: widget.employee,
        onPjpCreated: () {
          _fetchTodaysPjps();
        },
        theme: theme,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);

    try {
      String? relatedDealerId;
      if (_selectedVisitType == 'Dealer Visit' && _selectedPjp != null) {
        relatedDealerId = _selectedPjp!.dealerId; 
        if (relatedDealerId == null) {
           throw Exception('The selected PJP does not have a dealer linked to it.');
        }
      }

      final newTask = DailyTask(
        userId: int.parse(widget.employee.id),
        assignedByUserId: int.parse(widget.employee.id),
        taskDate: DateTime.now(),
        visitType: _selectedVisitType!,
        status: 'Assigned',
        pjpId: _selectedPjp?.id,
        relatedDealerId: relatedDealerId,
        siteName: _siteNameController.text.isNotEmpty ? _siteNameController.text : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      await _apiService.createDailyTask(newTask);

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Daily task created successfully!'),
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

  Widget _buildFintechInput({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Roboto'), 
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          validator: isRequired ? (v) => v!.isEmpty ? '$label is required' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardNavy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFintechDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Roboto'),
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
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
          items: items,
          onChanged: onChanged,
          validator: isRequired ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDealerVisit = _selectedVisitType == 'Dealer Visit';
    bool isSiteVisit = _selectedVisitType == 'Site Visit';

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
                    // --- Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create Daily Task',
                          style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textGrey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 30),

                    _buildFintechDropdown<String>(
                      label: 'Task Type',
                      value: _selectedVisitType,
                      items: ['Dealer Visit', 'Site Visit', 'Office Work', 'Follow-up']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedVisitType = value;
                        _selectedPjp = null; 
                      }),
                    ),
                    const SizedBox(height: 16),

                    // --- Conditional UI for Dealer Visit ---
                    if (isDealerVisit)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FutureBuilder<List<Pjp>>(
                            future: _pjpFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                              }

                              return _buildFintechDropdown<Pjp>(
                                label: 'Select Today\'s PJP',
                                value: _selectedPjp,
                                items: _pjpList.map((pjp) => DropdownMenuItem(
                                  value: pjp,
                                  child: Text(
                                    pjp.areaToBeVisited.split("|").first,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedPjp = value),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline, color: _accentOrange),
                            label: const Text('Create New PJP if not listed', style: TextStyle(color: _accentOrange, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _showAddPjpFormAndRefresh,
                          ),
                        ],
                      ),

                    // --- Conditional UI for Site Visit ---
                    if (isSiteVisit)
                      Column(
                        children: [
                          _buildFintechInput(
                            controller: _siteNameController,
                            label: 'Site Name',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    _buildFintechInput(
                      controller: _descriptionController,
                      label: 'Description',
                      isRequired: false,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SUBMIT TASK', style: TextStyle(fontWeight: FontWeight.bold)),
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