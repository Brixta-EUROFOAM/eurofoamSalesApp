// lib/screens/forms/approve_mason_bagLift.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/mason_baglift_model.dart';

class ApproveMasonBagLift extends StatefulWidget {
  const ApproveMasonBagLift({super.key});

  @override
  State<ApproveMasonBagLift> createState() => _ApproveMasonBagLiftState();
}

class _ApproveMasonBagLiftState extends State<ApproveMasonBagLift> {
  final ApiService _api = ApiService();
  late Future<List<MasonBagLift>> _futureLifts;
  
  // Added loading state for actions
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureLifts = _api.fetchPendingBagLifts().then((data) {
        return data.cast<MasonBagLift>().toList();
      });
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // ✅ FIX: Now actually using the _api instance
      await _api.updateBagLiftStatus(id, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Marked as $status"),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadData(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmAction(String id, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${status.toUpperCase()} Request?"),
        content: const Text("Are you sure you want to proceed? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, status);
            },
            child: Text(status.toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Bag Lifts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: FutureBuilder<List<MasonBagLift>>(
        future: _futureLifts,
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
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No pending bag lifts", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildBagLiftCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildBagLiftCard(MasonBagLift item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Icons.shopping_bag, color: Colors.orange),
            ),
            title: Text(
              item.masonName ?? "Unknown Mason",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Requested: ${item.createdAt.toLocal().toString().split('.')[0]}"),
            trailing: Text(
              "${item.bagCount} Bags",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          if (item.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(item.imageUrl!),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        Text("Image not available", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, "rejected"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("APPROVE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, "approved"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Proof of Purchase"),
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