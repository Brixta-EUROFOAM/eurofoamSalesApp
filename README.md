
├── frontend/
│   ├── app/            # Main Flutter application
│   │   ├── lib/
│   │   │   ├── api/          # Centralized API service classes
│   │   │   │   ├── api_service.dart      # Main data service (CRUD)
│   │   │   │   ├── auth_service.dart     # TSO/Employee auth
│   │   │   │   └── firebase_auth.dart    # Mason auth
│   │   │   │
│   │   │   ├── models/       # Data models (PODOs)
│   │   │   │   ├── employee_model.dart
│   │   │   │   ├── mason_model.dart
│   │   │   │   ├── pjp_model.dart
│   │   │   │   ├── dealer_model.dart
│   │   │   │   ├── daily_visit_report_model.dart
│   │   │   │   ├── technical_visit_report_model.dart
│   │   │   │   └── ... (all other models)
│   │   │   │
│   │   │   ├── screens/      # All application screens, organized by portal
│   │   │   │   ├── mason/    # Contractor Portal (from 'lib/screens/contractor/')
│   │   │   │   │   ├── contractor_nav_screen.dart
│   │   │   │   │   ├── contractor_home_screen.dart
│   │   │   │   │   ├── contractor_jobs_screen.dart
│   │   │   │   │   ├── contractor_gift_screen.dart
│   │   │   │   │   ├── contractor_profile_screen.dart
│   │   │   │   │   ├── kyc_onboarding_screen.dart
│   │   │   │   │   └── kyc_pending_screen.dart
│   │   │   │   │
│   │   │   │   ├── SALESFORCE/      # SALESFORCEEmployee Portal (from 'lib/screens/employee_management/')
│   │   │   │   │   ├── nav_screen.dart
│   │   │   │   │   ├── employee_dashboard_screen.dart
│   │   │   │   │   ├── employee_pjp_screen.dart
│   │   │   │   │   ├── employee_journey_screen.dart
│   │   │   │   │   ├── employee_salesorder_screen.dart
│   │   │   │   │   └── bulk_pjp_wizard_screen.dart
│   │   │   │   │
│   │   │   │   ├── admin/    # TSO Admin Portal (from 'lib/screens/admin/')
│   │   │   │   │   ├── admin_nav_screen.dart
│   │   │   │   │   ├── admin_dashboard_screen.dart
│   │   │   │   │   ├── admin_kycdetails.dart
│   │   │   │   │   └── admin_login.dart
│   │   │   │   │
│   │   │   │   └── shared/   # Screens/widgets shared by all portals
│   │   │   │       ├── app_selector_screen.dart  # Root app selection
│   │   │   │       ├── login_screen.dart         # TSO login form
│   │   │   │       ├── contractor_login_screen.dart
│   │   │   │       ├── salesforce_splash_screen.dart
│   │   │   │       ├── create_dvr.dart           # From 'lib/screens/forms/'
│   │   │   │       ├── create_tvr.dart           # From 'lib/screens/forms/'
│   │   │   │       ├── add_dealer_form.dart      # From 'lib/screens/forms/'
│   │   │   │       └── ... (all other forms)
│   │   │   │
│   │   │   ├── widgets/      # Reusable UI components
│   │   │   │   ├── pjp_cards.dart
│   │   │   │   ├── reusableglasscard.dart
│   │   │   │   └── ... (other shared widgets)
│   │   │   │
│   │   │   ├── providers/    # State management (Provider, Riverpod, etc.)
│   │   │   │   ├── theme_provider.dart   # (Moved from 'lib/widgets/')
│   │   │   │   └── NavProvider.dart      # (Note: Should be extracted from nav_screen dart)
│   │   │   │
│   │   │   ├── theme/        # App theme definitions
│   │   │   │   └── app_theme.dart        # (Moved from 'lib/widgets/')
│   │   │   │
│   │   │   ├── main.dart     # App entry point
│   │   │   └── firebase_options.dart
│   │   │
│   │   └── pubspec.yaml
│
└── PROJECT_STRUCTURE.md  # This file
│
└── README.md                 # The main project README