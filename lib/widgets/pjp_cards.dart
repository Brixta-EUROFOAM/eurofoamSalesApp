import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
// Unused import removed. This file only needs pjp_model.dart to get the Pjp class.

// --- ✅ NEW: This is the card for "Verified" PJPs ---
class PjpCard extends StatelessWidget {
  final Pjp pjp;
  final bool isVerified; // isVerified is true for this card

  const PjpCard({super.key, required this.pjp, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- ✅ FIX: Make the name logic smarter ---
    // Prioritize the specific dealerName. Fall back to the area string.
    // This fixes the "Monthly PJP Plan" bug.
    final displayName = pjp.dealerName ?? pjp.areaToBeVisited.split('|').first;
    // --- END FIX ---

    return Card(
      // This is the standard, theme-aware card
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle, // <-- "Verified" icon
              color: Colors.green,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            
            // --- ✅ FIX: Icon direction ---
            // This now correctly hints at a left-to-right swipe
            Icon(Icons.keyboard_arrow_right, // <-- Was keyboard_arrow_left
                color: theme.colorScheme.onSurface.withOpacity(0.7), size: 30),
            // --- END FIX ---
          ],
        ),
      ),
    );
  }
}

// --- ✅ NEW: This is the card for "Pending" PJPs ---
// It is visually distinct and not slidable.
class PendingPjpCard extends StatelessWidget {
  final Pjp pjp;

  const PendingPjpCard({super.key, required this.pjp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- ✅ FIX: Make the name logic smarter ---
    final displayName = pjp.dealerName ?? pjp.areaToBeVisited.split('|').first;
    // --- END FIX ---

    // --- ✅ THE MAIN FIX: This now checks the correct field ---
    // It looks at 'verificationStatus' instead of 'status'.
    final statusText = (pjp.verificationStatus == 'PENDING')
        ? "Waiting for approval"
        : "Status: ${pjp.verificationStatus ?? 'N/A'}"; // Use verificationStatus
    // --- END FIX ---


    // Use a more muted card color
    final cardColor = theme.colorScheme.surface.withOpacity(0.6);
    final textColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final iconColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions, // <-- "Pending" icon
              color: iconColor,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    statusText, // <-- Use the new fixed statusText variable
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Section header (Unchanged) ---
class PjpSectionHeader extends StatelessWidget {
  final String title;
  const PjpSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}