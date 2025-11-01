// lib/screens/employee_management/employee_pjp_screen.dart
import 'package:assetarchiverflutter/models/employee_model.dart';
// import 'package:assetarchiverflutter/widgets/reusableglasscard.dart'; // <-- REMOVED
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class EmployeePJPScreen extends StatefulWidget {
  final Employee employee;
  final Function(Map<String, dynamic> journeyData) onStartJourney;
  final VoidCallback onPjpCreated;

  const EmployeePJPScreen({
    super.key,
    required this.employee,
    required this.onStartJourney,
    required this.onPjpCreated,
  });

  @override
  State<EmployeePJPScreen> createState() => EmployeePJPScreenState();
}

class EmployeePJPScreenState extends State<EmployeePJPScreen> {
  // --- (All your logic is unchanged) ---
  final ApiService _apiService = ApiService();
  late Future<List<Pjp>> _pjpFuture;

  @override
  void initState() {
    super.initState();
    refreshPjpList();
  }

  void refreshPjpList() {
    if (mounted) {
      setState(() {
        _pjpFuture = _apiService.fetchPjpsForUser(int.parse(widget.employee.id), status: 'pending');
      });
    }
  }

  Future<void> _handleRefresh() async {
    final newPjpFuture = _apiService.fetchPjpsForUser(int.parse(widget.employee.id), status: 'pending');
    if (mounted) {
      setState(() {
        _pjpFuture = newPjpFuture;
      });
    }
    await newPjpFuture;
  }

  void _handlePjpCreation() {
    refreshPjpList();
    widget.onPjpCreated();
  }

  void _showAddPjpForm() {
    // --- ✅ THEME UPDATE: Get theme for the bottom sheet ---
    final theme = Theme.of(context);
    // --- END UPDATE ---

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPjpForm(
        employee: widget.employee,
        onPjpCreated: _handlePjpCreation,
        // --- ✅ THEME UPDATE: Pass the theme data down ---
        theme: theme,
      ),
    );
  }

  Future<void> _startJourneyForPjp(Pjp pjp) async {
    // ... (Your journey logic is unchanged) ...
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final parts = pjp.areaToBeVisited.split('|');
      if (parts.length != 3) throw const FormatException('Invalid PJP data format.');
      
      final String displayName = parts[0];
      final double? lat = double.tryParse(parts[1]);
      final double? lon = double.tryParse(parts[2]);

      if (lat == null || lon == null) throw const FormatException('Could not parse coordinates from PJP.');

      await _apiService.updatePjp(pjp.id, {'status': 'started'});
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Journey Planned, redirecting...'), backgroundColor: Colors.green));
      
      refreshPjpList();
      widget.onPjpCreated(); 
      
      widget.onStartJourney({
        'pjpId': pjp.id,
        'displayName': displayName,
        'destination': LatLng(lat, lon),
      });

    } catch (e) {
      debugPrint("Failed to start journey: $e");
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to start journey: PJP has invalid location data.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ✅ THEME UPDATE: Get theme colors ---
    final theme = Theme.of(context);
    // --- END UPDATE ---

    return Stack(
      children: [
        // --- ✅ THEME UPDATE: Removed Container + Gradient ---
        // The Scaffold from navscreen.dart provides the background color
        FutureBuilder<List<Pjp>>(
          future: _pjpFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              // --- ✅ THEME UPDATE ---
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }
            if (snapshot.hasError) {
              // --- ✅ THEME UPDATE ---
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: Stack(
                  children: [
                    ListView(),
                    Center(
                      child: Text(
                        'No PJPs to visit.', 
                        // --- ✅ THEME UPDATE ---
                        style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7))
                      )
                    ),
                  ],
                ),
              );
            }
            final pjpList = snapshot.data!;
            
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              // --- ✅ THEME UPDATE ---
              color: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView.builder(
                // Use the AppBar's height for top padding
                padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top, bottom: 80),
                itemCount: pjpList.length,
                itemBuilder: (context, index) {
                  final pjp = pjpList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Slidable(
                      key: ValueKey(pjp.id),
                      startActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _startJourneyForPjp(pjp),
                            // --- ✅ THEME UPDATE ---
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            // --- END UPDATE ---
                            icon: Icons.route,
                            label: 'Start Journey',
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                      child: _PjpCard(pjp: pjp),
                    ),
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          bottom: 120.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _showAddPjpForm,
            // --- ✅ THEME UPDATE ---
            // Style will come from app_theme.dart (elevatedButtonTheme)
            // or you can style it explicitly
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            // --- END UPDATE ---
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// --- ✅ THEME UPDATE: Replaced LiquidGlassCard with Card ---
class _PjpCard extends StatelessWidget {
  final Pjp pjp;
  const _PjpCard({required this.pjp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final displayName = pjp.areaToBeVisited.split('|').first;

    return Card( // <-- Replaced LiquidGlassCard
      // Card theme is applied from app_theme.dart
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                displayName,
                // --- ✅ THEME UPDATE ---
                style: textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.keyboard_arrow_right, 
              // --- ✅ THEME UPDATE ---
              color: theme.colorScheme.onSurface.withOpacity(0.7), 
              size: 30
            ),
          ],
        ),
      ),
    );
  }
}

// --- ✅ THEME UPDATE: Form is now theme-aware ---
class AddPjpForm extends StatefulWidget {
  final Employee employee;
  final VoidCallback onPjpCreated;
  final ThemeData theme; // <-- NEW: Receive theme from parent

  const AddPjpForm({
    super.key, 
    required this.employee, 
    required this.onPjpCreated,
    required this.theme, // <-- NEW
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
    _dealersFuture = _apiService.fetchDealers(userId: int.parse(widget.employee.id));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // ... (Your submit logic is unchanged) ...
    if (!_formKey.currentState!.validate() || _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a dealer.'), backgroundColor: Colors.orange));
      return;
    }
    
    final dealer = _selectedDealer!;
    if (dealer.latitude == null || dealer.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The selected dealer does not have location data saved.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final String displayName = '${dealer.name}, ${dealer.address}';
      final String visitData = '$displayName|${dealer.latitude}|${dealer.longitude}';

      final newPjp = Pjp(
        id: '',
        planDate: DateTime.now(),
        userId: int.parse(widget.employee.id),
        createdById: int.parse(widget.employee.id),
        status: 'pending',
        areaToBeVisited: visitData,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        dealerName: dealer.name, // NOTE: This field is now unused in your new schema
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // IMPORTANT: You'll need to update _apiService.createPjp to send 'dealerId'
      // For now, this will fail until the API service is updated
      await _apiService.createPjp(newPjp); 
      
      widget.onPjpCreated();
      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('PJP Created!'), backgroundColor: Colors.green));

    } catch (e) {
      debugPrint('--- FAILED TO CREATE PJP ---\nError: $e');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to create PJP: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ✅ THEME UPDATE: Get theme from widget property ---
    final theme = widget.theme;
    // --- END UPDATE ---
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        // --- ✅ THEME UPDATE ---
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        // --- END UPDATE ---
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New PJP', 
                // --- ✅ THEME UPDATE ---
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Dealer>>(
                future: _dealersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Text('Error loading dealers: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return Text('No dealers found for this user.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)));
                  
                  return DropdownButtonFormField<Dealer>(
                    // --- ✅ THEME UPDATE ---
                    hint: Text('Select a Dealer', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface, // Card color
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                    ),
                    // --- END UPDATE ---
                    items: snapshot.data!.map((dealer) => DropdownMenuItem(value: dealer, child: Text(dealer.name, overflow: TextOverflow.ellipsis,))).toList(),
                    onChanged: (value) => setState(() => _selectedDealer = value),
                    validator: (value) => value == null ? 'Please select a dealer' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                // --- ✅ THEME UPDATE ---
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                ),
                // --- END UPDATE ---
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                // --- ✅ THEME UPDATE ---
                // This will now use the style from app_theme.dart
                style: theme.elevatedButtonTheme.style?.copyWith(
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50))
                ),
                // --- END UPDATE ---
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('SUBMIT PJP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}