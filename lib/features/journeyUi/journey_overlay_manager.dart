import 'dart:ui';
import 'package:flutter/material.dart';
import 'active_journey_hud.dart';

class JourneyOverlayManager extends StatelessWidget {
  final bool isJourneyActive;
  final Widget idlePanel;
  final String distance;
  final Future<void> Function() onStop;
  final VoidCallback onNavigate;

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
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isHud = child.key == const ValueKey("ActiveHUD");

        // ✨ THE FIX: Since ActiveJourneyHUD has its own internal staggered slide animations,
        // we ONLY fade it here. This prevents "double-sliding" visual glitches.
        if (isHud) {
          return FadeTransition(opacity: animation, child: child);
        }

        // ✨ For the Idle Panel, we give it a buttery slide up from the bottom
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5), // Slide from slightly below
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuint,
                reverseCurve: Curves.easeInQuint,
              ),
            );

        return SlideTransition(
          position: slideAnimation,
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
              key: const ValueKey("IdlePanel"),
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                // ✨ UPGRADED: Premium Glassmorphism (Frosted Glass Blur)
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.85,
                        ), // Slight transparency for the blur to bleed through
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.6,
                          ), // Subtle rim light to define the edge
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.12),
                            blurRadius: 40,
                            spreadRadius: -5,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: idlePanel,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
