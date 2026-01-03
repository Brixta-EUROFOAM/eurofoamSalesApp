import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class BulkPjpCapabilities {
  final bool enabled;
  final bool allowInfluencerBulk;

  const BulkPjpCapabilities({
    required this.enabled,
    required this.allowInfluencerBulk,
  });

  factory BulkPjpCapabilities.fromFlags(TechnicalFlags flags) {
    return BulkPjpCapabilities(
      enabled: flags.createPjp, 
      allowInfluencerBulk: true,
    );
  }
}