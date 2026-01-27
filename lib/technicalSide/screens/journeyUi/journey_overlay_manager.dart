import 'package:flutter/material.dart';
import 'active_journey_hud.dart';

class JourneyOverlayManager extends StatelessWidget {
  final bool isJourneyActive;
  final Widget idlePanel;
  final String distance;
  final Future<void> Function() onStop;
  final VoidCallback onNavigate; // Accepts the navigation logic

  const JourneyOverlayManager({
    super.key,
    required this.isJourneyActive,
    required this.idlePanel,
    required this.distance,
    required this.onStop,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      // Bouncier curve for more "physics" feel
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isHud = child.key == const ValueKey("ActiveHUD");
        
        // HUD drops from Top (-0.6), Idle Panel rises from Bottom (1.0)
        final Offset beginOffset = isHud 
            ? const Offset(0, -0.6) 
            : const Offset(0, 1.0);

        return SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isJourneyActive
          ? ActiveJourneyHUD(
              key: const ValueKey("ActiveHUD"),
              distance: distance,
              onStop: onStop,
              onNavigate: onNavigate,
            )
          : Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                key: const ValueKey("IdlePanel"),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                // ✨ UPGRADED: Premium Card Look
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32), // More rounded
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.15), // Navy shadow
                      blurRadius: 40, // Very soft, wide blur
                      spreadRadius: -5,
                      offset: const Offset(0, 15), // Deep lift
                    )
                  ],
                ),
                child: idlePanel, 
              ),
            ),
    );
  }
}