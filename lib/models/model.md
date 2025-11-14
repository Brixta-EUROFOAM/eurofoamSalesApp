# Employee & Mason Models — Deep README

You gave me two model files — `employee_model.dart` and `mason_model.dart` — and asked for a full, no-nonsense explanation of how they work, how the API uses them, how to fetch/post data, and how admin maps to `Employee` with `isTechnicalRole = true`. Here’s a detailed, practical guide that explains everything to the core, with copy-paste examples and clear warnings where things will bite you.

---

## Table of contents

1. Quick summary
2. `Employee` model — what it does and why it’s clever
3. `Mason` model — what it does and the parsing resilience built in
4. How the models are created / converted / used (convenience methods)
5. How `ApiService` should fetch / post these models (example code + payloads)
6. Admin = `Employee` with `isTechnicalRole = true` — mapping & usage
7. End-to-end examples (curl + Dart snippets)
8. Gotchas, bugs to avoid, and recommended hardening
9. Next steps & checklist

---

## 1) Quick summary — short & useful

* `Employee` is the app’s admin/employee user model. It parses both nested and flat JSON, builds a `displayName`, and carries `role`.
* `Mason` is your contractor model. It’s resilient: accepts snake_case and camelCase, parses ints/bools/dates robustly, and has `Mason.fromEmployee()` to adapt an `Employee` into a mason when needed.
* `ApiService` must produce/consume camelCase payloads (your models’ `toJson()` use camelCase). Backend may return snake_case — models handle that on input.
* Admins are just `Employee` rows where `isTechnicalRole == true`. Use the `isTechnicalRole` filter server-side and treat the local `Employee.role` as additional metadata.

---

## 2) Employee model — anatomy & behavior

### Key fields

```dart
final String id;
final String? firstName;
final String? lastName;
final String? email;
final String? loginId;
final String? companyName;
final String? role;
```

### Important methods

* `displayName`: smart fallback builder — `firstName lastName` if present, otherwise first available of `firstName`, `lastName`, `loginId`, or `'Employee'`.
* `Employee.fromJson(Map<String, dynamic>)`: resilient parsing that handles:

  * `company` nested object (`company['companyName']`) OR flat `companyName`.
  * `id` might be numeric or string — coerced to string.
  * `role` is accepted from JSON.
* `toJson()`: returns a flat map with camelCase keys for POST/PATCH.

### Why this is good

* Works with inconsistent server responses. Backend can be poorly designed; your model won’t crash because of that.
* `role` addition makes it easier to render UI decisions (e.g., hide admin actions for non-admins).

---

## 3) Mason model — resilience & fields

### Core fields

```dart
final String? id;
final String name;
final String phoneNumber;
final String? kycDocumentName;
final String? kycDocumentIdNum;
final String kycStatus; // 'none'|'pending'|'approved'|'rejected'
final int pointsBalance;
final int? userId;
final DateTime? createdAt;
final DateTime? updatedAt;
...plus optional dealer/user joined fields...
```

### Smart parsing features

* Accepts snake_case and camelCase: `kycStatus` or `kyc_status`, `phoneNumber` or `phone_number` or `phone`.
* Parses numbers robustly: `_parseInt()` accepts int or stringified numbers.
* Parses boolean strings `('true','1','false','0')` with `_parseBool()`.
* Parses timestamps with `_parseDate()` and gracefully ignores invalid dates.
* `toJson()` uses camelCase to match your `ApiService` expectations.

### `Mason.fromEmployee(Employee e)`

* Convenience adapter: constructs a Mason from an Employee (useful for flows where admin creates mason from an employee row).
* Sets sensible defaults. Does not guess dealerId or userId — you must map those explicitly if needed.

---

## 4) How models are created / converted / used

### Create mason from JSON returned by API:

```dart
final Map<String, dynamic> json = ...; // server response
final mason = Mason.fromJson(json);
```

### Convert mason to payload for create/update:

```dart
final payload = mason.toJson(); // camelCase keys
// Use ApiService.createMason(Mason.fromJson(...)) or .createMason(Mason)
```

### Employee from login/profile:

* If login returns a flat object, `Employee.fromJson` still works.
* If profile returns `company` nested object, it extracts `company.companyName`.

### Copy/update pattern:

```dart
final updated = mason.copyWith(kycStatus: 'pending');
await api.updateMason(mason.id!, updated.toJson());
```

---

## 5) How `ApiService` should fetch / post these models

Your `ApiService` already contains many endpoints. Here's the exact contract and sample code integration you should use.

### Fetch mason by id (ApiService helper)

```dart
Future<Mason> fetchMasonById(String masonId) {
  return _get('masons/$masonId', (json) => Mason.fromJson(json));
}
```

**Backend response shape expected**:

```json
{ "success": true, "data": { "id": 87, "name": "John Doe", "phoneNumber": "+91..." } }
```

`_get` unwraps `data` and passes it to `Mason.fromJson`.

### Create mason (POST)

```dart
Future<Mason> createMason(Mason mason) {
  final body = mason.toJson()..removeWhere((k, v) => v == null);
  return _post('masons', body, (json) => Mason.fromJson(json));
}
```

**Request payload example (camelCase)**:

```json
{
  "name": "John Doe",
  "phoneNumber": "+919876543210",
  "kycStatus": "pending",
  "userId": 42,
  "documents": { "aadhaarFrontUrl": "https://..." }
}
```

**Response**:

```json
{ "success": true, "data": { "id": 87, "name": "John Doe", ... } }
```

### Update mason (PATCH)

```dart
Future<Mason> updateMason(String masonId, Map<String, dynamic> data) {
  return _patch('masons/$masonId', data, (json) => Mason.fromJson(json));
}
```

### Submit KYC (separate endpoint)

`submitKyc` in `ApiService` accepts `masonId` and document fields:

```dart
await _api.submitKyc(
  masonId: createdMason.id!,
  aadhaarNumber: '123412341234',
  documents: { 'aadhaarFrontUrl': 'https://...' }
);
```

**Important**: If `submitKyc` requires a `masonId`, ensure `createMason` runs first and returns id. Do not parallelize create + submit unless backend accepts that.

---

## 6) Admin = `Employee` with `isTechnicalRole = true`

Short: Your server has a `users` table where `isTechnicalRole` flags technical/admin users (TSO/tech). The `Employee` model is the local representation. On login, backend should return that user's `isTechnicalRole` or `role`. Map it like this:

* Server filter (example): `/api/users?isTechnicalRole=true` returns admin employees.
* Client: after login, fetch employee profile (or login returns employee data). If `employee.role` exists use it for UI; additionally use the server-side boolean for true authority checks.
* UI usage example:

```dart
if (employee.role == 'admin' || employeeIsTechnical) {
  // show admin dashboard
}
```

Where `employeeIsTechnical` is either `employee.role == 'tso'` or a separate boolean field obtained from the server. Your `Employee` model currently lacks `isTechnicalRole` boolean member — consider adding it for convenience if backend returns it.

---

## 7) End-to-end examples (curl + Dart)

### 1) Upload image (example)

```bash
curl -X POST "http://localhost:8000/api/r2/upload-direct" \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@/path/to/aadhaar_front.jpg"
# Expect: { "success": true, "publicUrl": "https://cdn..." }
```

### 2) Create mason (curl)

```bash
curl -X POST "http://localhost:8000/api/masons" \
 -H "Authorization: Bearer <TOKEN>" \
 -H "Content-Type: application/json" \
 -d '{
   "name":"John Mason",
   "phoneNumber":"+919876543210",
   "kycStatus":"pending",
   "documents":{"aadhaarFrontUrl":"https://..."}
 }'
```

### 3) Sequential Dart (safe KYC flow)

```dart
// 1. Upload files and build documents map
final aadhaarUrl = await api.uploadImageToR2(aadhaarFile);

// 2. Create mason (await id)
final created = await api.createMason(mason.copyWith(kycStatus: 'pending'));

// 3. Submit KYC using the returned id
await api.submitKyc(
  masonId: created.id!,
  aadhaarNumber: aadhaarController.text,
  documents: {'aadhaarFrontUrl': aadhaarUrl},
);
```

---

## 8) Gotchas, pitfalls, and fixes (read this twice)

1. **Parallel create + submit**
   If `submitKyc` requires `masonId`, running both at once is a race. Run sequentially.

2. **`Employee` token & admin flag mismatch**
   You store `role` in `Employee`. But the authoritative admin flag is `isTechnicalRole` from server. Add `bool? isTechnicalRole` to `Employee` if backend returns it.

3. **Auth header bug in ApiService**
   Do not append stray `!` to bearer token. Use `'Authorization': 'Bearer $_authToken'`.

4. **Date parsing and server formats**
   `Mason._parseDate()` uses `DateTime.parse()` which expects ISO8601. If backend returns epoch ints, add fallback parsing.

5. **Id types**
   Your models convert IDs to strings. Backend may expect integer IDs for some endpoints. Convert when building payloads (`int.parse` only when safe) or send strings if API accepts them.

6. **Null fields removal**
   Always remove nulls from payload before POST/PATCH (`..removeWhere((k,v)=>v==null)`) — you already do this in places. Keep doing it.

7. **Inconsistent server key casing**
   Models handle snake_case/camelCase on input. Ensure you always send camelCase outbound to be consistent.

---

## 9) Next steps & checklist (practical)

* [ ] Add `bool? isTechnicalRole` to `Employee` if backend returns it. Use it for access control.
* [ ] Ensure `ApiService.createMason()` returns the created object with `id`.
* [ ] Make KYC flow sequential: createMason → submitKyc.
* [ ] Remove accidental characters in headers.
* [ ] Add unit tests for `Mason.fromJson` and `Employee.fromJson` with both snake_case and camelCase samples.
* [ ] Add explicit error mapping for `ApiService` so UI can show friendly messages.
* [ ] Optionally add `Mason.toCreatePayload()` if you need a different shape for create vs update.

---

### Appendix — sample test JSON for models

**Mason server (snake_case) sample:**

```json
{
  "id": 87,
  "name": "Ravi",
  "phone_number": "+919876543210",
  "kyc_status": "pending",
  "points_balance": 120,
  "user_id": 42,
  "created_at": "2025-11-14T07:01:00.000Z"
}
```

**Employee server sample (nested company):**

```json
{
  "id": 12,
  "firstName": "Anjali",
  "lastName": "K",
  "email": "anjali@example.com",
  "salesmanLoginId": "EMP-XYZ",
  "company": { "companyName": "Brixta" },
  "role": "admin",
  "isTechnicalRole": true
}
```

Both of these should be parsed correctly by your current constructors (except `isTechnicalRole` currently not stored — add it to `Employee` if present).

---

## Final words (short & mildly smug)

Your models are solid and defensive — they won’t explode when the backend lies to them. Fix the few auth and ordering issues I flagged, add `isTechnicalRole` to `Employee` for clarity, and make the create→submit KYC flow sequential unless you really love race conditions. Send the next file and I’ll do another glorious README with examples and tiny surgical fixes.
