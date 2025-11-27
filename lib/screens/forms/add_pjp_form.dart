import 'package:flutter/material.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'dart:developer' as dev;

const _log = 'AddPjpForm';

class AddPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;
  final ThemeData theme;
  const AddPjpForm({
    super.key,
    required this.employee,
    required this.onPjpCreated,
    required this.theme,
  });
  @override
  State<AddPjpForm> createState() => AddPjpFormState();
}

class AddPjpFormState extends State<AddPjpForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  Dealer? _selectedDealer;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  late Future<List<Dealer>> _dealersFuture;

  @override
  void initState() {
    super.initState();
    dev.log('AddPjpForm.initState → load dealers for user ${widget.employee.id}', name: _log);
    _dealersFuture =
        _apiService.fetchDealers(userId: int.parse(widget.employee.id));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.orange));
      dev.log('Submit blocked: form invalid or dealer null', name: _log);
      return;
    }
    final dealer = _selectedDealer!;
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The selected dealer does not have location data saved.'),
          backgroundColor: Colors.orange));
      dev.log('Submit blocked: dealer lacks lat/lon (dealerId=${dealer.id})', name: _log);
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final String displayName = '${dealer.name}, ${dealer.address}';
      final String visitData =
          '$displayName|${dealer.latitude}|${dealer.longitude}';

      // --- ✅ THIS IS THE FIX ---
      // We now correctly set BOTH status fields as per your schema.
      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        
        // This is the JOURNEY status (pending, started, completed)
        status: 'PENDING', 
        
        // This is the ADMIN APPROVAL status (PENDING, VERIFIED)
        verificationStatus: 'PENDING', 

        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        dealerId: dealer.id,
        dealerName: dealer.name, // Good to include this for the model
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // --- END FIX ---

      dev.log('CREATE PJP → payload: ${newPjp.toJson()}', name: _log);

      final sw = Stopwatch()..start();
      final created = await _apiService.createPjp(newPjp);
      sw.stop();

      dev.log(
        'CREATE PJP ← success in ${sw.elapsedMilliseconds}ms (id=${created.id}, status=${created.status}, verificationStatus=${created.verificationStatus})',
        name: _log,
      );

      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('PJP Created!'), backgroundColor: Colors.green));
    } catch (e, st) {
      dev.log('CREATE PJP ← ERROR', name: _log, error: e, stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create PJP: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New PJP',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              FutureBuilder<List<Dealer>>(
                future: _dealersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error loading dealers: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No dealers found for this user.',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)));
                  }
                  return DropdownButtonFormField<Dealer>(
                    hint: Text('Select a Dealer',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7))),
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: snapshot.data!
                        .map((dealer) => DropdownMenuItem(
                            value: dealer,
                            child: Text(
                              dealer.name,
                              overflow: TextOverflow.ellipsis,
                            )))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDealer = value),
                    validator: (value) =>
                        value == null ? 'Please select a dealer' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: theme.elevatedButtonTheme.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                        const Size(double.infinity, 50))),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('SUBMIT PJP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}