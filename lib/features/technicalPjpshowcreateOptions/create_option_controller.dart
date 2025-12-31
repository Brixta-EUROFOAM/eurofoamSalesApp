import 'package:flutter/material.dart';

import 'create_option_capabilities.dart';
import 'create_option_result.dart';

// ✅ IMPORT THE SINGLE SOURCE OF TRUTH
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_results.dart';

class CreateOptionController {
  final CreateOptionCapabilities caps;

  CreateOptionController({required this.caps});

  List<PjpCreateOption> getOptions() {
    if (!caps.enabled) {
      throw Exception('Create PJP disabled');
    }

    final options = <PjpCreateOption>[];

    if (caps.singleEnabled) {
      options.add(
        const PjpCreateOption(
          mode: PjpCreateMode.single, // ✅ SAME ENUM EVERYWHERE
          title: 'Add Single Visit',
          subtitle: 'For specific date',
          icon: Icons.add_location_alt,
          iconColor: Colors.blue,
        ),
      );
    }

    if (caps.bulkEnabled) {
      options.add(
        const PjpCreateOption(
          mode: PjpCreateMode.bulk, // ✅ SAME ENUM EVERYWHERE
          title: 'Bulk Monthly Plan',
          subtitle: 'Auto-schedule multiple sites',
          icon: Icons.calendar_month,
          iconColor: Colors.green,
        ),
      );
    }

    return options;
  }
}
