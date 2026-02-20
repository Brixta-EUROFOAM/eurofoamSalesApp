// lib/core/feature_flags/sales_flags.dart

class SalesFlags {
  final bool journey;

  final bool createDvr;
  final bool addDealer;
  final bool competitionForm;
  final bool salesOrders;

  final bool showDbViewer;

  const SalesFlags({
    required this.journey,

    required this.createDvr,
    required this.addDealer,
    required this.competitionForm,
    required this.salesOrders,

    required this.showDbViewer,
  });

  static const SalesFlags dev = SalesFlags(
    journey: true,

    createDvr: true,
    addDealer: true,
    competitionForm: true,
    salesOrders: false,

    showDbViewer: false,
  );
}