import 'package:flutter/foundation.dart';
import 'package:salesmanapp/models/pjp_model.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/features/technicalPjpjourneystart/pjp_journey_controller.dart';
import 'package:salesmanapp/features/technicalPjpjourneystart/pjp_journey_result.dart';
import 'package:salesmanapp/features/technicalPjpjourneystart/pjp_journey_capabilities.dart';

// =============================================================================
// 1. THE INTENT (Kept here for simplicity)
// =============================================================================
class StartJourneyIntent {
  final Pjp pjp;
  StartJourneyIntent(this.pjp);
}

// =============================================================================
// 2. THE STATES
// =============================================================================
abstract class JourneyState {}

class JourneyIdle extends JourneyState {}

class JourneyProcessing extends JourneyState {
  final String pjpId; 
  JourneyProcessing(this.pjpId);
}

class JourneySuccess extends JourneyState {
  final Pjp pjp;
  final PjpJourneyResult result; 
  
  JourneySuccess({
    required this.pjp, 
    required this.result
  });
}

class JourneyFailure extends JourneyState {
  final String errorMessage;
  JourneyFailure(this.errorMessage);
}

// =============================================================================
// 3. THE BRAIN (State Machine)
// =============================================================================
class JourneyStateMachine extends ValueNotifier<JourneyState> {
  final ApiService _apiService;
  final TechnicalFlags _flags;

  JourneyStateMachine({
    required ApiService apiService,
    required TechnicalFlags flags,
  }) : _apiService = apiService,
       _flags = flags,
       super(JourneyIdle());

  /// 📥 Dispatch: Receives the Intent from UI
  Future<void> dispatch(dynamic intent) async {
    if (intent is StartJourneyIntent) {
       await _handleStartJourney(intent.pjp);
    }
  }

  /// ⚙️ Logic: Processes the journey start
  Future<void> _handleStartJourney(Pjp pjp) async {
    // 1. UPDATE UI: Show Spinner
    value = JourneyProcessing(pjp.id);
    
    debugPrint("🧠 [JourneyMachine] Processing Start Intent for PJP: ${pjp.id}");

    try {
      // 2. LOGIC: Initialize Controller & Capabilities
      final caps = PjpJourneyCapabilities.fromFlags(_flags);
      final controller = PjpJourneyController(
        api: _apiService,
        caps: caps,
      );

      // 3. EXECUTE: Async work (API, Location, Validation)
      debugPrint("⚙️ [JourneyMachine] calling controller.start()...");
      final result = await controller.start(pjp);

      debugPrint("✅ [JourneyMachine] Success. Emitting Navigation Data.");

      // 4. UPDATE UI: Success & Navigate
      value = JourneySuccess(
        pjp: pjp,
        result: result,
      );

    } catch (e) {
      debugPrint("❌ [JourneyMachine] Error: $e");
      
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }

      // 5. UPDATE UI: Show Error SnackBar
      value = JourneyFailure(msg);
    }
  }

  /// 🔄 Reset: Clears state (call after navigation)
  void reset() {
    value = JourneyIdle();
  }
}