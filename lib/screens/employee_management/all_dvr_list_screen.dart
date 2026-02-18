// lib/screens/employee_management/all_dvr_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/models/daily_visit_report_model.dart';

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

  // Theme Colors
  final Color _bgLight = const Color(0xFFF5F5F7);
  final Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    // Note: ensure your api_service.dart actually implements fetchDvrsForUser
    // If it's currently throwing "Not Implemented", this will return empty
    _dvrFuture = _apiService.fetchDvrsForUser(
      widget.userId,
      startDate: widget.startDate,
      endDate: widget.endDate,
    ).then((data) {
      if (mounted) {
        setState(() {
          _allReports = data;
          _applyFilter();
        });
      }
      return data;
    }).catchError((e) {
      debugPrint("Error loading DVRs: $e");
      return <DailyVisitReport>[];
    });
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredReports = _allReports;
    } else {
      _filteredReports = _allReports.where((r) {
        // Filter based on dealerType from schema
        return r.dealerType.toLowerCase().contains(_selectedFilter.toLowerCase());
      }).toList();
    }
  }

  Color _getCategoryColor(String c) {
    c = c.toLowerCase();
    if (c.contains('dealer')) return Colors.blue.shade600;
    if (c.contains('sub')) return Colors.orange.shade600;
    if (c.contains('ihb') || c.contains('site')) return Colors.green.shade600;
    return Colors.purple.shade600; // Influencer/Other
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Daily Visit Reports"),
        backgroundColor: _surfaceWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<DailyVisitReport>>(
              future: _dvrFuture,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (_filteredReports.isEmpty) {
                   // Fallback if API returns empty
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                         const SizedBox(height: 16),
                         Text("No Reports Found", style: TextStyle(color: Colors.grey.shade500)),
                       ],
                     ),
                   );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildCard(_filteredReports[i]),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Adjust filters based on your common 'dealerType' values
    final filters = ['All', 'Dealer', 'Sub-Dealer']; 
    
    return Container(
      color: _surfaceWhite,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: _selectedFilter == f,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = f;
                    _applyFilter();
                  });
                }
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(DailyVisitReport r) {
    final type = r.dealerType;
    final color = _getCategoryColor(type);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(r.checkInTime);
    
    // Fallback logic for title
    String title = r.dealerName ?? r.subDealerName ?? 'Unknown Party';
    if (title.isEmpty) title = "Unknown Visit";

    return InkWell(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => DvrDetailScreen(report: r, color: color))
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(width: 6, height: 90, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(r.location, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    // Quick Stats Row
                    Row(
                      children: [
                         _miniStat(Icons.shopping_cart, "${r.todayOrderMt} MT"),
                         const SizedBox(width: 12),
                         _miniStat(Icons.currency_rupee, "${r.todayCollectionRupees}"),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
      ],
    );
  }
}

class DvrDetailScreen extends StatelessWidget {
  final DailyVisitReport report;
  final Color color;

  const DvrDetailScreen({super.key, required this.report, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("${report.dealerType} Visit"),
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
              _row("Date", DateFormat('dd MMM yyyy').format(report.reportDate)),
              _row("Check In", DateFormat('hh:mm a').format(report.checkInTime)),
              if (report.checkOutTime != null)
                _row("Check Out", DateFormat('hh:mm a').format(report.checkOutTime!)),
              _row("Visit Type", report.visitType),
              _row("Location", report.location),
            ]),

            const SizedBox(height: 20),
            _section("SALES METRICS"),
            _card([
               _row("Order (MT)", "${report.todayOrderMt}"),
               _row("Collection (₹)", "${report.todayCollectionRupees}"),
               if(report.overdueAmount != null)
                 _row("Overdue (₹)", "${report.overdueAmount}"),
               _row("Potential (Total/Best)", "${report.dealerTotalPotential} / ${report.dealerBestPotential}"),
            ]),

            const SizedBox(height: 20),
            _section("CONTACT & MARKET"),
            _card([
              if(report.contactPerson != null) _row("Contact", report.contactPerson!),
              if(report.contactPersonPhoneNo != null) _row("Phone", report.contactPersonPhoneNo!),
              _row("Brands Selling", report.brandSelling.join(', ')),
            ]),

            const SizedBox(height: 20),
            _section("FEEDBACK & REMARKS"),
            _card([
              _row("Feedback", report.feedbacks),
              if(report.solutionBySalesperson != null)
                _row("Solution", report.solutionBySalesperson!),
              if(report.anyRemarks != null)
                _row("Remarks", report.anyRemarks!),
            ]),

             const SizedBox(height: 20),
            _section("EVIDENCE"),
            _photos(),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 2))]),
    child: Column(children: children),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
      ],
    ),
  );

  Widget _photos() {
    final images = [
      if (report.inTimeImageUrl != null) {'Check-In': report.inTimeImageUrl!},
      if (report.outTimeImageUrl != null) {'Check-Out': report.outTimeImageUrl!},
    ];

    if (images.isEmpty) return const Text("No photos available", style: TextStyle(color: Colors.grey));

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_,__) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final map = images[i];
          final key = map.keys.first;
          final url = map.values.first;
          return Column(
            children: [
              Container(
                height: 110, width: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 4),
              Text(key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }
}