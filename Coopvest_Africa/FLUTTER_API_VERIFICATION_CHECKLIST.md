# Flutter App - Guarantor Service API Verification Checklist

**Purpose:** Identify exact endpoint mismatches between Flutter app and Laravel backend

**Status:** 🔍 REVIEW REQUIRED - Critical for Phase 1

---

## API ENDPOINT COMPARISON TABLE

### GUARANTOR MANAGEMENT

| # | Method | Current Endpoint (Flutter) | Backend Endpoint (Web App) | Status | Match? |
|---|--------|--------------------------|---------------------------|--------|--------|
| 1 | `getGuarantorsForLoan()` | `/api/loans/{loanId}/guarantors` | `/api/loans/{loanId}/guarantors` | ✅ | YES |
| 2 | `getGuarantorById()` | `/api/guarantors/{guarantorId}` | `/api/guarantors/{id}` | ✅ | YES |
| 3 | `inviteGuarantor()` | `/api/loans/{loanId}/guarantors` | `/api/loans/{loanId}/guarantors` | ⚠️ | VERIFY |
| 4 | `removeGuarantor()` | `/api/loans/{loanId}/guarantors/{guarantorId}` | `/api/loans/{loanId}/guarantors/{id}` | ✅ | YES |

---

### GUARANTOR INVITATIONS

| # | Method | Current Endpoint (Flutter) | Backend Endpoint (Web App) | Status | Match? |
|---|--------|--------------------------|---------------------------|--------|--------|
| 5 | `getPendingInvitations()` | `/api/guarantor/pending-invitations` | `/api/guarantor/pending-requests` | ❌ | **NO** |
| 6 | `getInvitationByToken()` | `/api/guarantor-invitations/{token}` | `?` (verify) | ⚠️ | UNKNOWN |
| 7 | `acceptInvitation()` | `/api/guarantor-invitations/{token}/accept` | `/api/guarantor-invitations/{token}/accept` | ✅ | YES |
| 8 | `declineInvitation()` | `/api/guarantor-invitations/{token}/decline` | `/api/guarantor-invitations/{token}/decline` | ✅ | YES |

---

### GUARANTOR VERIFICATION

| # | Method | Current Endpoint (Flutter) | Backend Endpoint (Web App) | Status | Match? |
|---|--------|--------------------------|---------------------------|--------|--------|
| 9 | `getVerificationStatus()` | `/api/guarantors/{guarantorId}/verification` | `?` (verify) | ⚠️ | UNKNOWN |
| 10 | `submitVerificationDocuments()` | `/api/guarantors/{guarantorId}/verification` | `/api/guarantors/{id}/documents` | ⚠️ | **MAYBE NO** |
| 11 | `uploadEmploymentVerification()` | `/api/guarantors/{guarantorId}/employment-verification` | `?` (verify) | ⚠️ | UNKNOWN |

---

### GUARANTOR QR CODE

| # | Method | Current Endpoint (Flutter) | Backend Endpoint (Web App) | Status | Match? |
|---|--------|--------------------------|---------------------------|--------|--------|
| 12 | `getQrCode()` | `?` (check service) | `/api/guarantors/{id}/qr-code` | ⚠️ | UNKNOWN |

---

### USER-SPECIFIC ENDPOINTS

| # | Method | Current Endpoint (Flutter) | Backend Endpoint (Web App) | Status | Match? |
|---|--------|--------------------------|---------------------------|--------|--------|
| 13 | `getMyGuarantees()` | `?` (legacy) | `/api/guarantor/my-obligations` | ❌ | **NO** |
| 14 | `revokeGuarantee()` | `?` (legacy) | `?` (verify) | ⚠️ | UNKNOWN |

---

## ISSUES IDENTIFIED

### 🔴 CRITICAL MISMATCHES (Must Fix)

#### Issue #1: `getPendingInvitations()`
```
CURRENT:  /api/guarantor/pending-invitations
SHOULD BE: /api/guarantor/pending-requests
FILE: lib/services/guarantor_service.dart, line ~131
```

**Fix Required:** Update endpoint URL
```dart
// ❌ WRONG
final response = await http.get(
  Uri.parse('$baseUrl/api/guarantor/pending-invitations'),
  headers: headers,
);

// ✅ CORRECT
final response = await http.get(
  Uri.parse('$baseUrl/api/guarantor/pending-requests'),
  headers: headers,
);
```

---

#### Issue #2: `submitVerificationDocuments()`
```
CURRENT:  /api/guarantors/{guarantorId}/verification
SHOULD BE: /api/guarantors/{id}/documents
FILE: lib/services/guarantor_service.dart, line ~240
```

**Issue:** Using `/verification` endpoint but should use `/documents` endpoint

**Fix Required:** Check if backend supports both or migrate to `/documents`

```dart
// Current (might be wrong)
Uri.parse('$baseUrl/api/guarantors/$guarantorId/verification')

// Should be (verify with backend)
Uri.parse('$baseUrl/api/guarantors/$guarantorId/documents')
```

---

#### Issue #3: `getMyGuarantees()` (Legacy)
```
CURRENT:  ? (legacy endpoint)
SHOULD BE: /api/guarantor/my-obligations
FILE: lib/services/guarantor_service.dart
```

**Issue:** Using legacy endpoint that may not exist

**Fix Required:** Update to match backend endpoint

---

### 🟡 VERIFICATION NEEDED

These endpoints are used but we need to confirm they exist on the backend:

1. **`getInvitationByToken()`**
   - Current endpoint: `/api/guarantor-invitations/{token}`
   - Status: Need to verify this public endpoint exists

2. **`getVerificationStatus()`**
   - Current endpoint: `/api/guarantors/{guarantorId}/verification`
   - Status: Need to verify this endpoint exists

3. **`uploadEmploymentVerification()`**
   - Current endpoint: `/api/guarantors/{guarantorId}/employment-verification`
   - Status: Need to verify this endpoint exists

4. **`getQrCode()`**
   - Need to find method in service
   - Endpoint should be: `/api/guarantors/{id}/qr-code`

5. **`revokeGuarantee()`**
   - Legacy method, need to verify endpoint

---

## VERIFICATION STEPS

### Step 1: Check Backend API Documentation
```bash
# In web app folder:
cat server/app/Http/Controllers/GuarantorController.php | grep -E "public function|Route::"
```

### Step 2: Test Each Endpoint with Postman/Insomnia

**Template for testing:**
```
Method: GET/POST
URL: https://api.coopvest.africa/api/guarantor/pending-requests
Headers:
  Authorization: Bearer {token}
  Content-Type: application/json
Response Code: Should be 200
Response Body: Should contain { "data": [...] }
```

### Step 3: Update Flutter Service

**When endpoint is confirmed, update like this:**
```dart
// Before
const String endpoint = '/api/old-endpoint';

// After
const String endpoint = '/api/new-endpoint';
```

### Step 4: Test in Flutter

**After updating, test in Flutter:**
```dart
// Add test in main.dart or test file
import 'services/guarantor_service.dart';

final service = GuarantorService();
try {
  final result = await service.getPendingInvitations();
  print('✅ Success: $result');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## CORRECTED ENDPOINTS LIST

**After verification, update these in `GuarantorService`:**

```dart
// GUARANTOR MANAGEMENT
GET    /api/loans/{loanId}/guarantors              ✅ getGuarantorsForLoan()
GET    /api/guarantors/{id}                        ✅ getGuarantorById()
POST   /api/loans/{loanId}/guarantors/invite       ✅ inviteGuarantor()
DELETE /api/loans/{loanId}/guarantors/{id}         ✅ removeGuarantor()

// GUARANTOR INVITATIONS
GET    /api/guarantor/pending-requests             ❌ FIX: was /pending-invitations
GET    /api/guarantor-invitations/{token}          ⚠️ VERIFY
POST   /api/guarantor-invitations/{token}/accept   ✅ acceptInvitation()
POST   /api/guarantor-invitations/{token}/decline  ✅ declineInvitation()

// GUARANTOR VERIFICATION
GET    /api/guarantors/{id}/documents              ✅ getVerificationDocuments() [NEW METHOD NEEDED]
POST   /api/guarantors/{id}/documents              ✅ uploadDocument() [UPDATE submitVerificationDocuments()]
GET    /api/guarantors/{id}/qr-code               ✅ getQRCode()

// USER SPECIFIC
GET    /api/guarantor/pending-requests             ✅ getPendingInvitations() [AFTER FIX]
GET    /api/guarantor/my-obligations               ✅ getMyObligations() [UPDATE getMyGuarantees()]

// ADMIN
POST   /api/guarantors/{id}/verify                 ✅ verifyGuarantor() [IF EXISTS]
```

---

## SERVICE METHODS TO AUDIT

**File:** `lib/services/guarantor_service.dart`

```dart
Line 29-51    → getGuarantorsForLoan()           ✅ CHECK
Line 53-69    → getGuarantorById()               ✅ CHECK
Line 72-104   → inviteGuarantor()                ⚠️  CHECK PARAMETERS
Line 108-121  → removeGuarantor()                ✅ CHECK
Line 127-145  → getPendingInvitations()          ❌ FIX ENDPOINT
Line 147-162  → getInvitationByToken()           ⚠️  VERIFY
Line 165-185  → acceptInvitation()               ✅ CHECK
Line 188-203  → declineInvitation()              ✅ CHECK
Line 207-226  → getVerificationStatus()          ⚠️  VERIFY
Line 229-265  → submitVerificationDocuments()    ⚠️  VERIFY/FIX
Line 268-292  → uploadEmploymentVerification()   ⚠️  VERIFY
Line 295+     → Legacy methods                   ❌ REVIEW
```

---

## QUICK ACTION ITEMS

### Tomorrow (1-2 hours)

- [ ] Open `lib/services/guarantor_service.dart`
- [ ] Change line ~131 endpoint from `/pending-invitations` to `/pending-requests`
- [ ] Search for all legacy methods and review each
- [ ] Test `getPendingInvitations()` after fix

### This Week (3-4 hours)

- [ ] Create test script for all 14 methods
- [ ] Test each endpoint against backend using Postman
- [ ] Create mapping document of working endpoints
- [ ] Fix any remaining mismatches
- [ ] Test in Flutter emulator/device

### Next Week (1-2 hours)

- [ ] Deploy updated Flutter app to staging
- [ ] Run full end-to-end tests
- [ ] Update documentation with confirmed endpoints
- [ ] Proceed to Phase 2: QR Code Acceptance

---

## TESTING SCRIPT TEMPLATE

**Create file:** `test_guarantor_endpoints.dart`

```dart
import 'services/guarantor_service.dart';

void main() async {
  final service = GuarantorService();
  
  print('Testing Guarantor Service Endpoints...\n');
  
  // Test 1
  try {
    print('1. Testing getGuarantorsForLoan()...');
    final guarantors = await service.getGuarantorsForLoan('loan-id-here');
    print('   ✅ Success: Found ${guarantors.length} guarantors\n');
  } catch (e) {
    print('   ❌ Failed: $e\n');
  }
  
  // Test 2
  try {
    print('2. Testing getPendingInvitations()...');
    final invitations = await service.getPendingInvitations();
    print('   ✅ Success: Found ${invitations.length} invitations\n');
  } catch (e) {
    print('   ❌ Failed: $e\n');
  }
  
  // Add more tests for each method...
}
```

---

## REFERENCE: BACKEND ROUTES

**From Laravel backend (web app):**

```
GET    /api/loans/{loanId}/guarantors                    GuarantorController@index
GET    /api/guarantors/{id}                              GuarantorController@show
POST   /api/loans/{loanId}/guarantors/invite             GuarantorController@invite
DELETE /api/loans/{loanId}/guarantors/{id}               GuarantorController@destroy
GET    /api/guarantor/pending-requests                   GuarantorController@myPendingRequests
GET    /api/guarantor/my-obligations                     GuarantorController@myObligations
POST   /api/guarantor-invitations/{token}/accept         GuarantorController@acceptByToken
POST   /api/guarantor-invitations/{token}/decline        GuarantorController@declineByToken
GET    /api/guarantors/{id}/documents                    GuarantorController@getDocuments
POST   /api/guarantors/{id}/documents                    GuarantorController@uploadDocument
GET    /api/guarantors/{id}/qr-code                      GuarantorController@getQRCode
POST   /api/guarantors/{id}/verify                       GuarantorController@verify (ADMIN)
```

---

## SUBMIT THIS FOR APPROVAL

**Before proceeding with Flutter implementation:**

1. ✅ Confirm endpoint list above with backend team
2. ✅ Mark each as VERIFIED / INCORRECT
3. ✅ Provide any corrections
4. ✅ Proceed with Flutter fixes

**Contact Backend Team With:**
- This checklist
- Screenshot of endpoint comparisons
- Request for confirmation on marked UNKNOWN endpoints

---

**Prepared by:** Development Team
**Status:** Ready for Backend Review
**Action Required:** Backend Endpoint Verification
**Timeline:** ASAP (Critical for Phase 1)
