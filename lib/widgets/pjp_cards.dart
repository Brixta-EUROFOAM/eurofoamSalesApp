import 'package:flutter/material.dart';
import 'package:salesmanapp/salesSide/models/pjp_model.dart';
import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

// --- PjpCard (StatefulWidget) ---
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

    // 1) Use provided dealerName when available
    if (pjp.dealerName != null && pjp.dealerName!.isNotEmpty) {
      setState(() {
        _displayName = pjp.dealerName!;
        final area = pjp.areaToBeVisited.split('|').first.trim();
        _subtitle = (area.isNotEmpty && area != _displayName) ? area : dateString;
        _isLoading = false;
      });
      return;
    }

    // 2) Otherwise, try fetching the dealer by id
    if (pjp.dealerId != null && pjp.dealerId!.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        dev.log('PjpCard: Fetching details for dealerId=${pjp.dealerId}');
        final Dealer dealer = await _apiService.fetchDealerById(pjp.dealerId!);
        if (!mounted) return;
        setState(() {
          _displayName = dealer.name;
          _subtitle = dealer.area;
          _isLoading = false;
        });
      } catch (e) {
        dev.log('PjpCard: Failed to fetch dealer ${pjp.dealerId}', error: e);
        if (!mounted) return;
        setState(() {
          _displayName = pjp.description ?? pjp.areaToBeVisited;
          _subtitle = dateString;
          _isLoading = false;
        });
      }
      return;
    }

    // 3) Fallback to description/area
    if (!mounted) return;
    setState(() {
      _displayName = (pjp.description != null && pjp.description!.isNotEmpty)
          ? pjp.description!
          : pjp.areaToBeVisited;
      _subtitle = dateString;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final loadingTitle = (widget.pjp.description != null && widget.pjp.description!.isNotEmpty)
        ? widget.pjp.description!
        : "Loading Dealer...";

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Action bar
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

            // 2) Content
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
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_isLoading)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 1, right: 7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Icon(
                            (_subtitle != null && _subtitle != DateFormat.yMMMd().format(widget.pjp.planDate))
                                ? Icons.pin_drop_outlined
                                : Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        Text(
                          _isLoading ? "Fetching details..." : (_subtitle ?? ""),
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3) Status icon
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

// --- PendingPjpCard ---
class PendingPjpCard extends StatelessWidget {
  final Pjp pjp;

  const PendingPjpCard({super.key, required this.pjp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final String displayName = (pjp.dealerName != null && pjp.dealerName!.isNotEmpty)
        ? pjp.dealerName!
        : ((pjp.description != null && pjp.description!.isNotEmpty) ? pjp.description! : pjp.areaToBeVisited);

    final dateString = DateFormat.yMMMd().format(pjp.planDate);
    final pendingColor = theme.colorScheme.secondary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(Icons.hourglass_top, color: pendingColor, size: 30),
        title: Text(
          displayName,
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

// --- ✅ Section header (Now with collapse button) ---
class PjpSectionHeader extends StatelessWidget {
  final String title;
  final bool? isExpanded;
  final VoidCallback? onToggle;

  const PjpSectionHeader({
    super.key,
    required this.title,
    this.isExpanded,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (isExpanded == true) ? 1.0 : 0.0,
            child: (isExpanded == true)
                ? TextButton(
                    onPressed: onToggle,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'COLLAPSE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.unfold_less, size: 18),
                      ],
                    ),
                  )
                : const SizedBox(height: 30),
          ),
        ],
      ),
    );
  }
}
