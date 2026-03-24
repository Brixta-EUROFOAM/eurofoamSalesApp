// lib/technicalSide/screens/pending_masons_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 🔥 ADDED FOR PREMIUM ANIMATIONS
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';
import 'package:salesmanapp/technicalSide/screens/forms/submit_mason_kyc_form.dart';

class PendingMasonsScreen extends StatefulWidget {
  final Employee employee;
  const PendingMasonsScreen({super.key, required this.employee});

  @override
  State<PendingMasonsScreen> createState() => _PendingMasonsScreenState();
}

class _PendingMasonsScreenState extends State<PendingMasonsScreen> {
  final ApiService _api = ApiService();
  List<Mason> _pendingMasons = [];
  bool _isLoading = true;

  // --- 🎨 PREMIUM THEME PALETTE ---
  final Color _bgLight = const Color(0xFFF8FAFC);
  final Color _cardNavy = const Color(0xFF0F172A);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textGrey = const Color(0xFF64748B);
  final Color _surfaceWhite = Colors.white;
  final Color _accentBlue = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final masons = await _api.fetchMasons(
        userId: int.parse(widget.employee.id),
        status: 'pending_tso',
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _pendingMasons = masons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading pending masons: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: _cardNavy),
        toolbarHeight: 70,
        title:
            Text(
                  "New Registrations",
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
      ),

      // 🟢 ADDED: Animated Floating Action Button
      floatingActionButton:
          FloatingActionButton.extended(
                backgroundColor: _cardNavy,
                elevation: 8,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  "Add New",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () async {
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmitMasonKycForm(
                        mason: null,
                        tsoId: widget.employee.id,
                      ),
                    ),
                  );

                  if (result == true) {
                    setState(() => _isLoading = true);
                    _loadData();
                  }
                },
              )
              .animate()
              .scale(delay: 400.ms, curve: Curves.easeOutBack, duration: 500.ms)
              .then()
              .shimmer(duration: 2500.ms, color: Colors.white24)
              .animate(onPlay: (c) => c.repeat()),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: _cardNavy,
        backgroundColor: Colors.white,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _cardNavy))
            : _pendingMasons.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  100,
                ), // Extra bottom padding for FAB
                itemCount: _pendingMasons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  // ✨ STAGGERED LIST ANIMATION
                  return _buildMasonCard(_pendingMasons[index])
                      .animate(delay: (index * 50).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        physics:
            const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh even when empty
        children: [
          Column(
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
                  Icons.person_search_rounded,
                  size: 48,
                  color: _textGrey.withOpacity(0.5),
                ),
              ).animate().scale(
                delay: 200.ms,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              Text(
                    "No Pending KYC",
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "You're all caught up for now.",
                style: TextStyle(color: _textGrey, fontSize: 15),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasonCard(Mason mason) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardNavy.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _cardNavy.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // ✨ SQUIRCLE AVATAR
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Light blue tint
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  mason.name.isNotEmpty ? mason.name[0].toUpperCase() : "M",
                  style: TextStyle(
                    color: _accentBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ✨ MASON DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mason.name,
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, color: _textGrey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        mason.phoneNumber,
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✨ STYLED ACTION BUTTON
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cardNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmitMasonKycForm(
                      mason: mason,
                      tsoId: widget.employee.id,
                    ),
                  ),
                );

                if (result == true) {
                  setState(() => _isLoading = true);
                  _loadData();
                }
              },
              child: const Text(
                "DO KYC",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
