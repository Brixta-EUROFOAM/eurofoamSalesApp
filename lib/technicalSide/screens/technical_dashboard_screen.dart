import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

// --- EXISTING IMPORTS ---
import 'package:assetarchiverflutter/technicalSide/screens/forms/create_tvr_form.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/add_site_form.dart';

// --- NEW IMPORTS (Ensure these paths match your project structure) ---
// If you haven't created these files yet, create them and paste the code you provided.
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_kyc.dart';
import 'package:assetarchiverflutter/technicalSide/screens/forms/approve_mason_rewards.dart';
// import 'package:assetarchiverflutter/technicalSide/screens/forms/add_site_form.dart'; // <--- UNCOMMENT WHEN FILE EXISTS

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
  String _greeting = 'Good Morning';

  // Theme Constants (Moved here so they can be accessed by bottom sheets if needed)
  final Color _scaffoldBg        = const Color(0xFF020617);
  final Color _cardGradientStart = const Color(0xFF0B4AA8);
  final Color _cardGradientEnd   = const Color(0xFF111827);
  final Color _secondaryColor    = const Color(0xFFFFA000);
  final Color _surfaceDark       = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setGreeting();
  }

  // --- Attendance & Location Logic (UNCHANGED) ---
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

  // --- NAVIGATION HELPERS ---
  void _openFullScreen(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // --- 1. MASON ACTION SHEET ---
  void _showMasonActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mason Management", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionSheetItem(
              icon: Icons.shopping_bag_outlined,
              title: "Approve Bag Lift",
              subtitle: "Verify pending cement bag lifts",
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(ApproveMasonBagLift(employee: widget.employee));
              },
            ),
            _buildActionSheetItem(
              icon: Icons.verified_user_outlined,
              title: "Approve KYC",
              subtitle: "Review pending Mason identities",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _openFullScreen(ApproveMasonKycScreen(employee: widget.employee));
              },
            ),
            _buildActionSheetItem(
              icon: Icons.card_giftcard,
              title: "Approve Rewards",
              subtitle: "Process gift redemption requests",
              color: Colors.purple,
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

  // --- 2. TECHNICAL ACTION SHEET ---
  void _showTechnicalActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Technical Operations", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             _buildActionSheetItem(
              icon: Icons.assignment_add,
              title: "Create TVR",
              subtitle: "Technical Visit Report Form",
              color: Colors.green,
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
              color: Colors.cyan,
              onTap: () {
                Navigator.pop(context);
                // Navigates to the AddSiteForm, passing the current employee
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
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _scaffoldBg,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'DASHBOARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: _secondaryColor,
        backgroundColor: _surfaceDark,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. GREETING CARD (HERO)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_cardGradientStart, _cardGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              child: const Icon(Icons.engineering, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _greeting,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Technical',
                            style: TextStyle(
                              color: Colors.black, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 11
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.employee.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Area: $userArea',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 2. ATTENDANCE BUTTONS
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceButton(
                    label: 'CHECK IN',
                    icon: Icons.login,
                    isLoading: _isCheckingIn,
                    onTap: _isCheckingIn || _isCheckingOut ? null : _handleCheckIn,
                    bgColor: _secondaryColor, 
                    textColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttendanceButton(
                    label: 'CHECK OUT',
                    icon: Icons.logout,
                    isLoading: _isCheckingOut,
                    onTap: _isCheckingIn || _isCheckingOut ? null : _handleCheckOut,
                    bgColor: _surfaceDark, 
                    textColor: Colors.white, 
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            // 3. QUICK ACTIONS HEADER
            const Text(
              "QUICK ACTIONS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // 4. NEW SPLIT ACTION BUTTONS (MASON | TECHNICAL)
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    title: "MASON",
                    icon: Icons.handyman,
                    color1: const Color(0xFFC2410C), // Orange-Red
                    color2: const Color(0xFF7C2D12),
                    onTap: () => _showMasonActions(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCategoryCard(
                    title: "TECHNICAL",
                    icon: Icons.architecture,
                    color1: const Color(0xFF0F766E), // Teal
                    color2: const Color(0xFF134E4A),
                    onTap: () => _showTechnicalActions(context),
                  ),
                ),
              ],
            ),
          ]
          .animate(interval: 50.ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onTap,
    required Color bgColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        elevation: 0,
      ),
      child: isLoading 
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
    );
  }

  // Large square card for main categories (Mason/Technical)
  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140, // Square-ish aspect ratio
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 14
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // List tile for Bottom Sheet items
  Widget _buildActionSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
    );
  }
}