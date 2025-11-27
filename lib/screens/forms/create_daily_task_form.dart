import 'dart:ui';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_task_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
// import 'package:salesmanapp/models/dealer_model.dart'; // <-- 1. REMOVED (Unused)
import 'package:salesmanapp/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- ✅ FIX: Import the form from its new, correct location ---
import 'package:salesmanapp/screens/forms/add_pjp_form.dart';
// --- END FIX ---

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
    // Fetch only PJPs that are pending for today
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(
          // Your Employee.id is a String, the API needs an int
          int.parse(widget.employee.id), 
          status: 'pending',
          startDate: today,
          endDate: today,
        );
        // Store the result for easy access
        _pjpFuture.then((pjps) {
          if (mounted) {
            setState(() => _pjpList = pjps);
          }
        });
      });
    }
  }

Future<void> _showAddPjpFormAndRefresh() async {
    // This function is now correct and matches your PJP screen
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
      // --- This logic is now correct ---
      // We just pass the dealerId directly from the PJP.
      String? relatedDealerId;
      if (_selectedVisitType == 'Dealer Visit' && _selectedPjp != null) {
        relatedDealerId = _selectedPjp!.dealerId; 
        
        if (relatedDealerId == null) {
           throw Exception('The selected PJP does not have a dealer linked to it.');
        }
      }

      final newTask = DailyTask(
        userId: int.parse(widget.employee.id),
        assignedByUserId: int.parse(
          widget.employee.id,
        ), // User assigns to themselves
        taskDate: DateTime.now(),
        visitType: _selectedVisitType!,
        status: 'Assigned',
        pjpId: _selectedPjp?.id,
        relatedDealerId: relatedDealerId,
        siteName: _siteNameController.text.isNotEmpty
            ? _siteNameController.text
            : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      await _apiService.createDailyTask(newTask);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Daily task created successfully!'),
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
  
  InputDecoration _inputDecoration(String label, {bool isRequired = true}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: '$label${isRequired ? '*' : ''}',
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.secondary),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDealerVisit = _selectedVisitType == 'Dealer Visit';
    bool isSiteVisit = _selectedVisitType == 'Site Visit';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create Daily Task',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onSurface,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        Divider(color: theme.colorScheme.onSurface.withOpacity(0.2), height: 30),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedVisitType,
                          dropdownColor: theme.colorScheme.surface,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: _inputDecoration('Task Type'),
                          items:
                              [
                                    'Dealer Visit',
                                    'Site Visit',
                                    'Office Work',
                                    'Follow-up',
                                  ]
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) => setState(() {
                            _selectedVisitType = value;
                            _selectedPjp =
                                null; 
                          }),
                          validator: (v) =>
                              v == null ? 'Please select a task type' : null,
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Text(
                                      'Could not load PJPs: ${snapshot.error}',
                                      style: TextStyle(color: theme.colorScheme.error),
                                    );
                                  }

                                  return DropdownButtonFormField<Pjp>(
                                    hint: Text(
                                      'Select Today\'s PJP',
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                    ),
                                    initialValue: _selectedPjp,
                                    isExpanded: true,
                                    dropdownColor: theme.colorScheme.surface,
                                    style: TextStyle(color: theme.colorScheme.onSurface),
                                    decoration: _inputDecoration('PJP'),
                                    items: _pjpList
                                        .map(
                                          (pjp) => DropdownMenuItem(
                                            value: pjp,
                                            child: Text(
                                              // --- ✅ 2. THE FIX ---
                                              // We only use the areaToBeVisited string,
                                              // which we know contains the dealer's name.
                                              pjp.areaToBeVisited.split("|").first,
                                              // --- END FIX ---
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedPjp = value),
                                    validator: (v) => v == null
                                        ? 'Please select a PJP'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: Icon(
                                  Icons.add,
                                  color: theme.colorScheme.secondary, // Orange
                                ),
                                label: Text(
                                  'Create New PJP if not listed',
                                  style: TextStyle(color: theme.colorScheme.secondary),
                                ),
                                onPressed: _showAddPjpFormAndRefresh,
                              ),
                            ],
                          ),

                        // --- Conditional UI for Site Visit ---
                        if (isSiteVisit)
                          TextFormField(
                            controller: _siteNameController,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: _inputDecoration('Site Name'),
                            validator: (v) =>
                                v!.isEmpty ? 'Site name is required' : null,
                          ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: _inputDecoration(
                            'Description',
                            isRequired: false,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50))
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onSecondary, // Black
                                  ),
                                )
                              : const Text(
                                  'SUBMIT TASK',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}