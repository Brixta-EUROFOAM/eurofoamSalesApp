import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class ActiveJourneyHUD extends StatelessWidget {
  final String distance;
  final Future<void> Function() onStop;
  final VoidCallback onNavigate;

  // Usage: Your exact colors
  final Color cardNavy = const Color(0xFF0F172A);
  final Color dangerRed = const Color(0xFFEF4444);
  final Color navBlue = const Color(0xFF4285F4); // Google Maps Blue

  const ActiveJourneyHUD({
    super.key,
    required this.distance,
    required this.onStop,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. TOP FLOATING PILL (Distance Only)
        // ✨ UPGRADED: 3D Floating Effect
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: cardNavy.withOpacity(0.2), // Deeper shadow
                    blurRadius: 25,
                    spreadRadius: -2,
                    offset: const Offset(0, 10), // Vertical lift
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, color: cardNavy, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 20, // Slightly bigger
                      fontWeight: FontWeight.w900, // Black weight
                      color: cardNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. FLOATING NAVIGATION BUTTON (FAB)
        // ✨ UPGRADED: Lifted Shadow
        Positioned(
          bottom: 150, // Slightly higher to clear the larger slider
          right: 20,
          child: InkWell(
            onTap: onNavigate,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 60, // Bigger touch target
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cardNavy.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions,
                color: navBlue,
                size: 32,
              ),
            ),
          ),
        ),

        // 3. BOTTOM FLOATING SLIDER (The Professional "Stop" Button)
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Container(
            // ✨ THE 3D DEPTH EFFECT
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: dangerRed.withOpacity(0.4), // Red Glow
                  blurRadius: 25,
                  spreadRadius: -5, // Tighter spread for "lifted" look
                  offset: const Offset(0, 12), // Deep vertical shadow
                ),
              ],
            ),
            child: SlideAction(
              onSubmit: onStop,
              innerColor: dangerRed,
              outerColor: Colors.white,
              // ✨ CHUNKY ICON
              sliderButtonIcon: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
              text: "SLIDE TO END VISIT",
              // ✨ PROFESSIONAL TYPOGRAPHY
              textStyle: TextStyle(
                color: dangerRed,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5, // Wide spacing for "Tech" feel
              ),
              height: 76, // Taller touch target
              borderRadius: 24,
              elevation: 0, // We handle shadow manually
              sliderRotate: false,
            ),
          ),
        ),
      ],
    );
  }
}