// lib/core/feature_flags/sales_flags.dart

class SalesFlags {
  final bool journey;

  final bool createDvr;
  final bool addDealer;
  final bool addDestination;
  final bool competitionForm;
  final bool salesOrders;
  final bool teamView;

  final bool showDbViewer;
  final bool accountSwitcher;
  final bool offlineSync;

  const SalesFlags({
    required this.journey,

    required this.createDvr,
    required this.addDealer,
    required this.addDestination,
    required this.competitionForm,
    required this.salesOrders,
    required this.teamView,

    required this.showDbViewer,
    required this.accountSwitcher,
    required this.offlineSync,
  });

  static const SalesFlags dev = SalesFlags(
    journey: true,

    createDvr: true,
    addDestination: false,
    addDealer: true,
    competitionForm: false,
    salesOrders: true,
    teamView: true,

    showDbViewer: false,
    accountSwitcher: true,
    offlineSync: true,
  );
}