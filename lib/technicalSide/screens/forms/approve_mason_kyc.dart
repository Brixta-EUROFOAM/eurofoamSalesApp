// lib/screens/forms/approve_mason_kyc.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/mason_kyc_model.dart';

class ApproveMasonKycScreen extends StatefulWidget {
  const ApproveMasonKycScreen({super.key});

  @override
  State<ApproveMasonKycScreen> createState() => _ApproveMasonKycScreenState();
}

class _ApproveMasonKycScreenState extends State<ApproveMasonKycScreen> {
  final ApiService _api = ApiService();
  late Future<List<KycSubmission>> _submissionsFuture;
  bool _isProcessing = false;

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
      // ✅ FIX: The API now returns List<KycSubmission>, so we return it directly.
      // No need to map it again.
      return await _api.fetchPendingKycSubmissions();
    } catch (e) {
      debugPrint("Error fetching KYC: $e");
      return []; // Return empty on error for now
    }
  }

  Future<void> _processSubmission(String id, String status, [String? remark]) async {
    setState(() => _isProcessing = true);
    try {
      await _api.reviewKycSubmission(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission $status successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadSubmissions(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog(String id) {
    final remarkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Submission"),
        content: TextField(
          controller: remarkController,
          decoration: const InputDecoration(
            labelText: "Reason for rejection",
            hintText: "e.g., Blurred image, invalid ID",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _processSubmission(id, 'rejected', remarkController.text);
            },
            child: const Text("REJECT"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review KYC"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          )
        ],
      ),
      body: FutureBuilder<List<KycSubmission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No pending KYC submissions", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildKycCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildKycCard(KycSubmission item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mason Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.mason?.name ?? "Unknown Mason",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.mason?.phoneNumber ?? "No Phone",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("PENDING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                )
              ],
            ),
          ),

          // ID Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (item.aadhaarNumber != null) _detailRow("Aadhaar", item.aadhaarNumber!),
                if (item.panNumber != null) _detailRow("PAN", item.panNumber!),
                if (item.voterIdNumber != null) _detailRow("Voter ID", item.voterIdNumber!),
                const Divider(height: 24),
                
                // Documents Section
                const Text("Submitted Documents:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDocumentsGrid(item.documents),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _isProcessing ? null : () => _showRejectDialog(item.id),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("APPROVE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isProcessing ? null : () => _processSubmission(item.id, 'approved'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(Map<String, dynamic> docs) {
    if (docs.isEmpty) return const Text("No documents attached", style: TextStyle(fontStyle: FontStyle.italic));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: docs.entries.map((entry) {
        String label = entry.key.replaceAll('Url', '').replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}').trim();
        String url = entry.value.toString();

        return GestureDetector(
          onTap: () => _showFullImage(url, label),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label),
              leading: const CloseButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            InteractiveViewer(
              child: Image.network(url),
            ),
          ],
        ),
      ),
    );
  }
}