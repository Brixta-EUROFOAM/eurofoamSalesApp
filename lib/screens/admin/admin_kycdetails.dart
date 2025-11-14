import 'dart:convert';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:flutter/material.dart';

class AdminKycDetailScreen extends StatefulWidget {
  final Map<String, dynamic> submission;
  const AdminKycDetailScreen({super.key, required this.submission});

  @override
  State<AdminKycDetailScreen> createState() => _AdminKycDetailScreenState();
}

class _AdminKycDetailScreenState extends State<AdminKycDetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // Documents can be a JSON string or a Map.
  // This state variable will hold the parsed Map.
  late final Map<String, dynamic> documents;

  @override
  void initState() {
    super.initState();
    
    // Safely parse the 'documents' field
    var docData = widget.submission['documents'];
    if (docData is String) {
      try {
        documents = jsonDecode(docData);
      } catch (e) {
        documents = {}; // Default to empty map on parse error
      }
    } else if (docData is Map) {
      documents = docData.cast<String, dynamic>();
    } else {
      documents = {}; // Default if null or wrong type
    }
  }


  Future<void> _reviewSubmission(String status) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Call the API to update the submission status
      await _api.reviewKycSubmission(widget.submission['id'], status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission ${status.toLowerCase()}'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        // Pop the screen and return 'true' to signal a refresh
        // to the AdminDashboard.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely access the nested mason object
    final mason = widget.submission['mason'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Review KYC: ${mason['name'] ?? ''}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(mason),
            const SizedBox(height: 16),
            _buildDocumentsCard(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reviewSubmission('rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reviewSubmission('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> mason) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contractor Details', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _InfoRow(label: 'Name', value: mason['name'] ?? 'N/A'),
            _InfoRow(label: 'Phone', value: mason['phoneNumber'] ?? 'N/A'),
            _InfoRow(label: 'KYC Status', value: widget.submission['status'] ?? 'N/A',
              valueColor: widget.submission['status'] == 'pending' ? Colors.orange : Colors.black,
            ),
            _InfoRow(label: 'Aadhaar', value: widget.submission['aadhaarNumber'] ?? 'N/A'),
            _InfoRow(label: 'PAN', value: widget.submission['panNumber'] ?? 'N/A'),
            _InfoRow(label: 'Voter ID', value: widget.submission['voterIdNumber'] ?? 'N/A'),
            _InfoRow(label: 'Remark', value: widget.submission['remark'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submitted Documents', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            if (documents.isEmpty)
              const Center(child: Text('No documents were uploaded.')),
            // Dynamically show images based on keys in the documents map
            if (documents.containsKey('aadhaarFrontUrl'))
              _ImageRow(label: 'Aadhaar Front', url: documents['aadhaarFrontUrl']),
            if (documents.containsKey('aadhaarBackUrl'))
              _ImageRow(label: 'Aadhaar Back', url: documents['aadhaarBackUrl']),
            if (documents.containsKey('panUrl'))
              _ImageRow(label: 'PAN Card', url: documents['panUrl']),
            if (documents.containsKey('voterUrl'))
              _ImageRow(label: 'Voter ID', url: documents['voterUrl']),
          ],
        ),
      ),
    );
  }
}

// Helper widget for a clean "Label: Value" row
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}

// Helper widget to display an image from a URL
class _ImageRow extends StatelessWidget {
  final String label;
  final String url;
  const _ImageRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Use Image.network to load the image from your server/R2
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Could not load image'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}