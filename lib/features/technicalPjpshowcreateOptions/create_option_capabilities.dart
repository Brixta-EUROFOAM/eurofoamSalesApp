import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
class CreateOptionCapabilities {
  final bool enabled;
  final bool singleEnabled;
  final bool bulkEnabled;

  const CreateOptionCapabilities({
    required this.enabled,
    required this.singleEnabled,
    required this.bulkEnabled,
  });

  factory CreateOptionCapabilities.fromFlags(TechnicalFlags flags) {
    return CreateOptionCapabilities(
      enabled: flags.createPjp,
      singleEnabled: flags.createPjp,
      bulkEnabled: flags.createPjp, // split later if needed
    );
  }
}
