````{"id":"70329","variant":"standard","title":"README for Mason KYC Integration"}
# 🧱 Mason KYC Integration — Flutter + Node + Brixta

This document explains the **full implementation** of the Mason KYC feature — from the Flutter frontend to the Node.js backend route and the supporting `ApiService` updates.

---

## ⚙️ Overview

You implemented a complete **Mason KYC submission flow** for your Flutter app that communicates directly with your backend (`/api/kyc-submissions`) hosted at:

```
https://myserverbymycoco.onrender.com
```

The new system lets Masons (contractors) upload their KYC documents — Aadhaar, PAN, and Voter ID — along with remarks. The backend stores these, updates their verification status, and marks them as *pending approval*.

---

## 🧭 Flow Summary

### 1. Mason logs in
When a Mason logs into the app, they are navigated to:

```dart
KycOnboardingScreen(mason: mason)
```

The `mason` object carries their unique `UUID` (used for KYC linkage).

---

### 2. KYC form
The new `KycOnboardingScreen` lets the user:

- Fill optional KYC fields (Aadhaar, PAN, Voter ID)
- Upload supporting documents
- Write remarks
- Submit everything with a single tap

Form auto-fills with the Mason’s name and phone number.

---

### 3. Upload logic
Each selected image is uploaded via `uploadImageToR2` (in `ApiService`), returning a **public URL**.

These URLs are bundled under a JSON field:
```json
"documents": {
  "aadhaarFrontUrl": "https://cdn...",
  "panUrl": "https://cdn..."
}
```

---

### 4. Backend route
The backend route `/api/kyc-submissions`:

- Validates payload using Zod
- Confirms Mason existence
- Inserts into `kycSubmissions` table
- Updates `masonPcSide.kycStatus` to `'pending'`
- Returns the new KYC record

**Response sample:**
```json
{
  "success": true,
  "message": "KYC Submission submitted successfully and awaiting TSO approval.",
  "data": {
    "id": "uuid",
    "masonId": "uuid",
    "status": "pending"
  }
}
```

---

## 🧩 Flutter Implementation

### 📄 `lib/screens/contractor/kyc_onboarding_screen.dart`

A modernized, functional KYC screen featuring:
- Image uploads via `image_picker`
- Integrated API submission
- Validation
- User feedback (SnackBars)
- Live form state tracking

Key features:
```dart
final ApiService _api = ApiService();

Future<void> _submitKyc() async {
  await _api.submitKyc(
    masonId: widget.mason.id!,
    aadhaarNumber: _aadhaarController.text,
    panNumber: _panController.text,
    voterIdNumber: _voterController.text,
    documents: documents,
    remark: _remarkController.text,
  );
}
```

Packages used:
```yaml
image_picker: ^0.8.7+5
http: ^0.13.6
```

---

## 🧠 ApiService Updates

### 🪄 New Methods Added

**`uploadImageToR2(File)`**
Uploads an image to your R2 (or similar storage) and returns its public URL.

**`submitKyc({...})`**
Posts all KYC data to `/api/kyc-submissions`.

**`createMason(Mason)`**
Creates a new Mason.

**`updateMason(id, data)`**
Patches Mason data.

**`deleteMason(id)`**
Removes a Mason record.

---

### Example KYC Submission (from Flutter)
```dart
final api = ApiService();

await api.submitKyc(
  masonId: mason.id!,
  aadhaarNumber: '123456789012',
  panNumber: 'ABCDE1234F',
  documents: {
    'aadhaarFrontUrl': 'https://cdn.example.com/aadhaar_front.jpg',
    'panUrl': 'https://cdn.example.com/pan.jpg',
  },
  remark: 'Submitted for verification',
);
```

---

## 🧾 Server Route — `server/src/routes/formSubmissionRoutes/kycSubmissions.ts`

Implements:
- Zod validation
- Database transaction
- Mason KYC status update
- Typed response using `InferSelectModel`

Key points:
- Table: `kycSubmissions`
- Relation: `masonPcSide.id`
- Updates `kycStatus` to `'pending'`

---

## ✅ API Request Example

```http
POST /api/kyc-submissions
Content-Type: application/json

{
  "masonId": "8cfe0b94-2374-4a1c-9d85-9a91e6a15d27",
  "aadhaarNumber": "123412341234",
  "panNumber": "ABCDE1234F",
  "voterIdNumber": null,
  "documents": {
    "aadhaarFrontUrl": "https://cdn.example.com/aadhaar_front.jpg",
    "panUrl": "https://cdn.example.com/pan.jpg"
  },
  "remark": "Please verify"
}
```

---

## 🧠 Database Impact

**Table affected:**  
`kycSubmissions` → new record inserted  
`masonPcSide` → field `kycStatus` updated to `"pending"`

**Default values:**
- `status`: `'pending'`
- `documents`: JSON (nullable)
- `remark`: string (nullable)

---

## 🧰 File Summary

| File | Description |
|------|--------------|
| `lib/screens/contractor/kyc_onboarding_screen.dart` | Complete frontend UI and submission logic |
| `lib/services/api_service.dart` | Uploads, KYC API, and Mason CRUD |
| `server/src/routes/formSubmissionRoutes/kycSubmissions.ts` | Backend API route |
| `lib/models/mason_model.dart` | Holds Mason fields and fromJson/toJson |
| `.env` | Stores RADAR_API_KEY for reverse geocoding |

---

## 🧩 Final Result

✅ **Mason → Uploads KYC docs**  
✅ **Uploads stored on R2**  
✅ **API → `/api/kyc-submissions`**  
✅ **Backend → validates, inserts, updates `kycStatus`**  
✅ **Response → success + pending state**

---

## 🚀 Next Steps

- Add a **TSO Dashboard** to review and approve KYC submissions.
- Auto-refresh Mason list when KYC updates are detected.
- Introduce OCR verification (your `performOcr` mock already exists).
- Add local caching or retry for offline uploads.

---

## 📚 Version Compatibility

| Component | Version |
|------------|----------|
| Flutter | 3.x |
| Dart | >=3.0 |
| Node.js | >=18 |
| Drizzle ORM | 0.29+ |
| PostgreSQL | 15+ |

---

## 🏁 TL;DR

**You built an end-to-end KYC feature**:
- Mason uploads → Cloud → Server → DB  
- All handled cleanly through `ApiService`  
- Ready for production, extensible for admin workflows

> 🧩 *"From local phone to verified mason — one clean API call at a time."*
````
