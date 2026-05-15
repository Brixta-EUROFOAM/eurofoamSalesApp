// lib/screens/views/dvr_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../api/api_service.dart';
import '../../models/dvr_model.dart';
import '../forms/dvrFormComponents/dvr_constants.dart';

class DvrListScreen extends StatefulWidget {
  const DvrListScreen({Key? key}) : super(key: key);

  @override
  State<DvrListScreen> createState() => _DvrListScreenState();
}

class _DvrListScreenState extends State<DvrListScreen> {
  late Future<List<DvrModel>> _dvrFuture;
  final ApiService _apiService = ApiService();

  String _selectedFilter = 'All';
  List<DvrModel> _allReports = [];
  List<DvrModel> _filteredReports = [];

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
          .getDailyVisitReports()
          .then((data) {
            _allReports = data;
            _applyFilter();
            return data;
          })
          .catchError((e) {
            debugPrint("Error loading DVRs: $e");
            return <DvrModel>[];
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
        return r.dealerType?.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
    setState(() {});
  }

  Color _getCategoryColor(String? c) {
    if (c == null) return Colors.purple;
    if (c.contains('Eurofoam')) return Colors.blueAccent;
    if (c.contains('Non Eurofoam')) return Colors.orange;
    return Colors.purple;
  }

  IconData _getCategoryIcon(String? c) {
    if (c == null) return Icons.people_alt_rounded;
    if (c.contains('Eurofoam')) return Icons.storefront_rounded;
    if (c.contains('Non Eurofoam')) return Icons.store_rounded;
    return Icons.people_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title:
            const Text(
                  "DVR Reports",
                  style: TextStyle(
                    color: _cardNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, curve: Curves.easeOut),
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
              child: FutureBuilder<List<DvrModel>>(
                future: _dvrFuture,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _cardNavy),
                    );
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Merge 'All' with the options from your DvrConstants
    final filters = ['All', ...DvrConstants.dealerTypes];

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                  color: isSelected ? _cardNavy : Colors.grey.shade300,
                ),
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
                    BoxShadow(
                      color: _cardNavy.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.assignment_outlined,
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
                    "No Reports Found",
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
                "Try changing your filter.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DvrModel r) {
    final type = r.dealerType ?? 'Unknown Type';
    final color = _getCategoryColor(type);
    final icon = _getCategoryIcon(type);

    // Safely format the date
    final dateStr = r.checkInTime != null
        ? DateFormat('dd MMM, hh:mm a').format(r.checkInTime!)
        : (r.reportDate != null
              ? DateFormat('dd MMM yyyy').format(r.reportDate!)
              : 'No Date');

    String title = r.nameOfParty ?? 'Unknown Party';
    if (title.isEmpty) title = "Unknown Visit";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DvrDetailScreen(report: r, color: color, icon: icon),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _cardNavy.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          dateStr,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textGrey.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _textGrey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.location ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniStatPill(
                        Icons.shopping_cart_rounded,
                        "${r.todayOrderQty ?? 0} KG",
                      ),
                      _miniStatPill(
                        Icons.account_balance_wallet_rounded,
                        "₹${r.todayCollectionRupees ?? 0}",
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------
/// DETAIL SCREEN — PREMIUM UI PARITY
/// ----------------------------------------------------------------
class DvrDetailScreen extends StatelessWidget {
  final DvrModel report;
  final Color color;
  final IconData icon;

  const DvrDetailScreen({
    super.key,
    required this.report,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final checkIn = report.checkInTime != null
        ? DateFormat('hh:mm a').format(report.checkInTime!)
        : 'N/A';
    String title = report.nameOfParty ?? 'Unknown Party';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${report.dealerType ?? 'Visit'} Report"),
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
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.location ?? 'No location provided',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _section("VISIT SUMMARY"),
            _card([
              if (report.reportDate != null)
                _row(
                  Icons.calendar_today_rounded,
                  "Date",
                  DateFormat('dd MMM yyyy').format(report.reportDate!),
                ),
              _row(Icons.login_rounded, "Check In", checkIn),
              if (report.checkOutTime != null)
                _row(
                  Icons.logout_rounded,
                  "Check Out",
                  DateFormat('hh:mm a').format(report.checkOutTime!),
                ),
              if (report.visitType != null)
                _row(Icons.merge_type_rounded, "Visit Type", report.visitType!),
            ]),
            const SizedBox(height: 24),

            _section("DVR METRICS"),
            _card([
              _row(
                Icons.shopping_cart_rounded,
                "Order",
                "${report.todayOrderQty ?? 0} MT/KG",
              ),
              _row(
                Icons.account_balance_wallet_rounded,
                "Collection",
                "₹${report.todayCollectionRupees ?? 0}",
              ),
              if (report.overdueAmount != null && report.overdueAmount! > 0)
                _row(
                  Icons.warning_amber_rounded,
                  "Overdue",
                  "₹${report.overdueAmount}",
                  valueColor: Colors.redAccent,
                ),
              if (report.expectedActivationDate != null)
                _row(
                  Icons.rocket_launch_rounded,
                  "Exp. Activation",
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(report.expectedActivationDate!),
                ),
            ]),
            const SizedBox(height: 24),

            _section("CONTACT & MARKET"),
            _card([
              if (report.contactNoOfParty != null)
                _row(Icons.phone_rounded, "Phone", report.contactNoOfParty!),
              if (report.brandSelling != null &&
                  report.brandSelling!.isNotEmpty)
                _row(
                  Icons.branding_watermark_rounded,
                  "Brands Selling",
                  report.brandSelling!.join(', '),
                ),
            ]),
            const SizedBox(height: 24),

            if (report.feedbacks != null && report.feedbacks!.isNotEmpty) ...[
              _section("FEEDBACK & REMARKS"),
              _card([
                _row(Icons.feedback_rounded, "Feedback", report.feedbacks!),
              ]),
              const SizedBox(height: 24),
            ],

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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photos() {
    final images = [
      if (report.inTimeImageUrl != null) {'Check-In': report.inTimeImageUrl!},
      if (report.outTimeImageUrl != null)
        {'Check-Out': report.outTimeImageUrl!},
    ];

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "No photos available",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      height: 175,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
