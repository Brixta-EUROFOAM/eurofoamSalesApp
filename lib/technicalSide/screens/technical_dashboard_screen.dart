import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

// --- FORMS IMPORTS ---
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_tvr_form.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_kyc.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_rewards.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/add_site_form.dart'; 

class TechnicalDashboardScreen extends StatefulWidget {
  final Employee employee;

  const TechnicalDashboardScreen({
    super.key,
    required this.employee,
  });

  @override
  State<TechnicalDashboardScreen> createState() => _TechnicalDashboardScreenState();
}

class _TechnicalDashboardScreenState extends State<TechnicalDashboardScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  
  // --- NEW STATE VARIABLE ADDED HERE ---
  bool _isCheckedIn = false; // Tracks if user has checked in to toggle UI buttons

  String _greeting = 'Good Morning';

  // --- FINTECH THEME PALETTE ---
  final Color _bgLight       = const Color(0xFFF3F4F6); 
  final Color _cardNavy      = const Color(0xFF0F172A); 
  final Color _textDark      = const Color(0xFF111827); 
  final Color _textGrey      = const Color(0xFF6B7280); 
  final Color _surfaceWhite  = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {_greeting = 'Good Morning';}
    else if (hour < 17) {_greeting = 'Good Afternoon';}
    else {_greeting = 'Good Evening';};
  }
  
  Future<File?> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    return image == null ? null : File(image.path);
  }
  
  Future<Position?> _getCurrentPosition() async {
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return null;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleCheckIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingIn = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) { if(mounted) setState(() => _isCheckingIn = false); return; }
      final imageFile = await _captureImage();
      if (imageFile == null) { if(mounted) setState(() => _isCheckingIn = false); return; }
      
      final imageUrl = await _apiService.uploadImageToR2(imageFile);
      final checkInData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'locationName': 'Live Location',
        'inTimeLatitude': position.latitude,
        'inTimeLongitude': position.longitude,
        'inTimeImageUrl': imageUrl,
        'inTimeImageCaptured': true,
      };
      await _apiService.checkIn(checkInData);
      
      // --- UPDATE UI STATE ON SUCCESS ---
      if (mounted) {
        setState(() {
          _isCheckedIn = true; // Makes Check In inactive, Check Out active
        });
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Checked in successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }
  
  Future<void> _handleCheckOut() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingOut = true);
    try {
      final position = await _getCurrentPosition();
      if (position == null) { if(mounted) setState(() => _isCheckingOut = false); return; }
      final imageFile = await _captureImage();
      if (imageFile == null) { if(mounted) setState(() => _isCheckingOut = false); return; }
      
      final imageUrl = await _apiService.uploadImageToR2(imageFile);
      final checkOutData = {
        'userId': int.parse(widget.employee.id),
        'attendanceDate': DateTime.now().toIso8601String(),
        'outTimeImageUrl': imageUrl,
        'outTimeImageCaptured': true,
        'outTimeLatitude': position.latitude,
        'outTimeLongitude': position.longitude,
      };
      await _apiService.checkOut(checkOutData);

      // --- UPDATE UI STATE ON SUCCESS ---
      if (mounted) {
        setState(() {
          _isCheckedIn = false; // Resets the buttons for the next day/cycle
        });
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Checked out successfully!'), backgroundColor: Colors.blue));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() { _setGreeting(); });
  }

  void _openFullScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // ... [Action Sheet Methods remain exactly the same as your code] ...
  void _showMasonActions(BuildContext context) {
    // (Existing Code Hidden for Brevity)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mason Management", style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionSheetItem(
              icon: Icons.shopping_bag_outlined,
              title: "Approve Bag Lift",
              subtitle: "Verify pending cement bag lifts",
              iconBg: const Color(0xFFFFF7ED),
              iconColor: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(ApproveMasonBagLift(employee: widget.employee));
              },
            ),
            _buildActionSheetItem(
              icon: Icons.verified_user_outlined,
              title: "Approve KYC",
              subtitle: "Review pending Mason identities",
              iconBg: const Color(0xFFEFF6FF),
              iconColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(ApproveMasonKycScreen(employee: widget.employee));
              },
            ),
            _buildActionSheetItem(
              icon: Icons.card_giftcard,
              title: "Approve Rewards",
              subtitle: "Process gift redemption requests",
              iconBg: const Color(0xFFFAF5FF),
              iconColor: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(const ApproveMasonRewardsScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTechnicalActions(BuildContext context) {
     // (Existing Code Hidden for Brevity)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Technical Operations", 
              style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
             _buildActionSheetItem(
              icon: Icons.assignment_add,
              title: "Create TVR",
              subtitle: "Technical Visit Report Form",
              iconBg: const Color(0xFFF0FDF4),
              iconColor: Colors.green,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => CreateTvrScreen(employee: widget.employee),
                );
              },
            ),
            _buildActionSheetItem(
              icon: Icons.add_location_alt,
              title: "Register Site",
              subtitle: "Add a new construction site",
              iconBg: const Color(0xFFECFEFF),
              iconColor: Colors.cyan,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(AddSiteForm(employee: widget.employee));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userArea = "N/A";
    try { userArea = (widget.employee as dynamic).area ?? "N/A"; } catch (_) {}

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
         // (AppBar code remains exactly the same)
        backgroundColor: _bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: const NetworkImage("https://picsum.photos/200/300?grayscale"),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  widget.employee.displayName,
                  style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: const Icon(Icons.notifications_none, color: Colors.black87),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            
            // 1. HERO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardNavy,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _cardNavy.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Attendance Status",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                      const Icon(Icons.more_horiz, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Ready to Start", 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Area: $userArea',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // --- UPDATED GLASSMORPHISM BUTTONS ROW ---
                  Row(
                    children: [
                      // CHECK IN BUTTON
                      Expanded(
                        child: _buildGlassButton(
                          label: "CHECK IN",
                          icon: Icons.arrow_downward,
                          isLoading: _isCheckingIn,
                          // If NOT checked in, this is Active (White). If checked in, it becomes Inactive (Glass).
                          isActive: !_isCheckedIn, 
                          // If already checked in (or currently loading), disable click
                          onTap: (_isCheckedIn || _isCheckingIn || _isCheckingOut) 
                              ? null 
                              : _handleCheckIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // CHECK OUT BUTTON
                      Expanded(
                        child: _buildGlassButton(
                          label: "CHECK OUT",
                          icon: Icons.arrow_upward,
                          isLoading: _isCheckingOut,
                          // If Checked In, this becomes Active (White).
                          isActive: _isCheckedIn, 
                          // If NOT checked in (or currently loading), disable click
                          onTap: (!_isCheckedIn || _isCheckingIn || _isCheckingOut) 
                              ? null 
                              : _handleCheckOut,
                        ),
                      ),
                    ],
                  ),
                  // --- END UPDATED ROW ---

                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 2. OPERATIONS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories Of Work",
                  style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 3. FINTECH STYLE LIST ITEMS
            // Mason Operations
            _buildFintechCard(
              title: "Mason Management",
              subtitle: "Rewards, KYC, Bag Lifts",
              icon: Icons.handyman_outlined,
              iconColor: Colors.orange,
              iconBg: const Color(0xFFFFF7ED),
              actionText: "3 Actions",
              onTap: () => _showMasonActions(context),
            ),

            const SizedBox(height: 16),

            // Technical Operations
            _buildFintechCard(
              title: "Technical Ops",
              subtitle: "TVR, Site Registration",
              icon: Icons.architecture,
              iconColor: const Color(0xFF0F766E),
              iconBg: const Color(0xFFECFEFF),
              actionText: "2 Actions",
              onTap: () => _showTechnicalActions(context),
            ),
          ]
          .animate(interval: 50.ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // --- CUSTOM WIDGETS ---

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            // Logic: If active, White background. If inactive, Glass/Transparent background.
            color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: isLoading 
            ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: isActive ? _cardNavy : Colors.white, strokeWidth: 2)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: isActive ? _cardNavy : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? _cardNavy : Colors.white, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 12
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  // ... [Other Widgets remain unchanged] ...
  Widget _buildFintechCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          color: _textDark, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle, 
                        style: TextStyle(
                          color: _textGrey, 
                          fontSize: 13
                        )
                      ),
                    ],
                  ),
                ),
                Text(
                  actionText,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: _textGrey, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
    );
  }
}