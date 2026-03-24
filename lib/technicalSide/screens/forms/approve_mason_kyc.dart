// lib/technicalSide/screens/forms/approve_mason_kyc.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/mason_kyc_model.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/widgets/reusable_functions.dart';

class ApproveMasonKycScreen extends StatefulWidget {
  final Employee employee;
  const ApproveMasonKycScreen({super.key, required this.employee});

  @override
  State<ApproveMasonKycScreen> createState() => _ApproveMasonKycScreenState();
}

class _ApproveMasonKycScreenState extends State<ApproveMasonKycScreen> {
  final ApiService _api = ApiService();
  late Future<List<KycSubmission>> _submissionsFuture;
  bool _isProcessing = false;

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _surfaceWhite = Colors.white;
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _pendingOrange = Color(0xFFF59E0B);
  static const Color _inputFill = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    setState(() {
      _submissionsFuture = _fetchPendingKyc();
    });
  }

  Future<List<KycSubmission>> _fetchPendingKyc() async {
    try {
      final userId = int.tryParse(widget.employee.id);
      if (userId == null) return [];
      return await _api.fetchPendingKycSubmissions(userId: userId);
    } catch (e) {
      debugPrint("Error fetching KYC: $e");
      return [];
    }
  }

  // --- 🟢 DYNAMIC SERVER SEARCH ---
  Future<Dealer?> _showServerSearchDealerDialog() async {
    return await openDealerSearch(context);
  }

  // --- 🛡️ UPDATED: EDIT DIALOG (Safe from accidental close) ---
  void _showEditAndActionDialog(KycSubmission item) {
    final nameController = TextEditingController(text: item.mason?.name ?? '');
    final remarkController = TextEditingController();
    Dealer? selectedDealer;

    // Use StatefulBuilder to update the dialog UI (e.g. Dealer selection)
    showDialog(
      context: context,
      barrierDismissible: false, // 🔒 PREVENT ACCIDENTAL DISMISSAL
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: _surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Review & Edit Details",
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mason Name
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: _textDark),
                    decoration: _inputDecoration("Mason Name"),
                  ),
                  const SizedBox(height: 16),

                  // Dealer Selector
                  const Text(
                    "Assign/Change Dealer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () async {
                      // Open the dynamic search dialog
                      final result = await _showServerSearchDealerDialog();
                      if (result != null) {
                        setStateDialog(() => selectedDealer = result);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _cardNavy.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedDealer?.name ?? "Tap to Search Dealer...",
                              style: TextStyle(
                                color: selectedDealer != null
                                    ? _textDark
                                    : Colors.grey,
                                fontWeight: selectedDealer != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.search, color: _textDark),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Remarks
                  TextField(
                    controller: remarkController,
                    style: const TextStyle(color: _textDark),
                    decoration: _inputDecoration("TSO Remarks"),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    color: _textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processSubmission(
                    item.id,
                    'rejected',
                    remark: remarkController.text,
                  );
                },
                child: const Text(
                  "REJECT",
                  style: TextStyle(
                    color: _dangerRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  final updates = <String, dynamic>{
                    'name': nameController.text,
                    if (selectedDealer != null) 'dealerId': selectedDealer!.id,
                  };
                  _processSubmission(
                    item.id,
                    'approved',
                    remark: remarkController.text,
                    masonUpdates: updates,
                  );
                },
                child: const Text(
                  "SAVE & APPROVE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textGrey, fontSize: 13),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _cardNavy, width: 1),
      ),
    );
  }

  Future<void> _processSubmission(
    String id,
    String status, {
    String? remark,
    Map<String, dynamic>? masonUpdates,
  }) async {
    setState(() => _isProcessing = true);
    try {
      await _api.reviewKycSubmission(
        id,
        status,
        remark: remark,
        masonUpdates: masonUpdates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission $status successfully'),
            backgroundColor: status == 'approved' ? _accentGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textGrey,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Review KYC",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _textDark),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: FutureBuilder<List<KycSubmission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cardNavy),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: _dangerRed),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 40,
                      color: _textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending KYC submissions",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildKycCard(snapshot.data![index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildKycCard(KycSubmission item) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mason Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.mason?.name ?? "Unknown Mason",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.mason?.phoneNumber ?? "No Phone",
                        style: const TextStyle(color: _textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Text(
                    "PENDING",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _pendingOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ID Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.aadhaarNumber != null)
                  _detailRow("Aadhaar", item.aadhaarNumber!),
                if (item.panNumber != null) _detailRow("PAN", item.panNumber!),
                if (item.voterIdNumber != null)
                  _detailRow("Voter ID", item.voterIdNumber!),
                const SizedBox(height: 20),
                const Text(
                  "Submitted Documents",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDocumentsGrid(item.documents),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                label: const Text(
                  "REVIEW & EDIT DETAILS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () => _showEditAndActionDialog(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textGrey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(Map<String, dynamic> docs) {
    if (docs.isEmpty)
      return const Text(
        "No documents attached",
        style: TextStyle(fontStyle: FontStyle.italic, color: _textGrey),
      );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: docs.entries.map((entry) {
        String label = entry.key
            .replaceAll('Url', '')
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(0)}',
            )
            .trim();
        String url = entry.value.toString();

        return GestureDetector(
          onTap: () => _showFullImage(url, label),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  color: Colors.grey[50],
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFullImage(String url, String label) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CloseButton(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(child: Image.network(url)),
            ),
          ],
        ),
      ),
    );
  }
}
