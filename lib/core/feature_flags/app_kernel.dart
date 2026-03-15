// lib/core/app_kernel.dart

import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';

class AppKernel {
  AppKernel._(); // no instances

  // ---- SERVICES (SINGLETONS) ----
  static final ApiService api = ApiService();

  // ---- FLAGS (READ-ONLY) ----
  static late TechnicalFlags _flags;

  static void boot({required TechnicalFlags flags}) {
    _flags = flags;
  }

  static bool flag(bool Function(TechnicalFlags f) pick) {
    return pick(_flags);
  }
}
