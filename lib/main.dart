import 'package:flutter/material.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:provider/provider.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'package:salesmanapp/services/websocket/session_manager.dart';
import 'package:salesmanapp/core/feature_flags/technical_flags.dart';
import 'package:salesmanapp/core/feature_flags/sales_flags.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//kernel
import 'package:salesmanapp/core/app_kernel.dart';
import 'package:salesmanapp/api/api_service.dart';
import 'package:salesmanapp/features/technicalPjpjourneystart/pjp_journey_capabilities.dart';
import 'package:salesmanapp/features/technicalPjpjourneystart/pjp_journey_controller.dart';
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_controller.dart';
import 'package:salesmanapp/features/technicalPjpcreate/pjp_create_capabilities.dart';
import 'package:salesmanapp/features/technicalPjpshowcreateOptions/create_option_controller.dart';
import 'package:salesmanapp/features/technicalPjpshowcreateOptions/create_option_capabilities.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_capabilities.dart';
import 'package:salesmanapp/features/journeytracking/journey_tracking_controller.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_controller.dart';
import 'package:salesmanapp/features/launchgooglemapsJourneyscreen/googlemaps_capabilities.dart';
import 'package:salesmanapp/features/journeylocation/journeylocation_capabilities.dart';
import 'package:salesmanapp/features/journeylocation/journeylocation_controller.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_capabilities.dart';
import 'package:salesmanapp/features/journeyMapstyle/journeyMapstyle_controller.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_capabilities.dart';
import 'package:salesmanapp/features/mapselectionpjp/map_selection_controller.dart';
import 'package:salesmanapp/features/technicalBulkPjp/bulk_pjp_capabilities.dart';
import 'package:salesmanapp/features/technicalBulkPjp/bulk_pjp_controller.dart';
import 'package:salesmanapp/features/planedAreaJourney/planed_capabilities.dart';
import 'package:salesmanapp/features/planedAreaJourney/planed_controller.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_controller.dart';
import 'package:salesmanapp/features/JourneyModeController/journey_mode_capabilities.dart';
import 'package:salesmanapp/features/journey_bootstrap/journey_bootstrap_controller.dart';
import 'package:salesmanapp/features/unplanned_journey/unplanned_journey_capabilities.dart';
import 'package:salesmanapp/features/unplanned_journey/unplanned_journey_controller.dart';
import 'package:salesmanapp/services/dvrTimerFgTaskHandler/dvr_timer_foreground_service.dart';
import 'package:salesmanapp/services/journeyFgTaskHandler/journey_foreground_service.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_controller.dart';
import 'package:salesmanapp/features/salesJourney/sales_journey_capabilities.dart';

// --- WIDGETS & THEMES ---
import 'package:salesmanapp/widgets/app_theme.dart';
import 'package:salesmanapp/widgets/theme_provider.dart';
import 'package:salesmanapp/widgets/reusable_constants.dart';

// --- MODELS & SERVICES ---
import 'package:salesmanapp/salesSide/models/employee_model.dart';
import 'package:salesmanapp/services/notification_service.dart';
import 'package:salesmanapp/api/auth_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// --- SCREENS ---
import 'package:salesmanapp/auth/login_screen.dart';
import 'package:salesmanapp/salesSide/screens/nav_screen.dart';
import 'package:salesmanapp/auth/app_selector_screen.dart';
import 'package:salesmanapp/technicalSide/screens/technical_nav_screen.dart';
import 'package:salesmanapp/technicalSide/screens/forms/approve_mason_bagLift.dart';
import 'package:firebase_core/firebase_core.dart';

// 1. DEFINE GLOBAL KEY FOR NAVIGATOR
// We'll use this to get a BuildContext that's always under MaterialApp.
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  final flags = TechnicalFlags.dev;
  final salesFlags = SalesFlags.dev;

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint("Firebase Initialized Successfully.");

  // Remote Config -- pull env keys
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ),
  );

  await remoteConfig.setDefaults({
    'RADAR_API_KEY': '',
    'STADIA_API_KEY': '',
  });

  await remoteConfig.fetchAndActivate();

  debugPrint("RC Radar: ${remoteConfig.getString('RADAR_API_KEY')}");
  debugPrint("RC Stadia: ${remoteConfig.getString('STADIA_API_KEY')}");

  final kernel = AppKernel.instance;
  //KERNEL REGISTRATION

  // ------- TECHNICAL SIDE FLAGS ---------
  kernel.registerIf<PjpJourneyController>(
    flags.pjpjourney,
    () => PjpJourneyController(
      api: ApiService(),
      caps: PjpJourneyCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<UnplannedJourneyController>(
    flags.journey,
    () => UnplannedJourneyController(
      caps: UnplannedJourneyCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<JourneyModeController>(
    flags.journey,
    () => JourneyModeController(caps: JourneyModeCapabilities.fromFlags(flags)),
  );

  kernel.registerIf<JourneyBootstrapController>(
    flags.journeyStartStop,
    () => JourneyBootstrapController(),
  );
  kernel.registerIf<JourneyTrackingController>(
    flags.journeyTracking,
    () => JourneyTrackingController(
      caps: JourneyTrackingCapabilities.fromFlags(flags),
      notifications: FlutterLocalNotificationsPlugin(),
      api: ApiService(),
    ),
  );

  kernel.registerIf<PjpCreateController>(
    flags.createPjp,
    () => PjpCreateController(
      api: ApiService(),
      caps: PjpCreateCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<BulkPjpController>(
    flags.createPjp,
    () => BulkPjpController(
      api: ApiService(),
      caps: BulkPjpCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<CreateOptionController>(
    flags.createPjp,
    () =>
        CreateOptionController(caps: CreateOptionCapabilities.fromFlags(flags)),
  );
  kernel.registerIf<PlannedAreaJourneyController>(
    flags.pjpjourney,
    () => PlannedAreaJourneyController(
      caps: PlannedAreaJourneyCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<JourneyLocationController>(
    flags.journeyMap || flags.journeyTracking,
    () => JourneyLocationController(
      caps: JourneyLocationCapabilities.fromFlags(flags),
    ),
  );
  kernel.registerIf<MapSelectionController>(
    flags.journeyMap, // Using your new flag
    () =>
        MapSelectionController(caps: MapSelectionCapabilities.fromFlags(flags)),
  );

  kernel.registerIf<JourneyNavigationController>(
    flags.journeyMap,
    () => JourneyNavigationController(
      caps: JourneyNavigationCapabilities.fromFlags(flags),
    ),
  );

  kernel.registerIf<JourneyMapStyleController>(
    flags.journeyMap,
    () => JourneyMapStyleController(
      caps: JourneyMapStyleCapabilities.fromFlags(flags),
    ),
  );

  // ------- SALES SIDE FLAGS ---------
  kernel.registerIf<SalesJourneyController>(
    flags.journey,
    () => SalesJourneyController(
      caps: SalesJourneyCapabilities.fromFlags(salesFlags),
    ),
  );

  //KENEL REGISTRATION

  await NotificationService().init();
  await JourneyForegroundService.init();
  debugPrint("NOTIFICATIONS INITIALIZED.");

  await DvrTimerForegroundService.init();

  final radarPublishableKey = AppKeys.radarApiKey;
  if (radarPublishableKey.isEmpty) {
    debugPrint("❌ Radar key missing — skipping init");
  } else {
    await Radar.initialize(radarPublishableKey);
    debugPrint("Radar SDK Initialized Successfully.");
  }

  runApp(
    MultiProvider(
      providers: [
        // FEATURE FLAGS (control plane)
        Provider<TechnicalFlags>.value(value: TechnicalFlags.dev),
        Provider<SalesFlags>.value(value: SalesFlags.dev),

        // THEME PROVIDER (already used by MyApp)
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Future<void> _checkForcedLogout() async {
  //   final prefs = await SharedPreferences.getInstance();

  //   final shouldLogout = prefs.getBool('force_logout_on_resume') ?? false;
  //   if (!shouldLogout) return;

  //   final message = prefs.getString('force_logout_message');

  //   // 🔥 Nuke ALL local state (single source of truth)
  //   await prefs.clear();

  //   // 🔐 Hard auth cleanup (secure storage, etc.)
  //   await AuthService().logout();

  //   // 🧭 Navigate safely to login
  //   if (globalNavigatorKey.currentState != null) {
  //     globalNavigatorKey.currentState!.pushNamedAndRemoveUntil(
  //       '/salesforce_login_page',
  //       (route) => false,
  //     );
  //   }

  //   // 🗣 Optional user feedback
  //   if (message != null && globalNavigatorKey.currentContext != null) {
  //     ScaffoldMessenger.of(globalNavigatorKey.currentContext!).showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         backgroundColor: Colors.red.shade700,
  //         duration: const Duration(seconds: 4),
  //       ),
  //     );
  //   }

  //   debugPrint("🔐 Forced logout executed successfully");
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await _checkForcedLogout();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App resumed — checking forced logout");
      // await _checkForcedLogout();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEST WORK FORCE',

      // 3. ✅ ASSIGN THE GLOBAL NAVIGATOR KEY HERE
      navigatorKey: globalNavigatorKey, // Use the global key

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/selector',

      routes: {
        '/selector': (context) => const AppSelectorScreen(),
        '/salesforce_login_page': (context) => const LoginScreen(),
      },

      onGenerateRoute: (settings) {
        // --- 1. Existing Salesman App ---
        if (settings.name == '/home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => NavScreen(employee: employee),
          );
        }

        // --- 2. Technical App ---
        if (settings.name == '/technical_home') {
          final employee = settings.arguments as Employee;
          return MaterialPageRoute(
            builder: (context) => TechnicalNavScreen(employee: employee),
          );
        }

        // --- 3. ✅ NEW: Notification Route (Bag Lift Approval) ---
        if (settings.name == '/approve_mason_bagLift') {
          // Get the ID sent from the Notification Payload
          final bagLiftId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) {
              // We need the 'Employee' object to build the screen.
              // Fetch it securely from storage (Auto-Login).
              return FutureBuilder<Employee?>(
                future: AuthService().tryAutoLogin(),
                builder: (context, snapshot) {
                  // A. Waiting for storage...
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // B. User Found! Open Screen + Auto-Dialog
                  if (snapshot.hasData && snapshot.data != null) {
                    return ApproveMasonBagLift(
                      employee: snapshot.data!,
                      highlightedId:
                          bagLiftId, // <--- Pass ID to auto-open dialog
                    );
                  }

                  // C. No User (Logged out)? Redirect to Login
                  return const LoginScreen();
                },
              );
            },
          );
        }

        return null;
      },
    );
  }
}
