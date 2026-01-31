// lib/technicalSide/screens/all_masons_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; 
import 'package:qr_flutter/qr_flutter.dart'; // ✅ Added for QR
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_baglift_model.dart';

class AllMasonsScreen extends StatefulWidget {
  final Employee employee;
  const AllMasonsScreen({super.key, required this.employee});

  @override
  State<AllMasonsScreen> createState() => _AllMasonsScreenState();
}

class _AllMasonsScreenState extends State<AllMasonsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Mason> _allMasons = [];
  List<Mason> _filteredMasons = [];
  bool _isLoading = true;

  // --- Theme Colors ---
  static const Color _bgLight = Color(0xFFF3F4F6);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _accentOrange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _loadMasons();
  }

  // --- 1. FETCH MASONS ---
  Future<void> _loadMasons() async {
    final rawId = widget.employee.id;
    final numericId = rawId.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final masons = await _api.fetchMasons(
        userId: int.parse(numericId),
        limit: 300,
      );

      if (mounted) {
        setState(() {
          _allMasons = masons;
          _filteredMasons = masons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading masons: $e");
    }
  }

  void _filterMasons(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredMasons = _allMasons.where((mason) {
        return mason.name.toLowerCase().contains(lowerQuery) ||
            mason.phoneNumber.contains(lowerQuery);
      }).toList();
    });
  }

  // --- 2. HISTORY POPUP LOGIC ---
  Future<List<MasonBagLift>>? _historyFuture;

  void _showHistoryPopup(BuildContext context, Mason mason) {
    _historyFuture = _api.fetchMasonBagLiftHistory(mason.id);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgLight,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: const BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mason.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 6), 
                      GestureDetector(
                        onTap: () async {
                          if (mason.phoneNumber.isEmpty) return;
                          await Clipboard.setData(ClipboardData(text: mason.phoneNumber));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Copied: ${mason.phoneNumber}"),
                                backgroundColor: _cardNavy,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, size: 12, color: _textGrey),
                            const SizedBox(width: 4),
                            Text(
                              mason.phoneNumber.isNotEmpty ? mason.phoneNumber : "No Phone",
                              style: const TextStyle(fontSize: 13, color: _textGrey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            if (mason.phoneNumber.isNotEmpty)
                              const Icon(Icons.copy_rounded, size: 16, color: Colors.blueAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text("Bag Lift History", style: TextStyle(fontSize: 12, color: _textGrey)),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: _bgLight, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: _textGrey),
                    ),
                  ),
                ],
              ),
            ),

            // List Area
            Container(
              height: 450,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<MasonBagLift>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _cardNavy));
                  }
                  if (snapshot.hasError || (snapshot.data == null || snapshot.data!.isEmpty)) {
                    return _buildEmptyHistoryState();
                  }

                  final history = snapshot.data!;
                  history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: history.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _buildHistoryCard(history[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text("No history found", style: TextStyle(color: _textGrey)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(MasonBagLift lift) {
    Color statusColor = Colors.orange;
    String statusText = "PENDING";

    if (lift.status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusText = "APPROVED";
    } else if (lift.status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusText = "REJECTED";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_bag, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${lift.bagCount} Bags",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14),
                ),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(lift.createdAt),
                  style: const TextStyle(color: _textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lift.pointsCredited != null && lift.pointsCredited! > 0)
                Text(
                  "+${lift.pointsCredited}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _accentOrange, fontSize: 14),
                ),
              Text(
                statusText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
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
        title: const Text("Linked Masons", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: _textDark),
              decoration: InputDecoration(
                hintText: 'Search for a name...',
                hintStyle: const TextStyle(color: _textGrey),
                prefixIcon: const Icon(Icons.search, color: _textGrey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: _filterMasons,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _cardNavy))
                : _filteredMasons.isEmpty
                ? Center(child: Text("No masons found", style: TextStyle(color: _textGrey.withOpacity(0.7))))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredMasons.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildMasonCard(_filteredMasons[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasonCard(Mason mason) {
    // ✅ Check Credentials
    final creds = mason.credentials;
    final hasCredentials = creds != null;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. TAPPABLE AREA (Shows History)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showHistoryPopup(context, mason),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(24),
                bottom: hasCredentials ? Radius.zero : const Radius.circular(24),
              ),
              enableFeedback: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        mason.name.isNotEmpty ? mason.name[0].toUpperCase() : "M",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _cardNavy, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mason.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatText("Bags Lifted", (mason.bagsLifted ?? 0).toString()),
                              const SizedBox(width: 24),
                              _buildStatText("Points", mason.pointsBalance.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: _textDark, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // 2. ✅ ACTION BAR (View QR) - Only shows if credentials exist
          if (hasCredentials)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _MasonQrDialog(
                      masonName: mason.name,
                      userId: creds['userId']!,
                      password: creds['password']!,
                      qrData: creds['qrData']!,
                    ),
                  );
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code, size: 18, color: _cardNavy),
                      SizedBox(width: 8),
                      Text("VIEW LOGIN QR", style: TextStyle(color: _cardNavy, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: "$label: ", style: const TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
          TextSpan(text: value, style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🟢 INTERNAL DIALOG CLASS (Fixed Layout)
// -----------------------------------------------------------------------------
class _MasonQrDialog extends StatelessWidget {
  final String masonName;
  final String userId;
  final String password;
  final String qrData;

  const _MasonQrDialog({
    required this.masonName,
    required this.userId,
    required this.password,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // ✅ FIX: Constrain width to avoid "intrinsic dimensions" error
      content: SizedBox(
        width: double.maxFinite, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text("Mason Login Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(masonName, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 200.0),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _row("User ID", userId),
                    const Divider(),
                    _row("Password", password),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Scan this to login", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1, color: Colors.black87)),
      ],
    );
  }
}