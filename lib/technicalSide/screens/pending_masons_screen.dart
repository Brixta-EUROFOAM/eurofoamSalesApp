import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
// Import the form we will create in Step 2
import 'package:salesmanapp/technicalSide/screens/forms/submit_mason_kyc_form.dart';

class PendingMasonsScreen extends StatefulWidget {
  final Employee employee;
  const PendingMasonsScreen({super.key, required this.employee});

  @override
  State<PendingMasonsScreen> createState() => _PendingMasonsScreenState();
}

class _PendingMasonsScreenState extends State<PendingMasonsScreen> {
  final ApiService _api = ApiService();
  List<Mason> _pendingMasons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch masons with status 'pending_tso'
      final masons = await _api.fetchMasons(
        userId: int.parse(widget.employee.id),
        status: 'pending_tso', 
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _pendingMasons = masons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading pending masons: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("New Registrations", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      // 🟢 ADDED: Floating Action Button to Add NEW Mason
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          // 🚀 Navigate to Form with NULL mason (triggers "New Mason" mode)
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitMasonKycForm(mason: null, tsoId: widget.employee.id,),
            ),
          );
          
          // Refresh list if a new mason was added
          if (result == true) {
            setState(() => _isLoading = true);
            _loadData();
          }
        },
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingMasons.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingMasons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildMasonCard(_pendingMasons[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No new registrations found", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMasonCard(Mason mason) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            mason.name.isNotEmpty ? mason.name[0].toUpperCase() : "M",
            style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(mason.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(mason.phoneNumber, style: TextStyle(color: Colors.grey[600])),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            // Navigate to the KYC Form (Existing Mode)
            final bool? result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitMasonKycForm(mason: mason, tsoId: widget.employee.id,),
              ),
            );
            
            // Refresh list if registration was successful
            if (result == true) {
              setState(() => _isLoading = true);
              _loadData();
            }
          },
          child: const Text("DO KYC", style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }
}