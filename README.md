# Asset Archiver: Sales Force Management App

## 1\. Overview

This is a comprehensive, enterprise-grade mobile application for managing a field sales force, built with Flutter. The app provides a full suite of tools for employees, from daily attendance and journey planning to live location tracking, AI-powered sales assistance, and detailed site reporting.

The application is designed around a "check-in, plan, execute, report" workflow, enabling sales personnel to manage their daily tasks efficiently while providing management with real-time data and oversight. It connects to a robust backend API for data synchronization, image uploads, and authentication.

## 2\. Core Features

### Authentication & Security

  * **JWT-based Auth:** User login is handled via `loginId` and `password`, which returns a JSON Web Token (JWT).
  * **Secure Storage:** The JWT is stored securely on the device using `flutter_secure_storage`.
  * **Auto-Login:** The app automatically attempts to log the user in on startup by validating the stored token.
  * **Profile Fetching:** After login, the app fetches the user's detailed profile, including their `role`, `companyName`, and `displayName`.

### Main Navigation (`NavScreen`)

After logging in, the user is presented with a main navigation screen that includes a floating bottom navigation bar and a side drawer for quick actions.

**Five Main Tabs:**

1.  **Home:** The main `EmployeeDashboardScreen`.
2.  **PJP:** `EmployeePJPScreen` for managing "Personal Journey Plans".
3.  **Sales Order:** An AI-powered chatbot for placing orders.
4.  **Journey:** The `EmployeeJourneyScreen` for live map tracking.
5.  **Profile:** The `EmployeeProfileScreen` for stats, settings, and logout.

**Quick Actions (Side Drawer):**

  * Add Dealer
  * Create DVR (Daily Visit Report)
  * Create TVR (Technical Visit Report)
  * Competition Form
  * Apply for Leave
  * Create Daily Task

-----

## 3\. Feature Deep-Dive

#### 3.1. Home & Attendance (`EmployeeDashboardScreen`)

  * **Daily Check-In / Check-Out:**
      * Requires the user to capture a live photo (front camera) using `image_picker`.
      * Captures the user's precise GPS location using `geolocator`.
      * Uploads the image to an R2 bucket via the `api_service.uploadImageToR2`.
      * Submits the attendance record (In-Time/Out-Time, location, image URL) to the backend `api_service.checkIn`/`checkOut`.
  * **PJP Overview:** Displays a summary card of the user's pending PJPs for the day using a `FutureBuilder`.
  * **Greeting:** Provides a time-based greeting (e.g., "Good Morning, [Name]").

#### 3.2. PJP - Journey Planning (`EmployeePJPScreen`)

"PJP" (Personal Journey Plan) is the core planning feature.

  * **PJP List:** Fetches and displays a list of all `pending` PJPs assigned to the user using `api_service.fetchPjpsForUser`.
  * **Start Journey:** Users can swipe a PJP item using `flutter_slidable` to reveal a "Start Journey" button.
  * **Start Action:** This action (1) updates the PJP status to "started" via the API and (2) calls the `onStartJourney` callback, which navigates the user to the **Journey** tab, passing the destination coordinates and display name.
  * **Create PJP:** A `FloatingActionButton` allows users to create a new PJP by selecting from their list of registered dealers in a modal bottom sheet.

#### 3.3. Live Journey Tracking (`EmployeeJourneyScreen`)

This is the most complex screen in the app, integrating multiple services for live tracking.

  * **Map Interface:** Uses **MapLibre GL** with **Stadia Maps** tiles to display a live map.
  * **Route Drawing:** When a journey starts, it fetches a route from the **Radar** API and draws the suggested polyline on the map.
  * **Live Location:** Uses `Geolocator.getPositionStream()` to get high-accuracy, continuous location updates. The user's location is shown as a seamless blue dot.
  * **Distance Calculation:** The app calculates the distance traveled *locally* by summing the `Geolocator.distanceBetween` results from the position stream. This avoids high API costs.
  * **Arrival Detection:**
    1.  A `Timer` periodically calls `Radar.trackOnce()`.
    2.  A listener for Radar's `user.entered_geofence` event checks if the geofence's `externalId` matches the current `_currentPjpId`.
    3.  If a match occurs, the journey is considered complete, and `_showDestinationArrivalNotification` is called.
  * **Journey Lifecycle:**
      * **Start:** A `FlutterLocalNotificationsPlugin` is used to show a *foreground service notification* (`ongoing: true`), ensuring the app continues tracking in the background. The Radar arrival timer is started.
      * **Stop (Manual or Auto):** When the user slides to stop or arrival is detected, the app (1) stops the timer, (2) cancels the notification, (3) updates the PJP status to "completed" via the API, and (4) sends *one final* `GeoTrackingPoint` to the backend containing the total distance traveled.
  * **Navigation:** A "NAVIGATE" button uses `url_launcher` to open Google Maps for turn-by-turn navigation (`google.navigation:q=$lat,$lng`).

#### 3.4. AI Sales Assistant (`SalesOrderScreen`)

  * **Chat Interface:** Provides a full chat UI for placing sales orders.
  * **AI Bot:** Titled "CemTemBot," this feature connects to a separate Python AI agent (`https://python-ai-agent.onrender.com`) using `socket_io_client`.
  * **Persistence:** Chat history is saved locally on the device using **Hive**. The `ChatMessage` class is a `HiveObject`, and `employee_salesorder_screen.g.dart` is the generated `TypeAdapter`.
  * **Real-time:** Listens for socket events to show connection status, typing indicators (`status`), and new bot messages (`bot_message`).

#### 3.5. Profile & Settings (`EmployeeProfileScreen`)

  * **User Stats:** Fetches and displays key performance indicators by calling multiple API endpoints in `Future.wait` (e.g., `fetchDvrsForUser`, `fetchPjpsForUser`).
  * **Performance Chart:** Uses `fl_chart` to render a bar chart comparing monthly reports and PJPs.
  * **Dealer Management:** A "Manage Dealers" card opens a modal sheet where a user can see their dealer list and delete entries.
  * **Theme Customization:** A `SegmentedButton` allows the user to toggle between **Light**, **Dark**, and **System** theme modes. The choice is saved to `SharedPreferences` via the `ThemeProvider`.
  * **Logout:** A button that securely logs the user out by calling `AuthService().logout()`, which deletes the JWT from secure storage.

-----

## 4\. Data Reporting & Forms

The app features a robust set of forms for field data collection, which open as blurred-background `Dialog`s.

  * **Add Dealer Form (`add_dealer_form.dart`):**

      * A comprehensive, multi-section form for registering new dealers, using `ExpansionTile`s to organize UI.
      * Uses `Radar` and `Geolocator` to fetch the user's current location and auto-fill address, region, area, and PIN code fields.
      * Supports "Dealer" vs. "Sub-Dealer" types, allowing a user to select a "Parent Dealer" if "Sub-Dealer" is chosen.
      * Submits the new `Dealer` object to the API, including an optional `radius` for creating a geofence.

  * **Create DVR (`create_dvr.dart`) - Daily Visit Report:**

      * **Workflow:** 1. Select a Dealer -\> 2. Check-In (capture/upload photo) -\> 3. Fill form (potential, order, collection, feedback) -\> 4. Submit & Check-Out (capture/upload photo).
      * **Location Verification:** On submission, the app *verifies* the user's location is within **200 meters** of the selected dealer's saved coordinates using `Geolocator.distanceBetween`. If the distance is too great, it throws an exception and stops the submission.

  * **Create TVR (`create_tvr.dart`) - Technical Visit Report:**

      * **Workflow:** 1. Fill Site Name/Phone -\> 2. Check-In (capture/upload photo + get location) -\> 3. Fill form (visit type, remarks) -\> 4. Submit & Check-Out (capture/upload photo).
      * **Location Prepending:** The captured GPS coordinates (`_capturedLocation`) are automatically prepended to the "Salesperson Remarks" field before submission.

  * **Create Daily Task Form (`create_daily_task_form.dart`):**

      * Allows users to create tasks for "Dealer Visit", "Site Visit", "Office Work", etc..
      * If "Dealer Visit" is chosen, the form smartly displays a dropdown of the user's *pending PJPs for that day*, allowing the task to be linked to a PJP.
      * Includes a button to open the `AddPjpForm` in a modal if the required PJP isn't listed.

  * **Create Leave Form (`create_leave_form.dart`):**

      * A simple form to apply for leave with a type, start/end date, and reason. Submits with a "Pending" status.
      * Includes date validation to ensure the end date cannot be before the start date.

  * **Create Competition Form (`create_competition_form.dart`):**

      * A form to report on competitor activities, capturing brand name, billing, retail info, and scheme details.

-----

## 5\. Core Technologies & Stack

  * **Language:** Dart
  * **Framework:** Flutter
  * **State Management:** `ChangeNotifier` / `Provider` (for `ThemeProvider` and `NavProvider`)
  * **API / Backend:**
      * **Backend URL:** `https://myserverbymycoco.onrender.com`
      * **AI Chatbot URL:** `https://python-ai-agent.onrender.com`
  * **Routing:** `Navigator 1.0` (standard `routes` and `onGenerateRoute`)
  * **Local Storage:**
      * `flutter_secure_storage`: For the JWT.
      * `hive_flutter`: For persisting the AI chat history.
      * `shared_preferences`: For saving the user's theme preference.
  * **Location & Maps:**
      * `geolocator`: For GPS location and distance calculation.
      * `maplibre_gl`: For map rendering.
      * `flutter_radar`: For geofencing, arrival detection, and reverse geocoding.
      * `Stadia Maps`: As the map tile provider.
  * **Key Packages:**
      * `http`: For all API communication.
      * `socket_io_client`: For the AI chatbot websocket connection.
      * `image_picker`: For capturing photos.
      * `fl_chart`: For the profile performance chart.
      * `flutter_local_notifications`: For the journey tracking foreground service.
      * `url_launcher`: For opening Google Maps.
      * `flutter_dotenv`: For managing API keys.
      * `flutter_slidable`: For the PJP list "Start Journey" action.

-----

## 6\. Project Structure

```
lib/
├── api/
│   ├── api_service.dart       # Main service for all data models (CRUD)
│   └── auth_service.dart      # Handles login, logout, auto-login, JWTs
│
├── main.dart                  # App entry point, theme setup, auth logic
│
├── models/                    # Data models with fromJson/toJson
│   ├── attendance_model.dart
│   ├── brand_mapping_model.dart
│   ├── brand_model.dart
│   ├── competition_report_model.dart
│   ├── daily_task_model.dart
│   ├── daily_visit_report_model.dart
│   ├── dealer_model.dart      # Very large model with 50+ fields
│   ├── employee_model.dart
│   ├── geotracking_data_model.dart # For sending GPS points
│   ├── leave_application_model.dart
│   ├── pjp_model.dart         # Personal Journey Plan
│   ├── sales_order_model.dart
│   └── technical_visit_report_model.dart
│
├── screens/
│   ├── auth/
│   │   └── login_screen.dart    # Login UI
│   │
│   ├── employee_management/
│   │   ├── employee_dashboard_screen.dart  # "Home" tab (Check-in/out)
│   │   ├── employee_journey_screen.dart    # "Journey" (Map) tab
│   │   ├── employee_pjp_screen.dart        # "PJP" tab (Planning)
│   │   ├── employee_profile_screen.dart    # "Profile" tab (Stats/Settings)
Example
│   │   ├── employee_salesorder_screen.dart # "Sales Order" (Chat) tab
│   │   └── employee_salesorder_screen.g.dart # Generated Hive adapter for chat
│   │
│   ├── forms/
│   │   ├── add_dealer_form.dart    # Add Dealer dialog
│   │   ├── create_competition_form.dart # Competition Report dialog
│   │   ├── create_daily_task_form.dart # Daily Task dialog
│   │   ├── create_dvr.dart         # DVR (Daily Visit Report) dialog
│   │   ├── create_leave_form.dart  # Apply for Leave dialog
│   │   └── create_tvr.dart         # TVR (Technical Visit Report) dialog
│   │
│   └── nav_screen.dart            # Main 5-tab scaffold/container
│
└── widgets/
    ├── app_theme.dart             # Defines light/dark themes
    ├── reusableglasscard.dart     # (Deprecated) Old glass UI
    └── theme_provider.dart        # Manages theme state & persistence
```

-----