// lib/widgets/reusable_functions.dart

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/database/app_database.dart';

import 'package:salesmanapp/salesSide/models/dealer_model.dart';
import 'package:salesmanapp/salesSide/models/destination_model.dart';
import 'package:salesmanapp/technicalSide/models/sites_model.dart';
import 'package:salesmanapp/technicalSide/models/mason_pc_model.dart';

/// ------------------------------------------------------------
/// GENERIC DIALOG OPENER
/// ------------------------------------------------------------
Future<T?> openSearchDialog<T>({
  required BuildContext context,
  required Widget dialog,
}) {
  return showDialog<T>(context: context, builder: (_) => dialog);
}

/// ------------------------------------------------------------
/// PUBLIC HELPERS (USE THESE EVERYWHERE)
/// ------------------------------------------------------------
Future<Dealer?> openDealerSearch(
  BuildContext context, {
  double? lat,
  double? lng,
}) {
  return openSearchDialog(
    context: context,
    dialog: DealerSearchDialog(lat: lat, lng: lng),
  );
}

Future<TechnicalSite?> openSiteSearch(
  BuildContext context,
  ApiService api,
  int userId,
) {
  return openSearchDialog(
    context: context,
    dialog: SiteSearchDialog(api: api, userId: userId),
  );
}

Future<Mason?> openMasonSearch(BuildContext context, ApiService api) {
  return openSearchDialog(
    context: context,
    dialog: MasonSearchDialog(api: api),
  );
}

Future<DestinationModel?> openDestinationSearch(
  BuildContext context,
  ApiService api,
) {
  return openSearchDialog(
    context: context,
    dialog: DestinationSearchDialog(api: api),
  );
}

/// ------------------------------------------------------------
/// BASE SEARCH DIALOG (DRY UI)
/// ------------------------------------------------------------
class _BaseSearchDialog<T> extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<T> items;
  final Function(String) onSearch;
  final Widget Function(T) itemBuilder;

  const _BaseSearchDialog({
    required this.title,
    required this.isLoading,
    required this.items,
    required this.onSearch,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 12),

            TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? const Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => itemBuilder(items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 🚀 DEALER SEARCH (OFFLINE-FIRST)
/// ------------------------------------------------------------
class DealerSearchDialog extends StatefulWidget {
  final double? lat;
  final double? lng;

  const DealerSearchDialog({super.key, this.lat, this.lng});

  @override
  State<DealerSearchDialog> createState() => _DealerSearchDialogState();
}

class _DealerSearchDialogState extends State<DealerSearchDialog> {
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search("");
  }

  final _api = ApiService();

  void _search(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoading = true);

      try {
        List<Dealer> results = [];
        final cleanQuery = query.trim();

        // CASE 1: EMPTY QUERY → NEARBY FIRST
        if (cleanQuery.isEmpty) {
          // 1. NEARBY DEALERS
          if (widget.lat != null && widget.lng != null) {
            final nearby = await _api.fetchDealers(
              lat: widget.lat,
              lng: widget.lng,
              radius: 3, 
              limit: 50,
            );

            // If too few → fallback to general API
            if (nearby.length >= 5) {
              results = nearby;
            } else {
              results = await _api.fetchDealers(search: "", limit: 20);
            }
          } else {
            results = await _api.fetchDealers(search: "", limit: 20);
          }
        }
        
        // CASE 2: SEARCH QUERY
        else {
          // LOCAL SEARCH FIRST
          final localData = await AppDatabase.instance.searchLocalDealers(
            cleanQuery,
          );

          results = localData.map((d) => Dealer.fromJson(d.toJson())).toList();

          // API FALLBACK (WITH LOCATION BOOST)
          if (results.isEmpty) {
            results = await _api.fetchDealers(
              search: cleanQuery,
              lat: widget.lat,
              lng: widget.lng,
              limit: 50,
            );
          }
        }

        if (mounted) {
          setState(() => _dealers = results);
        }
      } catch (e) {
        debugPrint("Dealer search error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<Dealer>(
      title: "Select Dealer",
      isLoading: _isLoading,
      items: _dealers,
      onSearch: _search,
      itemBuilder: (dealer) => ListTile(
        title: Text(
          dealer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "${dealer.area}, ${dealer.region}",
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () => Navigator.pop(context, dealer),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 🌐 SITE SEARCH (API)
/// ------------------------------------------------------------
class SiteSearchDialog extends StatefulWidget {
  final ApiService api;
  final int userId;

  const SiteSearchDialog({super.key, required this.api, required this.userId});

  @override
  State<SiteSearchDialog> createState() => _SiteSearchDialogState();
}

class _SiteSearchDialogState extends State<SiteSearchDialog> {
  List<TechnicalSite> _sites = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search("");
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);

      try {
        final res = await widget.api.fetchTechnicalSites(
          userId: widget.userId,
          search: query,
        );

        if (mounted) {
          setState(() => _sites = res);
        }
      } catch (e) {
        debugPrint("Site search error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<TechnicalSite>(
      title: "Select Site",
      isLoading: _isLoading,
      items: _sites,
      onSearch: _search,
      itemBuilder: (site) => ListTile(
        title: Text(
          site.siteName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(site.address),
        onTap: () => Navigator.pop(context, site),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// 🌐 MASON SEARCH (API)
/// ------------------------------------------------------------
class MasonSearchDialog extends StatefulWidget {
  final ApiService api;

  const MasonSearchDialog({super.key, required this.api});

  @override
  State<MasonSearchDialog> createState() => _MasonSearchDialogState();
}

class _MasonSearchDialogState extends State<MasonSearchDialog> {
  List<Mason> _masons = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search("");
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);

      try {
        final res = await widget.api.fetchMasons(search: query);

        if (mounted) {
          setState(() => _masons = res);
        }
      } catch (e) {
        debugPrint("Mason search error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<Mason>(
      title: "Select Mason",
      isLoading: _isLoading,
      items: _masons,
      onSearch: _search,
      itemBuilder: (mason) => ListTile(
        title: Text(
          mason.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(mason.phoneNumber),
        onTap: () => Navigator.pop(context, mason),
      ),
    );
  }
}

class DestinationSearchDialog extends StatefulWidget {
  final ApiService api;

  const DestinationSearchDialog({super.key, required this.api});

  @override
  State<DestinationSearchDialog> createState() =>
      _DestinationSearchDialogState();
}

class _DestinationSearchDialogState extends State<DestinationSearchDialog> {
  List<DestinationModel> _destinations = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search("");
  }

  void _search(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);

      try {
        final res = await widget.api.fetchDestinations(
          search: query,
          limit: 50,
        );

        if (mounted) {
          setState(() => _destinations = res);
        }
      } catch (e) {
        debugPrint("Destination search error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSearchDialog<DestinationModel>(
      title: "Select Destination",
      isLoading: _isLoading,
      items: _destinations,
      onSearch: _search,
      itemBuilder: (d) => ListTile(
        title: Text(
          d.destination ?? "",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text("${d.district ?? ""}, ${d.zone ?? ""}"),
        onTap: () => Navigator.pop(context, d),
      ),
    );
  }
}