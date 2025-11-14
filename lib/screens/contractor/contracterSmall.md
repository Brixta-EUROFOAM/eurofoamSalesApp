# KYC Onboarding & Pending Screens — README

You gave me two Flutter screens — **`KycOnboardingScreen`** (the form + upload + submit flow) and **`KycPendingScreen`** (the “sit tight, we’re looking at it” screen). This README explains them *to the core*: imports, dependencies, wiring, control flow, sample payloads, backend contract, navigation, edge cases, recommended fixes, test curl commands, and copy-paste code snippets so you don’t end up guessing in the dark. I’ll be blunt when something smells like a race condition or a token bug.

---

## Table of contents

1. Overview & purpose
2. Files, classes and responsibilities
3. Dependencies & imports (what must be in `pubspec.yaml`)
4. App-level integration & routing examples
5. KYC Onboarding — end-to-end flow (detailed)
6. KYC Pending — how it works & why you need it
7. API contracts & sample payloads (what backend must support)
8. `ApiService` integration points (exact calls)
9. Auth / Firebase logout detail (MasonAuth usage)
10. UI/UX notes, error handling, and edge cases
11. Debugging & testing (curl, jq, emulator notes)
12. Performance, concurrency & race conditions — what to fix now
13. Recommended improvements & checklist
14. Appendix — code snippets you can copy-paste

---

## 1 — Overview & purpose

* **KycOnboardingScreen**: collects optional Aadhaar/PAN/Voter IDs plus images, uploads images (R2/multipart), creates or updates a `Mason` record, and submits a KYC submission. Has a debug bypass mode for offline testing.
* **KycPendingScreen**: shows “pending” state, allows pull-to-refresh to check KYC status by calling `ApiService.fetchMasonById(id)`, and logs out via `MasonAuth.AuthService.logout()`.

These screens are designed to work with the `ApiService` you already built and the `Mason` model.

---

## 2 — Files, classes and responsibilities

* `lib/screens/kyc/kyc_onboarding_screen.dart`

  * Class: `KycOnboardingScreen extends StatefulWidget`
  * Responsibilities: image picking, validation, uploading files, building `Mason` payload, calling `ApiService.createMason` and `ApiService.submitKyc`, navigating to home on success.

* `lib/screens/kyc/kyc_pending_screen.dart`

  * Class: `KycPendingScreen extends StatefulWidget`
  * Responsibilities: show pending UI, allow pull-to-refresh to check status, call `ApiService.fetchMasonById`, navigate to home on approval, provide logout via `MasonAuth.AuthService`.

* Models:

  * `lib/models/mason_model.dart` — `Mason` model with `fromJson`, `toJson`, `copyWith`.
  * `lib/models/employee_model.dart` — used elsewhere (admin flows) and for constructing masons via `Mason.fromEmployee`.

* API surface (used):

  * `ApiService.uploadImageToR2(File)` — returns a public URL
  * `ApiService.createMason(Mason)` — POST `/api/masons` -> returns created `Mason`
  * `ApiService.submitKyc({ masonId, aadhaarNumber, panNumber, voterIdNumber, documents, remark })` — POST `/api/kyc-submissions`
  * `ApiService.fetchMasonById(masonId)` — GET `/api/masons/:id`

---

## 3 — Dependencies & imports

Add these to `pubspec.yaml` if not present:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^0.8.7
  http: ^0.13.6
  flutter_dotenv: ^5.0.2     # if you use env variables elsewhere
  path: ^1.8.3               # optional: used for Multipart filename handling
  flutter_secure_storage: ^8.0.0 # recommended for token persistence (optional)
```

Top-of-file imports required by the screens:

```dart
import 'dart:io';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth; // for logout
```

---

## 4 — App-level integration & routing

Register routes (example `main.dart`) so navigation works:

```dart
routes: {
  '/kyc_onboarding': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Mason) return KycOnboardingScreen(mason: args);
    return Scaffold(body: Center(child: Text('Mason required')));
  },
  '/kyc_pending': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Mason) return KycPendingScreen(mason: args);
    return Scaffold(body: Center(child: Text('Mason required')));
  },
  '/contractor_home': (context) => ContractorHome(), // implement accordingly
  '/selector': (context) => SelectionScreen(),
}
```

Navigation examples:

* After submit success (from onboarding), go to pending or home:

```dart
Navigator.of(context).pushNamedAndRemoveUntil('/contractor_home', (_) => false, arguments: createdMason);
```

* To show pending screen from onboarding:

```dart
Navigator.of(context).pushReplacementNamed('/kyc_pending', arguments: createdMason);
```

---

## 5 — KYC Onboarding — end-to-end flow (detailed)

1. **UI collects inputs**: optional text inputs for Aadhaar, PAN, Voter ID; optional TSO user ID; optional remark; image pickers for Aadhaar front/back, PAN, Voter.

2. **Validation**: minimal — max length checks, numeric check for TSO; controlled by `_formKey`.

3. **Toggle**: `_useRealKyc` — if `false`: bypass flow, simulate success, set `kycStatus='pending'` and navigate to `/contractor_home` with simulated `Mason`.

4. **Real flow (when `_useRealKyc==true`)**:

   * a. Upload images: call `_uploadIfPresent(File) => ApiService.uploadImageToR2(file)` for each attached file. These return public URLs or throw.
   * b. Build `documents` map with keys: `aadhaarFrontUrl`, `aadhaarBackUrl`, `panUrl`, `voterUrl`.
   * c. Build `completeMason` via `_localMason.copyWith(...)` with `kycStatus: 'pending'`, `userId` from TSO (if provided), doc name/id set from Aadhaar if present.
   * d. **Create mason**: prepare payload via `completeMason.toJson()` and remove `id` field. Call `_api.createMason(Mason.fromJson(payload))`.
   * e. **Submit KYC**: call `_api.submitKyc(masonId: createdMason.id, aadhaarNumber: .., panNumber: .., documents: documents, remark: ..)`.
   * f. Navigate to `/contractor_home` passing `createdMason` object.

> **Note**: Your code currently calls create and submit in parallel then expects `createMason` to return an ID. That works only if `submitKyc` does not *require* the created mason ID, or if the backend accepts client-supplied IDs. Safer sequence: create -> await -> get id -> submit.

---

## 6 — KYC Pending — how it works & why you need it

* Designed to show when `kycStatus == 'pending'`.
* Pull-to-refresh calls `_api.fetchMasonById(widget.mason.id!)`:

  * If `kycStatus == 'approved'` → show success snackbar and navigate to `/contractor_home` with updated mason.
  * Otherwise show 'still pending' toast.
* Includes Logout button calling `MasonAuth.AuthService(...).logout()` and navigates to '/selector'.

**Why this screen exists**: avoid the user guessing; give a single place to poll for status and a clean logout path. Good UX.

---

## 7 — API contracts & sample payloads

### Upload endpoint (multipart)

* Endpoint: `POST /api/r2/upload-direct` (or `/api/upload`)
* Request: multipart/form-data with field `file`
* Response: `200` with JSON — example:

```json
{ "success": true, "publicUrl": "https://r2.cdn.example/abcd.jpg" }
```

### Create Mason

* Endpoint: `POST /api/masons`
* Request JSON (camelCase):

```json
{
  "name": "Ravi",
  "phoneNumber": "+919876543210",
  "kycStatus": "pending",
  "kycDocumentName": "Aadhaar Card",
  "kycDocumentIdNum": "123412341234",
  "userId": 42,
  "documents": {
    "aadhaarFrontUrl": "https://...",
    "aadhaarBackUrl": "https://..."
  }
}
```

* Response `201`:

```json
{ "success": true, "data": { "id": "87", "name": "Ravi", ... } }
```

### Submit KYC

* Endpoint: `POST /api/kyc-submissions`
* Request:

```json
{
  "masonId": "87",
  "aadhaarNumber": "123412341234",
  "panNumber": "ABCDE1234F",
  "voterIdNumber": "B1234567",
  "documents": { "aadhaarFrontUrl": "...", "panUrl": "..." },
  "remark": "Submitted from Android"
}
```

* Response `201`:

```json
{ "success": true, "data": { "id": "250", "masonId": "87", "status": "pending" } }
```

### Fetch Mason by ID

* Endpoint: `GET /api/masons/:id`
* Response:

```json
{ "success": true, "data": { "id": "87", "name": "Ravi", "kycStatus": "approved" } }
```

---

## 8 — ApiService integration points (exact calls)

* Upload file:

```dart
final url = await _api.uploadImageToR2(file);
```

* Create mason:

```dart
final payload = completeMason.toJson()..remove('id');
final created = await _api.createMason(Mason.fromJson(payload));
```

* Submit KYC (recommended sequential version):

```dart
final created = await _api.createMason(Mason.fromJson(payload));
await _api.submitKyc(
  masonId: created.id!,
  aadhaarNumber: _aadhaarController.text.trim(),
  panNumber: _panController.text.trim(),
  voterIdNumber: _voterController.text.trim(),
  documents: documents,
  remark: _remarkController.text.trim(),
);
```

* Fetch mason by id:

```dart
final updated = await _api.fetchMasonById(masonId);
```

**Important**: ensure `createMason` returns the `id` in `created.id` or change API to return it. Your `Mason` model handles `id` as string.

---

## 9 — Auth / Firebase logout detail (MasonAuth usage)

* You import the firebase auth helper with a prefix:

```dart
import 'package:assetarchiverflutter/api/firebase_auth.dart' as MasonAuth;
```

* You call logout like:

```dart
MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
```

**Notes**:

* `AuthService.logout()` must:

  * clear local token storage (call `ApiService.clearAuthToken()` or clear secure storage),
  * sign out from Firebase if used,
  * optionally notify server (revoke session).
* Ensure the `AuthService` constructor works with `baseUrl` and `logout()` is synchronous or `await`able if necessary.

---

## 10 — UI/UX notes, error handling, and edge cases

* **Empty images**: you handle nulls. Good.
* **Image size & compression**: `imageQuality: 80` is used. Consider further client-side compression if users have slow networks.
* **Timeouts / long uploads**: multipart upload can take > 90s for flaky networks — add retry/backoff or chunked upload if needed.
* **Form validation**: you only check max length and numeric TSO. Consider Aadhaar format regex, PAN pattern, etc., if needed.
* **Disabled submit**: you use `_isSubmitting` to prevent duplicate taps. Good.
* **Offline flows**: if the network is down, save upload tasks in a queue and retry in background (future improvement).
* **Error messages**: show actionable messages — e.g., "Upload failed: server returned 401 — please login".

---

## 11 — Debugging & testing (curl, jq, emulator notes)

### Upload test:

```bash
curl -X POST "http://localhost:8000/api/r2/upload-direct" \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@/path/to/aadhaar.jpg" | jq .
```

### Create Mason test:

```bash
curl -X POST "http://localhost:8000/api/masons" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"name":"Test","phoneNumber":"+919876543210","kycStatus":"pending"}' | jq .
```

### Submit KYC test:

```bash
curl -X POST "http://localhost:8000/api/kyc-submissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"masonId":"87","aadhaarNumber":"123412341234","documents":{"aadhaarFrontUrl":"https://..."} }' | jq .
```

### Emulator network notes

* Android emulator: use `http://10.0.2.2:8000` instead of `localhost`.
* iOS simulator: `http://localhost:8000` works.

---

## 12 — Performance, concurrency & race conditions — what to fix now

You currently call `createMason` and `submitKyc` in parallel and assume `completeMason.id` exists for `submitKyc`. That’s unsafe.

**Fix: sequential flow (recommended)**

```dart
final payload = completeMason.toJson()..remove('id');
final createdMason = await _api.createMason(Mason.fromJson(payload));
await _api.submitKyc(
  masonId: createdMason.id!,
  aadhaarNumber: ...,
  documents: documents,
  remark: ...
);
```

**If you insist on parallelism**:

* Only parallelize *independent* calls.
* Or have backend accept the same request in a single endpoint: `POST /api/masons-with-kyc` — server creates mason and submission atomically.

---

## 13 — Recommended improvements & checklist

* [ ] Make `_useRealKyc` a runtime toggle (developer settings) not a code constant.
* [ ] Ensure `ApiService.createMason` returns an ID and `Mason.id` is non-null for created records.
* [ ] Remove the `!` suffix in auth header building (if present in ApiService).
* [ ] Persist auth token using `flutter_secure_storage` on login; call `ApiService.setAuthToken(token)` on startup.
* [ ] Improve UX: image upload progress, per-file retry, skeleton loaders.
* [ ] Add more validation for Aadhaar/PAN patterns if needed.
* [ ] Consider single atomic backend endpoint for create+submit to avoid races.
* [ ] Add unit tests for `Mason.fromJson`, and widget tests for both screens.

---

## 14 — Appendix — copy-paste code snippets

### Safe sequential submit (replace the parallel block in `_submitKyc`)

```dart
// 4) Create mason
final payload = completeMason.toJson()..remove('id');
final createdMason = await _api.createMason(Mason.fromJson(payload));

// 5) Submit KYC using createdMason.id
await _api.submitKyc(
  masonId: createdMason.id!,
  aadhaarNumber: _aadhaarController.text.trim(),
  panNumber: _panController.text.trim(),
  voterIdNumber: _voterController.text.trim(),
  documents: documents,
  remark: _remarkController.text.trim(),
);
```

### Toast helper (already present — reusable)

```dart
void _toast(String m) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
```

### Logout (ensure token cleared server-side + client):

```dart
Future<void> _logout() async {
  try {
    await MasonAuth.AuthService(baseUrl: 'https://myserverbymycoco.onrender.com').logout();
  } catch (e) {
    // ignore logout errors, still clear client state
  } finally {
    // Clear local tokens
    ApiService.clearAuthToken();
    // navigate to selector
    Navigator.of(context).pushNamedAndRemoveUntil('/selector', (r) => false);
  }
}
```

### Add optional progress indicator for uploads (very small example)

```dart
// Use a package like dio for progress or stream the multipart to track bytes.
// Minimal: show a modal dialog while uploading
showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator()));
// after complete: Navigator.of(context).pop();
```

---

## Final words (sharp but useful)

These two screens are solid — they do the job, are easy to read, and wire nicely to your `ApiService` and `Mason` model. Fix the create/submit ordering and make sure your upload and auth headers are correct. Add progress & retry for uploads later, or your users will suffer when on a bad 2G connection.

If you want, I’ll rewrite `_submitKyc` to use the safer sequential flow and add a progress dialog, plus a small `Developer Settings` toggle for `_useRealKyc`. Want that? Say the word (but don’t say the word).
