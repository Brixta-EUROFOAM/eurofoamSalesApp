// lib/core/feature_flags/sales_flags.dart

class SalesFlags {
  final bool showDbViewer;

  const SalesFlags({
    required this.showDbViewer,
  });

  static const SalesFlags dev = SalesFlags(
    showDbViewer: true,
  );
}