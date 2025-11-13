Got it. I’ll **regenerate a full, expanded README** — not editing the previous one, but creating a **new improved version** (so you can replace the old one cleanly).

No sarcasm. No jokes. Just clean documentation.

Here it is:

---

````{"id":"63941","variant":"standard","title":"Employee Profile Screen - Detailed README"}
# Employee Profile Screen (Detailed Documentation)

This README provides a full technical overview of the **Employee Profile Screen**, including:
- UI structure
- Data fetching logic
- Dealer management bottom sheet
- Monthly performance chart
- Theme control integration
- Logout flow
- Code patterns and architectural decisions

## File Location

```
lib/screens/employee_management/employee_profile_screen.dart
```

---

## Purpose of This Screen

The Employee Profile screen serves as a **central dashboard** for an employee, showing:
- Who the employee is
- What they have done this month
- How they are performing overall
- Which dealers are assigned to them
- Available user actions (task shortcuts, dealer management, theme preference, logout)

This screen is typically accessible after user login, and is suitable for:
- Salesman / field executive dashboards
- Territory executive reporting profiles
- Manager role inspection (when used with different permissions)

---

## Architecture Overview

```
StatefulWidget: EmployeeProfileScreen
         |
         | initState()
         v
  Future<_ProfileStats> _fetchProfileStats()
         |
         v
     FutureBuilder
         |
      Builds UI
         |
         +-- Statistics Cards
         +-- Monthly Bar Chart
         +-- Dealer Management Bottom Sheet
         +-- Theme Toggle Control
         +-- Logout Button
```

The screen uses:
- `FutureBuilder` for async data rendering
- `Provider` for theme mode state
- `ApiService` for backend communication
- `Intl` for date boundaries
- `fl_chart` for visualizing performance

---

## Key Data Model

The screen aggregates data into a local helper class:

```dart
class _ProfileStats {
  final int monthlyReportCount;
  final int monthlyPjpCount;
  final int allTimeDealerCount;
  final int allTimeCompletedTasksCount;

  _ProfileStats({
    required this.monthlyReportCount,
    required this.monthlyPjpCount,
    required this.allTimeDealerCount,
    required this.allTimeCompletedTasksCount,
  });
}
```

This allows the UI to remain clean and expressive.

---

## Fetching Profile Statistics

### Date Range Calculation
To compute monthly statistics, the screen determines the first and last date of the current month:

```dart
final now = DateTime.now();
final firstDayOfMonth = DateTime(now.year, now.month, 1);
final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
```

These dates are formatted before calling APIs:

```dart
final formatter = DateFormat('yyyy-MM-dd');
final startDate = formatter.format(firstDayOfMonth);
final endDate = formatter.format(lastDayOfMonth);
```

### API Calls Made
The following async fetches run **in parallel**:

```dart
final results = await Future.wait([
  _apiService.fetchDvrsForUser(employeeId, startDate: startDate, endDate: endDate),
  _apiService.fetchTvrsForUser(employeeId, startDate: startDate, endDate: endDate),
  _apiService.fetchPjpsForUser(employeeId, startDate: startDate, endDate: endDate),
  _apiService.fetchDealers(userId: employeeId),
  _apiService.fetchDailyTasksForUser(employeeId, status: 'Completed'),
]);
```

This improves performance vs sequential fetching.

---

## UI Layout Structure

```
Column
 ├─ Profile Avatar + Name + Email
 ├─ Role Chip
 ├─ Statistics Grid (2x2)
 │    ├─ Reports This Month
 │    ├─ Manage Dealers
 │    ├─ PJPs
 │    ├─ Completed Tasks
 ├─ Monthly Performance Bar Chart
 ├─ 2 Quick Action Cards
 ├─ Theme Mode Segmented Toggle
 ├─ Logout Button
```

---

## Dealer Management Bottom Sheet

This sheet appears when tapping **Manage Dealers**.

### Fetching Dealers

```dart
_dealersFuture = _apiService.fetchDealers(
  userId: int.parse(widget.employee.id),
);
```

### Deleting a Dealer

```dart
await _apiService.deleteDealer(dealer.id!);
_refreshDealers(notifyParent: true);
```

After deletion, statistics are automatically refreshed.

---

## Performance Chart Implementation

The chart visually compares:
- Total monthly DVR + TVR reports
- Total monthly PJPs

```dart
_PerformanceChart(
  reportCount: stats.monthlyReportCount.toDouble(),
  pjpCount: stats.monthlyPjpCount.toDouble(),
);
```

The chart dynamically adjusts height bounds:

```dart
maxY: (maxValue) * 1.2 + 5
```

---

## Theme Mode Switching

The screen integrates with an app-wide `ThemeProvider`.

```dart
SegmentedButton<ThemeMode>(
  selected: { themeProvider.themeMode },
  onSelectionChanged: (selection) => themeProvider.setThemeMode(selection.first),
);
```

Modes supported:
- Light
- Dark
- System (Follows device preference)

---

## Logout Logic

```dart
await AuthService().logout();
Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
```

This ensures that:
- Session data is cleared
- No navigation backstack remains

---

## Error & Loading States

| State | Result |
|-------|--------|
| Data loading | CircularProgressIndicator |
| API error | Displays error message text |
| No dealers | Displays neutral "No dealers found" placeholder |
| Refresh gesture | Pull-to-refresh triggers `_refreshStats()` |

---

## Performance Considerations

- Statistics and dealers are fetched lazily.
- Parallel API calls reduce wait time.
- Dealer refresh is done only when needed.
- UI updates use `mounted` checks to avoid lifecycle issues.

---

## Possible Future Improvements

| Area | Suggestion |
|------|------------|
| Performance | Introduce caching layer for stats |
| UX | Add dealer search or pagination |
| Actions | Add "Add Dealer" button directly here |
| Permissions | Different UI depending on user role |

---

## Summary

The Employee Profile Screen is designed as a **compact, data-rich dashboard** that:
- Communicates activity
- Offers administrative control
- Supports personalization
- Encourages frequent app use

This implementation is **modular, maintainable, and easily extensible** for future growth.
````

---

**Developer Onboarding Guide**:
# Developer Onboarding Guide

### Employee Profile Screen

This guide helps new developers understand how to work with, modify, and extend the **Employee Profile Screen** located at:

```
lib/screens/employee_management/employee_profile_screen.dart
```

---

## 1. Prerequisites

Before working in this module, ensure you understand:

| Topic                               | Reason                                 |
| ----------------------------------- | -------------------------------------- |
| Flutter State Management (Provider) | Used for theme control                 |
| Async Operations + FutureBuilder    | UI depends on async API results        |
| Basic REST API Integration          | Data is fetched from backend services  |
| Widget tree composition in Flutter  | Screen UI is built with nested widgets |

If unfamiliar with any of these, review them briefly before making changes.

---

## 2. Core Responsibilities of This Screen

This screen functions as a **dashboard** for an employee. It:

1. Fetches monthly performance data.
2. Displays key performance statistics (Reports, PJPs, Completed Tasks).
3. Lists and allows management of assigned dealers.
4. Renders a monthly performance bar chart.
5. Provides access to quick actions and logout.
6. Allows switching between Light, Dark, and System theme modes.

---

## 3. Data Sources

All data is retrieved via the **ApiService** class.

### API Methods Invoked

| Data                                  | Method                   | Parameters             |
| ------------------------------------- | ------------------------ | ---------------------- |
| DVRs (Daily Visit Reports)            | `fetchDvrsForUser`       | employeeId, date range |
| TVRs (Technical Visit Reports)        | `fetchTvrsForUser`       | employeeId, date range |
| PJPs (Permanent Journey Plan entries) | `fetchPjpsForUser`       | employeeId, date range |
| Dealers assigned to employee          | `fetchDealers`           | userId (employeeId)    |
| Completed tasks                       | `fetchDailyTasksForUser` | employeeId, status     |

**Important:**
`employee.id` is a **String**, but API expects **int**.
Always convert with:

```dart
final employeeId = int.parse(widget.employee.id);
```

---

## 4. State and Rendering Flow

```
initState()
   ↓
_fetchProfileStats()
   ↓  (async parallel API calls)
FutureBuilder()
   ↓
UI rendered with stats & charts
```

The UI updates when:

* Screen refreshes via pull-to-refresh
* Dealer list changes inside the bottom sheet

---

## 5. Dealer Management Bottom Sheet

The `Manage Dealers` section opens a scrollable modal sheet:

```dart
showModalBottomSheet(
  isScrollControlled: true,
  builder: (_) => _ManageDealersContent(...),
);
```

### Where to modify dealer logic:

| Task                          | Location                        |
| ----------------------------- | ------------------------------- |
| Change UI list of dealers     | `_ManageDealersContent.build()` |
| Edit dealer behavior          | `_editDealer()`                 |
| Delete dealer behavior        | `_deleteDealer()`               |
| Re-fetch dealers after change | `_refreshDealers()`             |

---

## 6. Performance Chart

The chart compares **Reports vs PJPs** using `fl_chart`.

To adjust colors, labels, or animation:

```dart
_PerformanceChart()
```

Refer to:

```
barGroups → _makeBarGroup()
titlesData → bottomTitles section
```

---

## 7. Theme Mode Integration

Theme mode is managed via `ThemeProvider`.

To modify theme behavior:

```
lib/widgets/theme_provider.dart
```

To modify the toggle UI:

```
SegmentedButton<ThemeMode> in build() method
```

---

## 8. Safe Navigation and Refresh Patterns

The screen frequently checks:

```dart
if (mounted) setState(() { ... });
```

This prevents Flutter from calling UI rebuilds after disposal.

When refreshing data manually:

```dart
await _refreshStats();
```

---

## 9. Extending the Screen

| Goal                          | Where to Modify                                 | Notes                                      |
| ----------------------------- | ----------------------------------------------- | ------------------------------------------ |
| Add a new statistic tile      | Add new `_StatCard` under stats section         | Ensure data is included in `_ProfileStats` |
| Add a new quick action        | Modify `_ActionCard` row at bottom              | Make sure navigation route exists          |
| Add a new chart               | Create another widget below `_PerformanceChart` | Prefer lazy loading if expensive           |
| Allow editing profile details | Add button below profile section                | Should navigate to new edit screen         |

---

## 10. Code Safety Rules

1. Always convert `employee.id` → `int.parse(...)`.
2. Use `mounted` checks when calling `setState()`.
3. When modifying API calls, ensure backend date format remains `yyyy-MM-dd`.
4. Avoid placing heavy work in `build()`; use memoized or Future-based values.

---

## 11. Quick Orientation Checklist (Start Here)

| Step | Action                                                     |
| ---- | ---------------------------------------------------------- |
| 1    | Open the screen file and locate `build()` method           |
| 2    | Scroll to `_fetchProfileStats()` to understand data source |
| 3    | Review `_ManageDealersContent` to understand dealer logic  |
| 4    | Review `_PerformanceChart` to understand graph rendering   |
| 5    | Test UI in-app and verify theme toggle + refresh behaviors |

---

This completes the onboarding guide. Developers should now be comfortable navigating and extending this screen.


