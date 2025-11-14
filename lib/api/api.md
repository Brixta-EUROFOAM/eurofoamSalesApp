# ApiService & KYC Flow — README

You handed me a beast: a central `ApiService` in Dart that powers a mobile app (masons, dealers, KYC, uploads, PJP, etc.) plus a `KycOnboardingScreen` that uploads documents and kicks off KYC. This README explains everything **to the core** — how the pieces fit, what each method does, expected backend contract, sample code snippets, debugging tips, and a clear path for the next files you said you’ll drop. I’ll be blunt where things will bite you; I’ll also give copy-paste-ready snippets so you don’t waste another hour guessing.

---

## Table of contents

1. [High-level architecture & flow](#high-level-architecture--flow)
2. [File layout & responsibilities](#file-layout--responsibilities)
3. [Core design decisions & contracts](#core-design-decisions--contracts)
4. [Environment and configuration](#environment-and-configuration)
5. [ApiService internals — explanation and examples](#apiservice-internals----explanation-and-examples)
6. [KYC flow & KycOnboardingScreen integration](#kyc-flow--kyconboardingscreen-integration)
7. [Key endpoints & sample payloads (copy/paste)](#key-endpoints--sample-payloads-copypaste)
8. [Auth, state & token handling](#auth-state--token-handling)
9. [Concurrency gotchas & recommended fixes](#concurrency-gotchas--recommended-fixes)
10. [Testing & debugging (curl, jq, emulator NOTES)](#testing--debugging-curl-jq-emulator-notes)
11. [Error handling & UX suggestions](#error-handling--ux-suggestions)
12. [Security & production checklist (don’t skip)](#security--production-checklist-dont-skip)
13. [Next files you promised — what I’ll do for them](#next-files-you-promised---what-ill-do-for-them)
14. [Appendix: helper snippets and tiny utilities](#appendix-helper-snippets-and-tiny-utilities)

---

## High-level architecture & flow

Short version: mobile UI → `ApiService` → backend REST APIs → DB / object store (R2/S3). `KycOnboardingScreen` hands files and metadata to `ApiService`, which:

1. uploads images to an upload endpoint (`/api/r2/upload-direct`), returning public URLs;
2. builds a `Mason` payload and calls `POST /api/masons`;
3. calls `POST /api/kyc-submissions` with the mason ID and document metadata.

Your current code sometimes runs (2) and (3) in parallel. That only works if the backend either:

* accepts a mason payload without creating a new ID (id supplied by client), or
* `submitKyc` doesn't require `masonId` (unlikely).

If backend requires created `masonId`, change flow: create mason, read id, then submit KYC.

---

## File layout & responsibilities

Suggested working layout (what you already have):

```
lib/
  api/
    api_service.dart         # central Http client + helpers (this file)
  models/
    mason_model.dart
    dealer_model.dart
    pjp_model.dart
    daily_task_model.dart
    attendance_model.dart
    ...                       # other domain models
  screens/
    contractor/
      kyc_onboarding_screen.dart
```

Responsibility summary:

* `api_service.dart`: single source of truth for network. Wraps GET/POST/PATCH/DELETE and multipart upload. Stores an in-memory token via `ApiService.setAuthToken()` — good for ephemeral session handling.
* `mason_model.dart`: `{ toJson(), fromJson() }` used by create/update flows.
* `kyc_onboarding_screen.dart`: UI collecting docs, calling `ApiService` methods, navigation.

---

## Core design decisions & contracts

* **Single http.Client instance**: your `_client` is created once; good. Reuse avoids socket exhaustion and is testable.
* **Auth storage in memory**: `_authToken` is stored statically. Good for quick usage — but not persistent across app restarts. Use secure storage for persistent tokens.
* **API responses**: your helper expects `{ success: true, data: ... }` format. Some endpoints (like `auth/login`) may return different shapes. `_post` handles `auth/login` as a special-case. Keep backend consistent or add per-endpoint adapters.
* **Multipart upload**: uses `http.MultipartRequest`. Assumes server returns `{ success: true, publicUrl: "..." }` (or `publicUrl` key). Confirm with backend.
* **TSO helper**: `TsoUser.fromJson` builds a `name` by joining `firstName` and `lastName`. Good convenience.

---

## Environment and configuration

Set these before running on an emulator/device:

* `API_BASE_URL` — base for all REST endpoints. Example:

  * Local (emulator): `http://10.0.2.2:8000`
  * Local (iOS simulator): `http://localhost:8000`
  * Prod (example): `https://api.example.com`
* `UPLOAD_BASE_URL` — if upload uses a different domain or proxy.

Example `.env` (use `flutter_dotenv`):

```
API_BASE_URL=http://10.0.2.2:8000
UPLOAD_BASE_URL=http://10.0.2.2:8000
RADAR_API_KEY=xxx
```

Your `ApiService` currently hardcodes `_baseUrl`. You may want to initialize it from `dotenv.env['API_BASE_URL']` or construct `ApiService(baseUrl: ...)` for better flexibility.

---

## ApiService internals — explanation and examples

### 1) `_get`, `_post`, `_patch`, `_delete`

* `_get` builds `$_baseUrl/api/<endpoint>` and expects `success:true` and `data`.
* `_post` handles `auth/login` specially (returns raw data), otherwise same contract.
* `_patch` and `_delete` behave similarly.

**Example usage (already present):**

```dart
final mason = await apiService.fetchMasonById('42');
```

`fetchMasonById` calls:

```dart
return _get('masons/$masonId', (json) => Mason.fromJson(json));
```

### 2) `uploadImageToR2(File)`

Sends a multipart POST to `$_baseUrl/api/r2/upload-direct`. The method expects JSON with `publicUrl` (or `publicUrl` inside `data` / `success` checks). If your backend returns `url` or `data.url`, adapt parsing.

**Important**: you add auth header to `request.headers['Authorization']` and append a trailing `!` to the token string (`'Bearer $_authToken!'`) — that `!` seems accidental and will break auth. Remove the `!`.

Fix snippet:

```dart
if (_authToken != null) {
  request.headers['Authorization'] = 'Bearer $_authToken';
}
```

### 3) `searchTso`, `fetchTechnicalTsos`

`searchTso` uses `/api/users?search=$query&role=tso`. `fetchTechnicalTsos` uses `/api/users?isTechnicalRole=true`. These rely on your server-side filters implemented earlier — consistent.

---

## KYC flow & `KycOnboardingScreen` integration

**Flow variants:**

### A) Current (your code)

* Upload files (if present) → get URLs
* Build `completeMason`
* Fire parallel requests: `createMason` and `submitKyc` simultaneously
* Assume `createMason` returns the created mason object

**When this is safe:** when `submitKyc` either:

* Accepts `mason` data inline (no masonId required), or
* Accepts mason identifier provided by client (client-controlled ID), or
* Backend tolerates this ordering and associates submission later.

**Safer flow (recommended):**

1. Upload images → get URLs
2. Create mason (POST → returns `createdMason.id`)
3. Submit KYC with `masonId: createdMason.id`

**Example safer code (async sequential):**

```dart
final createdMason = await _api.createMason(completeMason);
await _api.submitKyc(
  masonId: createdMason.id!.toString(),
  aadhaarNumber: _aadhaarController.text.trim(),
  documents: documents,
  remark: _remarkController.text.trim(),
);
```

If you truly want parallelism, only parallelize independent operations (e.g., logging + notify admin + local DB write). Not the create/submit dependent pair.

---

## Key endpoints & sample payloads (copy/paste)

### Upload image

```bash
curl -X POST "http://localhost:8000/api/r2/upload-direct" \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/image.jpg"
```

Response expected:

```json
{ "success": true, "publicUrl": "https://cdn.example.com/abc.jpg" }
```

### Create Mason

```bash
curl -X POST "http://localhost:8000/api/masons" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "John Mason",
    "phoneNumber": "+919876543210",
    "kycStatus": "pending",
    "kycDocumentName": "Aadhaar Card",
    "kycDocumentIdNum": "123412341234",
    "userId": 42,
    "documents": { "aadhaarFrontUrl": "https://cdn.example.com/a.jpg" }
  }'
```

Response:

```json
{ "success": true, "data": { "id": 87, "name": "John Mason", ... } }
```

### Submit KYC

```bash
curl -X POST "http://localhost:8000/api/kyc-submissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "masonId": "87",
    "aadhaarNumber": "123412341234",
    "documents": { "aadhaarFrontUrl": "https://cdn.example.com/a.jpg" },
    "remark": "Submitted from mobile"
  }'
```

Response:

```json
{ "success": true, "data": { "id": 250, "status": "pending" } }
```

---

## Auth, state & token handling

* `ApiService.setAuthToken(token)` sets the static in-memory token. Call it after login.
* For persistence across restarts, combine with `flutter_secure_storage`:

  * store token on login
  * on app startup, read token and call `ApiService.setAuthToken`
* Remove the accidental `!` in upload headers.
* Always attach `Authorization` header for endpoints that require it.

---

## Concurrency gotchas & recommended fixes

1. **Parallel create + submit**
   If `submitKyc` requires `masonId`, running both requests in parallel is a race. Switch to sequential or restructure backend to accept a single combined KYC payload.

2. **Multipart requests and timeouts**
   You used `.timeout(const Duration(seconds: 90))` — reasonable. For large files, consider chunked uploads or increasing timeout.

3. **Client resource management**
   Close `_client` on app shutdown or provide a `dispose()` when using dependency injection.

---

## Testing & debugging (curl, jq, emulator NOTES)

* Android emulator → `http://10.0.2.2:8000` points to host machine.
* iOS simulator → `http://localhost:8000` works.
* To pretty-print JSON: `curl -s <url> | jq .`
* To check upload:

  ```bash
  curl -F "file=@aadhaar_front.jpg" "http://localhost:8000/api/r2/upload-direct" \
    -H "Authorization: Bearer <token>"
  ```
* If you see 401 on upload, check header format and trailing `!`.

---

## Error handling & UX suggestions

* Show progress for uploads (multipart supports streamed upload progress with other packages). `image_picker` + `http` alone doesn't show progress.
* Provide per-file retry and a "retry all failed uploads" action.
* Validate file type (`.jpg`, `.png`) and limit size (e.g., < 5MB).
* If `createMason` succeeds but `submitKyc` fails, capture server response and show a "Retry KYC submission" screen that uses stored createdMason.id and documents.

---

## Security & production checklist (don't skip)

* Use HTTPS everywhere.
* Persist tokens in secure storage and refresh tokens where applicable.
* Validate user inputs on backend.
* Limit upload size / validate content types.
* Scan uploaded images if your compliance requires it.
* Use signed URLs or privacy-preserving access to uploaded assets when these are sensitive.
* Rate-limit endpoints and enforce auth on all sensitive endpoints.

---

## Next files you promised — what I'll do for them (deal)

You said: “more consecutive files are coming and I need you to do the same for those tooo DEAL?” Deal. For every file you drop I will:

* produce a **detailed README** that explains:

  * responsibilities of the file,
  * data contracts (request/response),
  * integration points (what other files call it),
  * security concerns,
  * sample curl and dart snippets,
  * common pitfalls and tests,
  * suggested improvements and refactors.
* provide **copy-paste code snippets** and precise bullet lists for changes needed in other modules.
* be mildly annoyed, but deliver.

So send the next file. Don’t dawdle.

---

## Appendix: helper snippets and tiny utilities

### Fix `Authorization` header bug

```dart
// BAD:
request.headers['Authorization'] = 'Bearer $_authToken!';

// FIX:
if (_authToken != null) {
  request.headers['Authorization'] = 'Bearer $_authToken';
}
```

### Persisting token using flutter_secure_storage

```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// On startup:
final token = await storage.read(key: 'auth_token');
if (token != null) ApiService.setAuthToken(token);
```

### Safer create + submit sequence (KYC)

```dart
// 1) create mason and await id
final createdMason = await _api.createMason(completeMason);
// 2) submit KYC using returned id
await _api.submitKyc(
  masonId: createdMason.id!.toString(),
  aadhaarNumber: _aadhaarController.text.trim(),
  documents: documents,
  remark: _remarkController.text.trim(),
);
```

---

## Final words (short)

You built a useful, pragmatic `ApiService` with a lot of endpoints — nice. Fix the `Authorization` upload bug, decide on create-vs-submit ordering (sequential unless guaranteed otherwise), and persist your token securely. Send the next file and I’ll generate another equally obnoxious but perfect README.
