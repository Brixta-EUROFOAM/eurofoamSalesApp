import 'package:salesmanapp/api/api_service.dart';
import 'pjp_create_capabilities.dart';
import 'pjp_create_results.dart';

class PjpCreateController {
  final PjpCreateCapabilities caps;
  final ApiService api;

  PjpCreateController({
    required this.api,
    required this.caps});

  PjpCreateResult startSingle() {
    if (!caps.enabled) {
      throw Exception('PJP creation disabled');
    }

    return const PjpCreateResult(mode: PjpCreateMode.single);
  }

  PjpCreateResult startBulk() {
    if (!caps.bulkEnabled) {
      throw Exception('Bulk PJP disabled');
    }

    return const PjpCreateResult(mode: PjpCreateMode.bulk);
  }
}
