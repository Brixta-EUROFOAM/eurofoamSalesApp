// lib/salesSide/screens/all_dvr_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/daily_visit_report_model.dart';

class AllDvrListScreen extends StatefulWidget {
  final int userId;
  final String? startDate;
  final String? endDate;

  const AllDvrListScreen({
    super.key,
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  State<AllDvrListScreen> createState() => _AllDvrListScreenState();
}

class _AllDvrListScreenState extends State<AllDvrListScreen> {
  late Future<List<DailyVisitReport>> _dvrFuture;
  final ApiService _apiService = ApiService();

  String _selectedFilter = 'All';
  List<DailyVisitReport> _allReports = [];
  List<DailyVisitReport> _filteredReports = [];

  // --- 🎨 PREMIUM THEME PALETTE ---
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _surfaceWhite = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _cardNavy = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _dvrFuture = _apiService
          .fetchDvrsForUser(
        widget.userId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      )
          .then((data) {
        _allReports = data;
        _applyFilter();
        return data;
      }).catchError((e) {
        debugPrint("Error loading DVRs: $e");
        return <DailyVisitReport>[];
      });
    });
  }

  Future<void> _handleRefresh() async {
    _loadReports();
    await _dvrFuture;
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredReports = _allReports;
    } else {
      _filteredReports = _allReports.where((r) {
        return r.dealerType.toLowerCase().contains(_selectedFilter.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  Color _getCategoryColor(String c) {
    c = c.toLowerCase();
    if (c.contains('dealer')) return Colors.blueAccent;
    if (c.contains('sub')) return Colors.orange;
    // if (c.contains('ihb') || c.contains('site')) return Colors.green;
    return Colors.purple; // Influencer/Other
  }

  IconData _getCategoryIcon(String c) {
    c = c.toLowerCase();
    if (c.contains('dealer')) return Icons.storefront_rounded;
    if (c.contains('sub')) return Icons.store_rounded;
    // if (c.contains('ihb') || c.contains('site')) return Icons.foundation_rounded;
    return Icons.people_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          "DVR Reports",
          style: TextStyle(
            color: _cardNavy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut),
        backgroundColor: _bgLight,
        iconTheme: const IconThemeData(color: _cardNavy),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _cardNavy,
              backgroundColor: Colors.white,
              child: FutureBuilder<List<DailyVisitReport>>(
                future: _dvrFuture,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _cardNavy));
                  }

                  if (_filteredReports.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      return _buildCard(_filteredReports[i])
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Dealer', 'Sub-Dealer',];

    return Container(
      color: _bgLight,
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(
                  f,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : _textGrey,
                  ),
                ),
                selected: isSelected,
                selectedColor: _cardNavy,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: isSelected ? _cardNavy : Colors.grey.shade300),
                onSelected: (selected) {
                  if (selected) {
                    _selectedFilter = f;
                    _applyFilter();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                    BoxShadow(color: _cardNavy.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Icon(Icons.assignment_outlined, size: 48, color: _textGrey.withOpacity(0.5)),
              ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack, duration: 600.ms),
              const SizedBox(height: 32),
              const Text(
                "No Reports Found",
                style: TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 20),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "Try changing your filter.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DailyVisitReport r) {
    final type = r.dealerType;
    final color = _getCategoryColor(type);
    final icon = _getCategoryIcon(type);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(r.checkInTime);

    String title = 'Unknown Party';
    if (r.dealerName != null && r.dealerName!.isNotEmpty) {
      title = r.dealerName!;
    } else if (r.subDealerName != null && r.subDealerName!.isNotEmpty) {
      title = r.subDealerName!;
    } else if (r.nameOfParty != null && r.nameOfParty!.isNotEmpty) {
      title = r.nameOfParty!;
    }

    if (title.isEmpty) title = "Unknown Visit";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DvrDetailScreen(report: r, color: color, icon: icon)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _cardNavy.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✨ SQUIRCLE AVATAR
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textGrey.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: _textGrey, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.location,
                          style: const TextStyle(fontSize: 13, color: _textGrey, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Premium Stat Pills
                  Row(
                    children: [
                      _miniStatPill(Icons.shopping_cart_rounded, "${r.todayOrderMt} MT"),
                      const SizedBox(width: 8),
                      _miniStatPill(Icons.account_balance_wallet_rounded, "₹${r.todayCollectionRupees}"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(color: _bgLight, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: _cardNavy, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _textGrey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark)),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// DETAIL SCREEN — PREMIUM UI PARITY
/// ----------------------------------------------------------------
class DvrDetailScreen extends StatelessWidget {
  final DailyVisitReport report;
  final Color color;
  final IconData icon;

  const DvrDetailScreen({super.key, required this.report, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final checkIn = DateFormat('hh:mm a').format(report.checkInTime);
    String title = report.dealerName ?? report.subDealerName ?? 'Unknown Party';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${report.dealerType} Visit"),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(report.location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _section("VISIT SUMMARY"),
            _card([
              _row(Icons.calendar_today_rounded, "Date", DateFormat('dd MMM yyyy').format(report.reportDate)),
              _row(Icons.login_rounded, "Check In", checkIn),
              if (report.checkOutTime != null)
                _row(Icons.logout_rounded, "Check Out", DateFormat('hh:mm a').format(report.checkOutTime!)),
              _row(Icons.merge_type_rounded, "Visit Type", report.visitType),
            ]),
            const SizedBox(height: 24),

            _section("DVR METRICS"),
            _card([
              _row(Icons.shopping_cart_rounded, "Order (MT)", "${report.todayOrderMt}"),
              _row(Icons.account_balance_wallet_rounded, "Collection (₹)", "${report.todayCollectionRupees}"),
              if (report.overdueAmount != null && report.overdueAmount! > 0)
                _row(Icons.warning_amber_rounded, "Overdue (₹)", "${report.overdueAmount}", valueColor: Colors.redAccent),
              _row(Icons.trending_up_rounded, "Potential (Total/Best)", "${report.dealerTotalPotential} / ${report.dealerBestPotential}"),
            ]),
            const SizedBox(height: 24),

            _section("CONTACT & MARKET"),
            _card([
              if (report.contactPerson != null) _row(Icons.person_rounded, "Contact", report.contactPerson!),
              if (report.contactPersonPhoneNo != null) _row(Icons.phone_rounded, "Phone", report.contactPersonPhoneNo!),
              _row(Icons.branding_watermark_rounded, "Brands Selling", report.brandSelling.join(', ')),
            ]),
            const SizedBox(height: 24),

            _section("FEEDBACK & REMARKS"),
            _card([
              _row(Icons.feedback_rounded, "Feedback", report.feedbacks),
              if (report.solutionBySalesperson != null && report.solutionBySalesperson!.isNotEmpty)
                _row(Icons.lightbulb_rounded, "Solution", report.solutionBySalesperson!),
              if (report.anyRemarks != null && report.anyRemarks!.isNotEmpty)
                _row(Icons.notes_rounded, "Remarks", report.anyRemarks!),
            ]),
            const SizedBox(height: 24),

            _section("EVIDENCE"),
            _photos(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.2),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(children: children),
      );

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photos() {
    final images = [
      if (report.inTimeImageUrl != null) {'Check-In': report.inTimeImageUrl!},
      if (report.outTimeImageUrl != null) {'Check-Out': report.outTimeImageUrl!},
    ];

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text("No photos available", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final map = images[i];
          final key = map.keys.first;
          final url = map.values.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          );
        },
      ),
    );
  }
}