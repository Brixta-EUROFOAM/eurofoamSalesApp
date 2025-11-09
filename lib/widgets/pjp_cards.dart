import 'package:flutter/material.dart';
import 'package:assetarchiverflutter/models/pjp_model.dart';
import 'package:assetarchiverflutter/models/dealer_model.dart'; // <-- ✅ NEW IMPORT
import 'package:assetarchiverflutter/api/api_service.dart'; // <-- ✅ NEW IMPORT
import 'package:intl/intl.dart'; 
import 'dart:developer' as dev; // <-- ✅ NEW IMPORT

// --- ✅ REDESIGNED: PjpCard is now a StatefulWidget ---
class PjpCard extends StatefulWidget {
  final Pjp pjp;
  final bool isVerified;

  const PjpCard({super.key, required this.pjp, required this.isVerified});

  @override
  State<PjpCard> createState() => _PjpCardState();
}

class _PjpCardState extends State<PjpCard> {
  final ApiService _apiService = ApiService();
  
  String? _displayName;
  String? _subtitle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resolveDisplayNames();
  }

  Future<void> _resolveDisplayNames() async {
    final pjp = widget.pjp;
    final dateString = DateFormat.yMMMd().format(pjp.planDate);

    // --- ✅ THIS IS THE SMART LOGIC ---
    
    // 1. If dealerName is already in the PJP object, just use it.
    if (pjp.dealerName != null && pjp.dealerName!.isNotEmpty) {
      setState(() {
        _displayName = pjp.dealerName!;
        final area = pjp.areaToBeVisited.split('|').first.trim();
        _subtitle = (area.isNotEmpty && area != _displayName) ? area : dateString;
        _isLoading = false;
      });
      return;
    }

    // 2. If dealerName is missing, but we have a dealerId, fetch the dealer.
    if (pjp.dealerId != null && pjp.dealerId!.isNotEmpty) {
      if (!mounted) return;
      setState(() { _isLoading = true; }); // Show loading
      
      try {
        dev.log('PjpCard: Fetching details for dealerId=${pjp.dealerId}');
        final Dealer dealer = await _apiService.fetchDealerById(pjp.dealerId!);
        if (!mounted) return;
        setState(() {
          _displayName = dealer.name;
          _subtitle = dealer.area; // Use the dealer's area as the subtitle
          _isLoading = false;
        });
      } catch (e) {
        dev.log('PjpCard: Failed to fetch dealer ${pjp.dealerId}', error: e);
        // 3. If fetch fails, fall back to the PJP description.
        if (!mounted) return;
        setState(() {
          _displayName = pjp.description ?? pjp.areaToBeVisited;
          _subtitle = dateString;
          _isLoading = false;
        });
      }
      return;
    }

    // 4. If all else fails, fall back to description/area.
    if (!mounted) return;
    setState(() {
      _displayName = (pjp.description != null && pjp.description!.isNotEmpty)
          ? pjp.description!
          : pjp.areaToBeVisited;
      _subtitle = dateString;
      _isLoading = false;
    });
    // --- END LOGIC ---
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    // Use the description as a temporary title while loading
    final loadingTitle = (widget.pjp.description != null && widget.pjp.description!.isNotEmpty)
          ? widget.pjp.description!
          : "Loading Dealer...";

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. THE "LIVELY" ACTION BAR ---
            Container(
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_right_alt,
                    color: theme.colorScheme.onPrimary,
                    size: 28,
                  ),
                ],
              ),
            ),

            // --- 2. THE CONTENT (NOW HANDLES LOADING) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(
                      _isLoading ? loadingTitle : (_displayName ?? "Error"),
                      style: textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date or Area Subtitle
                    Row(
                      children: [
                        if (_isLoading)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 1, right: 7),
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          )
                        else
                          Icon(
                            // If subtitle is not the date, show a pin icon
                            (_subtitle != null && _subtitle != DateFormat.yMMMd().format(widget.pjp.planDate))
                               ? Icons.pin_drop_outlined
                               : Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        Text(
                          _isLoading 
                              ? "Fetching details..." 
                              : (_subtitle ?? ""),
                          style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- 3. THE STATUS ICON ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ✅ PendingPjpCard is now also SMARTER ---
// It will never show "pending" as a title again.
class PendingPjpCard extends StatelessWidget {
  final Pjp pjp;

  const PendingPjpCard({super.key, required this.pjp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- ✅ NEW, SMARTER LOGIC ---
    final String displayName;
    
    // 1. Try to use dealerName if it exists (e.g., from a single PJP)
    if (pjp.dealerName != null && pjp.dealerName!.isNotEmpty) {
      displayName = pjp.dealerName!;
    } else {
    // 2. Fall back to description (e.g., "Monthly PJP Plan")
      displayName = (pjp.description != null && pjp.description!.isNotEmpty)
          ? pjp.description!
          : pjp.areaToBeVisited; // 3. Last resort
    }
    // This logic ensures "pending" is never shown as the title.
    // --- END NEW LOGIC ---

    final dateString = DateFormat.yMMMd().format(pjp.planDate);
    final pendingColor = theme.colorScheme.secondary; 

    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          Icons.hourglass_top, 
          color: pendingColor,
          size: 30,
        ),
        title: Text(
          displayName, // <-- Uses new smart logic
          style: textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "Waiting for approval • $dateString",
          style: textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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