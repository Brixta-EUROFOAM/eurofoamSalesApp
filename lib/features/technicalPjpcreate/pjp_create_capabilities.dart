import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class PjpCreateCapabilities {
  final bool enabled;
  final bool bulkEnabled;

  const PjpCreateCapabilities({
    required this.enabled,
    required this.bulkEnabled,
  });

  factory PjpCreateCapabilities.fromFlags(TechnicalFlags flags) {
    return PjpCreateCapabilities(
      enabled: flags.createPjp,
      bulkEnabled: flags.createPjp, // or separate flag later
    );
  }
}
