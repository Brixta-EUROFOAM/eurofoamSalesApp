// lib/screens/forms/add_site_form.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/sites_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';

class AddSiteForm extends StatefulWidget {
  final Employee employee;
  const AddSiteForm({super.key, required this.employee});

  @override
  State<AddSiteForm> createState() => _AddSiteFormState();
}

class _AddSiteFormState extends State<AddSiteForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controllers
  final _siteNameController = TextEditingController();
  final _concernedPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedStage;
  String? _selectedType;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  Position? _currentPosition;

  final List<String> _stages = ['Foundation', 'Plinth', 'Lintel', 'Roofing', 'Finishing'];
  final List<String> _types = ['Residential', 'Commercial', 'Government', 'Industrial'];

  Future<void> _getLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _addressController.text = "Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location is required")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final site = TechnicalSite(
        siteName: _siteNameController.text,
        concernedPerson: _concernedPersonController.text,
        phoneNo: _phoneController.text,
        address: _addressController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        siteType: _selectedType,
        stageOfConstruction: _selectedStage,
        area: widget.employee.area, 
        region: widget.employee.region,
        constructionStartDate: DateTime.now(),
      );

      // ✅ FIX: This line is now uncommented and uses the 'site' variable
      await _apiService.createTechnicalSite(site);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site Registered Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register New Site")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _siteNameController,
                decoration: const InputDecoration(labelText: "Site Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _concernedPersonController,
                decoration: const InputDecoration(labelText: "Concerned Person", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? "Invalid Phone" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Site Type", border: OutlineInputBorder()),
                items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStage,
                decoration: const InputDecoration(labelText: "Construction Stage", border: OutlineInputBorder()),
                items: _stages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedStage = v),
              ),
              const SizedBox(height: 24),
              
              // Location Block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Site Location", style: TextStyle(fontWeight: FontWeight.bold)),
                        if (_isFetchingLocation) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else IconButton(icon: const Icon(Icons.my_location, color: Colors.blue), onPressed: _getLocation),
                      ],
                    ),
                    if (_currentPosition != null)
                      Text("Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}", style: TextStyle(color: Colors.green[700])),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Address / Landmark", border: UnderlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTER SITE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}