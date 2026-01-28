// lib/technicalSide/widgets/all_tvr_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _tvrFuture = _apiService.fetchTvrsForUser(
      widget.userId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      limit: 100,
    ).then((data) {
      _allReports = data;
      _applyFilter();
      return data;
    });
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
        return Colors.red.shade600;
      case 'IHB':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Technical Reports"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<TechnicalVisitReport>>(
              future: _tvrFuture,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_filteredReports.isEmpty) {
                  return const Center(child: Text("No Reports Found"));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _buildCard(_filteredReports[i]),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: ['All', 'IHB', 'Dealer', 'Influencer']
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) {
                      _selectedFilter = f;
                      _applyFilter();
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCard(TechnicalVisitReport r) {
    final cat = _getCategory(r);
    final color = _getCategoryColor(cat);
    final date =
        DateFormat('dd MMM').format(r.reportDate);

    final title = r.siteNameConcernedPerson.isNotEmpty
        ? r.siteNameConcernedPerson
        : r.associatedPartyName ??
            r.influencerName ??
            'Unknown Party';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TvrDetailScreen(report: r, category: cat, color: color),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    const SizedBox(height: 6),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${r.visitType} • ${r.region ?? ''}",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(date,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            )
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// DETAIL SCREEN — TSX PARITY
/// ----------------------------------------------------------------

class TvrDetailScreen extends StatelessWidget {
  final TechnicalVisitReport report;
  final String category;
  final Color color;

  const TvrDetailScreen({
    super.key,
    required this.report,
    required this.category,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final checkIn =
        DateFormat('hh:mm a').format(report.checkInTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("$category Visit"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("VISIT SUMMARY"),
            _card([
              _row("Party Name", report.siteNameConcernedPerson),
              _row("Visit Type", report.visitType),
              _row("Visit Category", report.visitCategory),
              _row("Check In", checkIn),
              _row("Location",
                  "${report.area ?? '-'}, ${report.region ?? '-'}"),
              _row("Address", report.siteAddress),
            ]),
            const SizedBox(height: 20),
            if (category == 'IHB') _ihb(),
            if (category == 'Dealer') _dealer(),
            if (category == 'Influencer') _influencer(),
            const SizedBox(height: 20),
            _section("REMARKS"),
            _card([
              _row("Remarks", report.salespersonRemarks),
            ]),
            const SizedBox(height: 20),
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
        const SizedBox(height: 16),
        _conversion(isDealer: false),
        if (report.isTechService == true) ...[
          const SizedBox(height: 16),
          _section("TECHNICAL SERVICES"),
          _card([
            _row("Service Given?", "YES"),
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
        const SizedBox(height: 16),
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
          _row("Preferred Brands",
              report.siteVisitBrandInUse.join(', ')),
          _row("Scheme Enrolled?",
              report.isSchemeEnrolled == true ? "YES" : "NO"),
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
          _row("Is Converted?", "YES"),
          if (!isDealer) _row("Conversion Type", report.conversionType),
          if (!isDealer) _row("From Brand", report.conversionFromBrand),
          _row(
            "Quantity",
            "${report.conversionQuantityValue ?? 0} ${report.conversionQuantityUnit ?? ''}",
          ),
          if (!isDealer)
            _row("Converted Dealer", report.nearbyDealerName),
          if (isDealer)
            _row("Rate per Bag", report.currentBrandPrice),
        ]),
      ],
    );
  }

  /// ---------------- HELPERS ----------------
  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey.shade700,
          ),
        ),
      );

  Widget _card(List<Widget> c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: c),
      );

  Widget _row(String l, dynamic v) {
    if (v == null || v.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(l,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500))),
          Expanded(
              child: Text(v.toString(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
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

    final valid = items.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .toList();

    if (valid.isEmpty) {
      return const Text("No Photos Available");
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: valid.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final e = valid[i];
          return Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(e.value!),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.black54,
                child: Text(e.key,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10)),
              ),
            ),
          );
        },
      ),
    );
  }
}
