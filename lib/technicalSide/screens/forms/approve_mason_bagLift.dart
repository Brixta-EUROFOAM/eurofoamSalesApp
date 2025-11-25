// lib/screens/forms/approve_mason_bagLift.dart
import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/technicalSide/models/mason_baglift_model.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';

class ApproveMasonBagLift extends StatefulWidget {
  final Employee employee;
  const ApproveMasonBagLift({super.key, required this.employee});

  @override
  State<ApproveMasonBagLift> createState() => _ApproveMasonBagLiftState();
}

class _ApproveMasonBagLiftState extends State<ApproveMasonBagLift> {
  final ApiService _api = ApiService();
  late Future<List<MasonBagLift>> _futureLifts;
  
  bool _isProcessing = false;

  // --- FINTECH THEME PALETTE ---
  static const Color _bgLight       = Color(0xFFF3F4F6); // Corporate Grey
  static const Color _surfaceWhite  = Colors.white;
  static const Color _textDark      = Color(0xFF111827); // Navy/Black
  static const Color _textGrey      = Color(0xFF6B7280); // Subtitle Grey
  static const Color _cardNavy      = Color(0xFF0F172A); // Deep Navy
  static const Color _accentGreen   = Color(0xFF10B981); 
  static const Color _dangerRed     = Color(0xFFEF4444);
  static const Color _infoBlue      = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      final userId = int.tryParse(widget.employee.id);
      _futureLifts = _api.fetchPendingBagLifts(userId: userId);
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _api.updateBagLiftStatus(id, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Marked as $status"),
            backgroundColor: status == 'approved' ? _accentGreen : _dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: _dangerRed),
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
        backgroundColor: _surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "${status.toUpperCase()} REQUEST?",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark),
        ),
        content: Text(
          "Are you sure you want to proceed? This action cannot be undone.",
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: _textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? _accentGreen : _dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, status);
            },
            child: Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pending Bag Lifts",
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
            onPressed: _loadData,
          )
        ],
      ),
      body: FutureBuilder<List<MasonBagLift>>(
        future: _futureLifts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cardNavy));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: _dangerRed)));
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
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 40, color: _textGrey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pending bag lifts", 
                    style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  const SizedBox(height: 4),
                  const Text("You're all caught up!", style: TextStyle(color: _textGrey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
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
    final dateStr = item.createdAt.toLocal().toString().split('.')[0];
    
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // 1. Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF7ED), // Light Orange
                  child: const Icon(Icons.shopping_bag, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.masonName ?? "Unknown Mason",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: _textDark,
                          fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Light Blue
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${item.bagCount} Bags",
                    style: const TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w700, 
                      color: _infoBlue
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // 2. Image Section (if available)
          if (item.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullImage(item.imageUrl!),
              child: Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
          // 3. Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, "rejected"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _dangerRed,
                      side: const BorderSide(color: _dangerRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _confirmAction(item.id, "approved"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const CloseButton(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}