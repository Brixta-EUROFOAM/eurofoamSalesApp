// lib/technicalSide/widgets/all_tvr_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/technicalSide/models/technical_visit_report_model.dart';

class UserTvrListScreen extends StatefulWidget {
  final int userId;
  final String? startDate;
  final String? endDate;

  const UserTvrListScreen({
    super.key,
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  State<UserTvrListScreen> createState() => _UserTvrListScreenState();
}

class _UserTvrListScreenState extends State<UserTvrListScreen> {
  late Future<List<TechnicalVisitReport>> _tvrFuture;
  final ApiService _apiService = ApiService();

  String _selectedFilter = 'All';
  List<TechnicalVisitReport> _allReports = [];
  List<TechnicalVisitReport> _filteredReports = [];

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
      _tvrFuture = _apiService
          .fetchTvrsForUser(
        widget.userId,
        startDate: widget.startDate,
        endDate: widget.endDate,
        limit: 100,
      )
          .then((data) {
        _allReports = data;
        _applyFilter();
        return data;
      }).catchError((e) {
        debugPrint("Error loading TVRs: $e");
        return <TechnicalVisitReport>[];
      });
    });
  }

  Future<void> _handleRefresh() async {
    _loadReports();
    await _tvrFuture;
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredReports = _allReports;
    } else {
      _filteredReports = _allReports.where((r) {
        final type = _getCategory(r);
        return type == _selectedFilter;
      }).toList();
    }
    setState(() {});
  }

  String _getCategory(TechnicalVisitReport r) {
    final c = r.customerType ?? '';
    if (c.contains('Dealer') || c.contains('Partner')) return 'Dealer';
    if (c.contains('IHB') || c.contains('Site')) return 'IHB';
    return 'Influencer';
  }

  Color _getCategoryColor(String c) {
    switch (c) {
      case 'Dealer':
        return Colors.redAccent;
      case 'IHB':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getCategoryIcon(String c) {
    switch (c) {
      case 'Dealer':
        return Icons.storefront_rounded;
      case 'IHB':
        return Icons.foundation_rounded;
      default:
        return Icons.people_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          "Technical Reports",
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
              child: FutureBuilder<List<TechnicalVisitReport>>(
                future: _tvrFuture,
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
    final filters = ['All', 'IHB', 'Dealer', 'Influencer'];

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

  Widget _buildCard(TechnicalVisitReport r) {
    final cat = _getCategory(r);
    final color = _getCategoryColor(cat);
    final icon = _getCategoryIcon(cat);
    final date = DateFormat('dd MMM, hh:mm a').format(r.reportDate);

    final title = r.siteNameConcernedPerson.isNotEmpty
        ? r.siteNameConcernedPerson
        : r.associatedPartyName ?? r.influencerName ?? 'Unknown Party';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TvrDetailScreen(report: r, category: cat, color: color, icon: icon),
        ),
      ),
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
                          cat.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                        ),
                      ),
                      Text(
                        date,
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
                          "${r.visitType} • ${r.region ?? ''}",
                          style: const TextStyle(fontSize: 13, color: _textGrey, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
}

/// ----------------------------------------------------------------
/// DETAIL SCREEN — PREMIUM UI PARITY
/// ----------------------------------------------------------------

class TvrDetailScreen extends StatelessWidget {
  final TechnicalVisitReport report;
  final String category;
  final Color color;
  final IconData icon;

  const TvrDetailScreen({
    super.key,
    required this.report,
    required this.category,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final checkIn = DateFormat('hh:mm a').format(report.checkInTime);
    
    final title = report.siteNameConcernedPerson.isNotEmpty
        ? report.siteNameConcernedPerson
        : report.associatedPartyName ?? report.influencerName ?? 'Unknown Party';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "$category Visit",
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
        ),
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
                      Text("${report.area ?? '-'}, ${report.region ?? '-'}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _section("VISIT SUMMARY"),
            _card([
              _row("Party Name", report.siteNameConcernedPerson),
              _row("Visit Type", report.visitType),
              _row("Visit Category", report.visitCategory),
              _row("Check In", checkIn),
              _row("Address", report.siteAddress),
            ]),
            const SizedBox(height: 24),
            
            if (category == 'IHB') _ihb(),
            if (category == 'Dealer') _dealer(),
            if (category == 'Influencer') _influencer(),
            
            const SizedBox(height: 24),
            _section("REMARKS"),
            _card([
              _row("Remarks", report.salespersonRemarks),
            ]),
            const SizedBox(height: 24),
            
            _section("PHOTO EVIDENCE"),
            _photos(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ---------------- IHB ----------------
  Widget _ihb() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section("CONSTRUCTION SITE ANALYSIS"),
        _card([
          _row("Stage", report.siteVisitStage),
          _row("Area (SqFt)", report.constAreaSqFt),
          _row("Site Stock", report.siteStock),
          _row("Est. Requirement", report.estRequirement),
          _row("Brands In Use", report.siteVisitBrandInUse.join(', ')),
          _row("Market Name", report.marketName),
          _row("Supplying Dealer", report.supplyingDealerName),
        ]),
        const SizedBox(height: 24),
        _conversion(isDealer: false),
        if (report.isTechService == true) ...[
          const SizedBox(height: 24),
          _section("TECHNICAL SERVICES"),
          _card([
            _row("Service Given?", "YES", valueColor: Colors.green),
            _row("Type of Tech Service", report.serviceType),
            _row("Description", report.serviceDesc),
          ])
        ]
      ],
    );
  }

  /// ---------------- DEALER ----------------
  Widget _dealer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section("DEALER & SALES LOGIC"),
        _card([
          _row("Productivity", report.influencerProductivity),
          _row("Brands Selling", report.siteVisitBrandInUse.join(', ')),
        ]),
        const SizedBox(height: 24),
        _conversion(isDealer: true),
      ],
    );
  }

  /// ---------------- INFLUENCER ----------------
  Widget _influencer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section("INFLUENCER / PROFESSIONAL INFO"),
        _card([
          _row("Type", report.influencerType.join(', ')),
          _row("Phone", report.influencerPhone),
          _row("Productivity Score", report.influencerProductivity),
          _row("Preferred Brands", report.siteVisitBrandInUse.join(', ')),
          _row("Scheme Enrolled?", report.isSchemeEnrolled == true ? "YES" : "NO", valueColor: report.isSchemeEnrolled == true ? Colors.green : Colors.redAccent),
        ]),
      ],
    );
  }

  /// ---------------- CONVERSION ----------------
  Widget _conversion({required bool isDealer}) {
    if (report.isConverted != true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section("CONVERSION STATUS"),
        _card([
          _row("Is Converted?", "YES", valueColor: Colors.green),
          if (!isDealer) _row("Conversion Type", report.conversionType),
          if (!isDealer) _row("From Brand", report.conversionFromBrand),
          _row("Quantity", "${report.conversionQuantityValue ?? 0} ${report.conversionQuantityUnit ?? ''}"),
          if (!isDealer) _row("Converted Dealer", report.nearbyDealerName),
          if (isDealer) _row("Rate per Bag", report.currentBrandPrice),
        ]),
      ],
    );
  }

  /// ---------------- HELPERS ----------------
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

  Widget _row(String label, dynamic value, {Color? valueColor}) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photos() {
    final items = {
      "Site / Shop": report.sitePhotoUrl,
      "Check-In": report.inTimeImageUrl,
      "Check-Out": report.outTimeImageUrl,
    };

    final valid = items.entries.where((e) => e.value != null && e.value!.isNotEmpty).toList();

    if (valid.isEmpty) {
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
        itemCount: valid.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final e = valid[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  image: DecorationImage(image: NetworkImage(e.value!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          );
        },
      ),
    );
  }
}