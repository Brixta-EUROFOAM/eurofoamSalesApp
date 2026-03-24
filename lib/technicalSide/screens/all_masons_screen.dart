// lib/technicalSide/screens/all_masons_screen.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
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

  // 🚀 O(1) CPU THROTTLING: Prevents search loops from locking the UI
  Timer? _debounce;

  List<Mason> _allMasons = [];
  List<Mason> _filteredMasons = [];
  bool _isLoading = true;

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _accentBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadMasons();
  }

  // 🚀 SPACE COMPLEXITY: Plug memory leaks
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _loadMasons();
    // Re-apply search if it exists
    if (_searchController.text.isNotEmpty) {
      _filterMasons(_searchController.text);
    }
  }

  // 🚀 BATTERY/CPU OPTIMIZATION: Debounce search input
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterMasons(query);
    });
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
      builder: (context) =>
          Dialog(
            backgroundColor: _bgLight,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: const BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mason.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _textDark,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                if (mason.phoneNumber.isEmpty) return;
                                await Clipboard.setData(
                                  ClipboardData(text: mason.phoneNumber),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Copied: ${mason.phoneNumber}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _cardNavy,
                                      duration: const Duration(seconds: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 12,
                                    color: _textGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mason.phoneNumber.isNotEmpty
                                        ? mason.phoneNumber
                                        : "No Phone",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (mason.phoneNumber.isNotEmpty)
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: _accentBlue,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _cardNavy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "BAG LIFT HISTORY",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _cardNavy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: _cardNavy,
                          ),
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
                        return const Center(
                          child: CircularProgressIndicator(color: _cardNavy),
                        );
                      }
                      if (snapshot.hasError ||
                          (snapshot.data == null || snapshot.data!.isEmpty)) {
                        return _buildEmptyHistoryState();
                      }

                      final history = snapshot.data!;
                      history.sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      );

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: history.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildHistoryCard(history[i])
                            .animate()
                            .fadeIn(delay: (i * 30).ms)
                            .slideY(begin: 0.1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate().scale(
            curve: Curves.easeOutBack,
            duration: 400.ms,
          ), // ✨ POPUP ANIMATION
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _cardNavy.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 40,
              color: _textGrey,
            ),
          ).animate().scale(curve: Curves.easeOutBack, delay: 200.ms),
          const SizedBox(height: 16),
          const Text(
            "No history found",
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms),
          const Text(
            "This mason hasn't lifted any bags yet.",
            style: TextStyle(color: _textGrey, fontSize: 13),
          ).animate().fadeIn(delay: 400.ms),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${lift.bagCount} Bags",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(lift.createdAt),
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _accentOrange,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
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
        backgroundColor: _surfaceWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _cardNavy),
        toolbarHeight: 70,
        title:
            const Text(
                  "Linked Masons",
                  style: TextStyle(
                    color: _cardNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOut),
      ),
      body: Column(
        children: [
          Container(
            color: _surfaceWhite,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: const TextStyle(
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: _textGrey),
                filled: true,
                fillColor: _bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: _onSearchChanged, // 🚀 Trigger debounced search
            ),
          ).animate().slideY(
            begin: -0.5,
            curve: Curves.easeOutCubic,
          ), // Search bar drop-in

          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _cardNavy),
                    )
                  : _filteredMasons.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: _filteredMasons.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        // ✨ STAGGERED LIST ANIMATION
                        return _buildMasonCard(_filteredMasons[index])
                            .animate(delay: (index * 40).ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOut);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.group_off_rounded,
                  size: 48,
                  color: _textGrey.withOpacity(0.5),
                ),
              ).animate().scale(
                delay: 100.ms,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              const Text(
                    "No Masons Found",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? "You haven't linked any masons yet."
                    : "No results match your search.",
                style: const TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasonCard(Mason mason) {
    final creds = mason.credentials;
    final hasCredentials = creds != null;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _cardNavy.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showHistoryPopup(context, mason),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(24),
                bottom: hasCredentials
                    ? Radius.zero
                    : const Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          mason.name.isNotEmpty
                              ? mason.name[0].toUpperCase()
                              : "M",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _accentBlue,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mason.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatText(
                                "Lifts",
                                (mason.bagsLifted ?? 0).toString(),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _textGrey.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildStatText(
                                "Pts",
                                mason.pointsBalance.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 36,
                      decoration: const BoxDecoration(
                        color: _bgLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _cardNavy,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

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
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 18, color: _cardNavy),
                      SizedBox(width: 8),
                      Text(
                        "VIEW LOGIN QR",
                        style: TextStyle(
                          color: _cardNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
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
          TextSpan(
            text: "$label: ",
            style: const TextStyle(
              color: _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🟢 INTERNAL DIALOG CLASS (Fixed Layout & Animated)
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Mason Login",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                masonName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  color: Colors.white,
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _row("User ID", userId),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _row("Password", password),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Scan this QR to login to the Mason App",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              "CLOSE",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    ).animate().scale(
      curve: Curves.easeOutBack,
      duration: 400.ms,
    ); // ✨ POPUP ANIMATION
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        SelectableText(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.5,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
