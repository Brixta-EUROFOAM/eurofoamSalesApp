import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActiveJourneyHUD extends StatelessWidget {
  final String distance;
  final Future<void> Function() onStop;
  final VoidCallback onNavigate;

  final Color cardNavy = const Color(0xFF0F172A);
  final Color dangerRed = const Color(0xFFEF4444);
  final Color navBlue = const Color(0xFF4285F4); 

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
        // 1. TOP FLOATING PILL (Distance)
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
                    color: cardNavy.withOpacity(0.15), 
                    blurRadius: 25,
                    spreadRadius: -2,
                    offset: const Offset(0, 10), 
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, color: cardNavy, size: 22),
                  const SizedBox(width: 12),
                  // ✨ Smooth text transition for when the distance updates
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      distance,
                      key: ValueKey<String>(distance),
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900, 
                        color: cardNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate()
             .slideY(begin: -1.5, duration: 600.ms, curve: Curves.easeOutBack)
             .fadeIn(duration: 400.ms),
          ),
        ),

        // 2. FLOATING NAVIGATION BUTTON (FAB)
        Positioned(
          bottom: 210, 
          right: 50,
          child: InkWell(
            onTap: onNavigate,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 60, 
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: navBlue.withOpacity(0.3),
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
          ).animate(delay: 200.ms)
           .scale(duration: 500.ms, curve: Curves.easeOutBack)
           .fadeIn()
           // ✨ Subtle continuous pulse to draw the user's eye to navigation
           .then()
           .shimmer(duration: 2000.ms, color: navBlue.withOpacity(0.2))
           .animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(end: 1.05, duration: 1500.ms, curve: Curves.easeInOutSine),
        ),

        // 3. BOTTOM FLOATING SLIDER
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: dangerRed.withOpacity(0.35), 
                  blurRadius: 25,
                  spreadRadius: -5, 
                  offset: const Offset(0, 12), 
                ),
              ],
            ),
            child: SlideAction(
              onSubmit: () async {
                await onStop();
                return null;
              },
              innerColor: dangerRed,
              outerColor: Colors.white,
              sliderButtonIcon: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
              text: "SLIDE TO END VISIT",
              textStyle: TextStyle(
                color: dangerRed,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5, 
              ),
              height: 76, 
              borderRadius: 24,
              elevation: 0, 
              sliderRotate: false,
            ),
          ).animate(delay: 100.ms)
           .slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
           .fadeIn(),
        ),
      ],
    );
  }
}