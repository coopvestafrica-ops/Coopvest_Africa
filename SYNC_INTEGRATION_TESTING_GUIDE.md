# Flutter & Web Sync Integration Testing Guide

**Purpose:** Verify cross-platform synchronization before production deployment  
**Confidence Level Required:** 100% (all tests passing)  
**Estimated Time:** 2-3 hours  

---

## 🧪 TEST SUITE OVERVIEW

### Total Test Cases: 45+
- **Unit Tests:** 20+
- **Integration Tests:** 15+
- **End-to-End Tests:** 10+

---

## ✅ PHASE 1: AUTHENTICATION SYNC (5 tests)

### Test 1.1: Login Endpoint Parity
**Objective:** Verify both apps handle login identically

**Steps:**
1. Flutter: Call `POST /auth/login` with test credentials
2. Web: Call `POST /auth/login` with same credentials
3. Compare response format
4. Verify token format matches

**Expected Result:**
```json
{
  "success": true,
  "data": {
    "token": "Bearer ...",
    "user": { /* UserModel */ }
  }
}
```

**Pass Criteria:** ✅ Both apps receive identical response structure

---

### Test 1.2: Token Refresh Sync
**Objective:** Verify token refresh works the same way

**Steps:**
1. Get initial token from Flutter
2. Call refresh endpoint from Web
3. Verify new token is valid for Flutter requests
4. Call refresh endpoint from Flutter
5. Verify new token is valid for Web requests

**Pass Criteria:** ✅ Token refresh response identical, cross-app usage works

---

### Test 1.3: Session State Consistency
**Objective:** Verify session state is shared

**Steps:**
1. Login on Flutter app
2. Make request from Web app using same token
3. Both apps should have access to user data
4. Logout on Flutter
5. Web should no longer have access (verify 401 error)

**Pass Criteria:** ✅ Session state is truly shared

---

### Test 1.4: Error Response Consistency
**Objective:** Verify invalid credentials handled identically

**Steps:**
1. Send invalid credentials to Flutter endpoint
2. Send invalid credentials to Web endpoint
3. Compare error response format

**Expected Error Response:**
```json
{
  "success": false,
  "message": "Invalid credentials",
  "errors": { }
}
```

**Pass Criteria:** ✅ Error format identical

---

### Test 1.5: Password Reset Workflow
**Objective:** Verify password reset works cross-platform

**Steps:**
1. Request password reset from Flutter
2. Verify email link works in Web
3. Initiate password reset from Web
4. Verify credentials work on Flutter

**Pass Criteria:** ✅ Password reset flow consistent

---

## ✅ PHASE 2: DATA MODEL SYNC (8 tests)

### Test 2.1: User Model Serialization
**Objective:** Verify UserModel maps correctly

**Dart → PHP → TypeScript:**
1. Flutter loads UserModel from API response
2. Web loads UserModel from same API response
3. Compare field counts: should match
4. Compare field names after camelCase conversion
5. Verify no fields lost

**Pass Criteria:** ✅ All fields present, names consistent

---

### Test 2.2: Loan Model Consistency
**Objective:** Verify Loan model fields aligned

**Test Data:**
```json
{
  "id": "loan_001",
  "userId": "user_001",
  "amount": 10000.00,
  "status": "active",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

**Steps:**
1. Create loan in backend
2. Fetch from Flutter app
3. Fetch from Web app
4. Verify all fields match

**Pass Criteria:** ✅ Same fields, same values

---

### Test 2.3: LoanApplication Status Enums
**Objective:** Verify status enum values match

**Status Values to Test:**
- draft
- submitted
- under_review
- approved
- rejected

**Steps:**
1. Create application with each status
2. Fetch from Flutter
3. Fetch from Web
4. Verify enum values don't transform unexpectedly

**Pass Criteria:** ✅ Enums consistent, no unexpected transformations

---

### Test 2.4: Guarantor Model Mapping
**Objective:** Verify complex nested objects map correctly

**Guarantor Structure:**
```typescript
{
  id: string;
  userId: string;
  relationship: "friend" | "family" | "colleague";
  verificationStatus: "pending" | "verified" | "rejected";
  employmentVerificationRequired: boolean;
}
```

**Steps:**
1. Create guarantor with all fields
2. Fetch from Flutter → parse Dart model
3. Fetch from Web → parse TypeScript interface
4. Compare all nested fields

**Pass Criteria:** ✅ Nested objects map correctly

---

### Test 2.5: Transaction Model
**Objective:** Verify transaction list formatting

**Steps:**
1. Fetch transactions from Flutter
2. Fetch same transactions from Web
3. Verify list ordering matches
4. Verify pagination format matches

**Pass Criteria:** ✅ List structure, ordering, pagination identical

---

### Test 2.6: KYCVerification Model
**Objective:** Verify KYC data model sync

**Fields to Verify:**
- fullName (String)
- dateOfBirth (Date)
- nationalId (String)
- verificationStatus (Enum)
- documents (Array)

**Steps:**
1. Submit KYC from Flutter
2. Read KYC from Web
3. Verify all fields present
4. Check date format consistency

**Pass Criteria:** ✅ All fields, correct formatting

---

### Test 2.7: Currency Handling
**Objective:** Verify currency/decimal handling matches

**Test Amounts:**
- 10000.00
- 10000.50
- 0.99
- 999999.99

**Steps:**
1. Create loans with different amounts
2. Fetch from Flutter
3. Fetch from Web
4. Verify no rounding errors

**Pass Criteria:** ✅ No precision loss, decimals match exactly

---

### Test 2.8: Null/Optional Field Handling
**Objective:** Verify optional fields handled consistently

**Scenarios:**
- User without middleName (null vs undefined)
- Loan without rejectionReason
- Document without notes

**Steps:**
1. Create objects with optional fields omitted
2. Fetch from Flutter
3. Fetch from Web
4. Verify null handling matches

**Pass Criteria:** ✅ Consistent null representation

---

## ✅ PHASE 3: ENDPOINT VERIFICATION (12 tests)

### Test 3.1: Loan List Endpoint
**Endpoint:** `GET /loans`

**Test Steps:**
1. Create 3 loans via backend
2. Fetch with Flutter: `loanService.getLoans()`
3. Fetch with Web: `apiService.getLoans()`
4. Compare results

**Expected Response:**
```json
{
  "success": true,
  "data": [ /* Loan[] */ ],
  "message": "Loans retrieved successfully"
}
```

**Pass Criteria:** ✅ Same count, same ordering, same data

---

### Test 3.2: Loan Application Creation
**Endpoint:** `POST /loan-applications`

**Test Payload:**
```json
{
  "loan_type_id": 1,
  "requested_amount": 50000,
  "requested_tenure": 12,
  "loan_purpose": "Business expansion",
  "employment_status": "employed"
}
```

**Test Steps:**
1. Create application from Flutter
2. Create application from Web with same data
3. Compare response format
4. Verify IDs are different but data matches

**Pass Criteria:** ✅ Both create successfully, responses identical format

---

### Test 3.3: Loan Application Retrieval
**Endpoint:** `GET /loan-applications/{id}`

**Test Steps:**
1. Create application from Flutter
2. Retrieve same application from Web
3. Retrieve same application from Flutter
4. Compare all fields

**Pass Criteria:** ✅ Same data from both platforms

---

### Test 3.4: Guarantor Invitation Creation
**Endpoint:** `POST /loans/{loanId}/guarantors`

**Test Payload:**
```json
{
  "guarantor_email": "guarantor@example.com",
  "guarantor_phone": "+234 800 123 4567",
  "guarantor_name": "John Doe",
  "relationship": "friend",
  "employment_verification_required": true
}
```

**Test Steps:**
1. Create guarantor invitation from Flutter
2. Create invitation from Web with same data
3. Compare responses

**Pass Criteria:** ✅ Same response format, both succeed

---

### Test 3.5: Guarantor Invitation Acceptance
**Endpoint:** `POST /guarantor-invitations/{token}/accept`

**Test Steps:**
1. Create invitation from Flutter
2. Get token
3. Accept from Web using token
4. Verify Flutter can see guarantor status changed
5. Reverse: Create from Web, accept from Flutter

**Pass Criteria:** ✅ Workflow works bidirectionally

---

### Test 3.6: Document Upload
**Endpoint:** `POST /guarantors/{id}/documents`

**Test Steps:**
1. Upload document from Flutter (multipart/form-data)
2. Upload document from Web
3. Retrieve documents list
4. Verify both uploads visible in both apps

**Pass Criteria:** ✅ Document upload/retrieval consistent

---

### Test 3.7: KYC Submission
**Endpoint:** `PUT /kyc/submit`

**Test Data:**
```json
{
  "full_name": "Test User",
  "date_of_birth": "1990-01-15",
  "national_id": "123456789",
  "bvn": "123456789012"
}
```

**Test Steps:**
1. Submit KYC from Flutter
2. Submit KYC from Web for different users
3. Verify each submission in both apps

**Pass Criteria:** ✅ KYC data visible to both platforms

---

### Test 3.8: Payment Recording
**Endpoint:** `POST /loans/{id}/payment`

**Test Payload:**
```json
{
  "amount": 1000.00,
  "payment_method": "bank_transfer"
}
```

**Test Steps:**
1. Record payment from Flutter
2. Verify payment visible in Web
3. Record payment from Web
4. Verify payment visible in Flutter

**Pass Criteria:** ✅ Payment recorded consistently

---

### Test 3.9: Profile Update
**Endpoint:** `PUT /member/profile`

**Test Data:**
```json
{
  "first_name": "Updated",
  "phone_number": "+234 800 000 0000"
}
```

**Test Steps:**
1. Update profile from Flutter
2. Immediately fetch from Web
3. Verify changes visible
4. Reverse: update from Web, fetch from Flutter

**Pass Criteria:** ✅ Profile changes sync immediately

---

### Test 3.10: Dashboard Data
**Endpoint:** `GET /member/dashboard`

**Test Steps:**
1. Fetch dashboard from Flutter
2. Fetch dashboard from Web
3. Compare all metrics:
   - Active loans count
   - Savings balance
   - Recent transactions
   - Pending applications

**Pass Criteria:** ✅ Same data, same calculations

---

### Test 3.11: Loan Type Retrieval
**Endpoint:** `GET /loan-types`

**Test Steps:**
1. Fetch loan types from Flutter
2. Fetch loan types from Web
3. Verify same count
4. Verify same fields in each type
5. Calculate loan details from Flutter and Web

**Pass Criteria:** ✅ Identical loan types and calculations

---

### Test 3.12: Admin Application Review
**Endpoint:** `GET /admin/applications` (admin only)

**Test Steps:**
1. Submit application from Flutter user account
2. Login as admin in Web
3. Fetch pending applications
4. Login as admin in Flutter
5. Fetch pending applications

**Pass Criteria:** ✅ Same applications visible to both admin platforms

---

## ✅ PHASE 4: ERROR HANDLING SYNC (5 tests)

### Test 4.1: Validation Error Consistency
**Scenario:** Create loan with invalid amount

**Invalid Payload:**
```json
{
  "requested_amount": "not_a_number"
}
```

**Expected Error:**
```json
{
  "success": false,
  "errors": {
    "requested_amount": ["The requested amount must be a number"]
  }
}
```

**Test Steps:**
1. Send invalid payload from Flutter
2. Send invalid payload from Web
3. Compare error response format

**Pass Criteria:** ✅ Same error message, same format

---

### Test 4.2: Authentication Error
**Scenario:** Make request without valid token

**Test Steps:**
1. Call authenticated endpoint from Flutter without token
2. Call authenticated endpoint from Web without token
3. Compare error responses

**Expected Error:**
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

**Pass Criteria:** ✅ Both get 401 error with same format

---

### Test 4.3: Not Found Error
**Scenario:** Fetch non-existent resource

**Test Steps:**
1. Fetch loan with ID 999999 from Flutter
2. Fetch loan with ID 999999 from Web
3. Compare error responses

**Expected Error:**
```json
{
  "success": false,
  "message": "Loan not found"
}
```

**Pass Criteria:** ✅ Same 404 error format

---

### Test 4.4: Permission Error
**Scenario:** User tries to access another user's loan

**Test Steps:**
1. User A creates loan
2. User B tries to access loan from Flutter
3. User B tries to access loan from Web
4. Both should get 403 error

**Pass Criteria:** ✅ Same permission denied error

---

### Test 4.5: Server Error Handling
**Scenario:** Simulated server error

**Test Steps:**
1. Send malformed request that causes server error
2. Verify Flutter handles gracefully
3. Verify Web handles gracefully
4. Both should show user-friendly message

**Pass Criteria:** ✅ Same error handling approach

---

## ✅ PHASE 5: CROSS-PLATFORM WORKFLOWS (5 tests)

### Test 5.1: Full Loan Application Journey
**Objective:** Complete workflow starting from one platform, finishing on another

**Scenario:**
1. Start on Flutter: Select loan type
2. Continue on Flutter: Enter personal info
3. Switch to Web: Verify data saved
4. Continue on Web: Add employment info
5. Switch to Flutter: Add guarantor
6. Continue on Flutter: Upload documents
7. Switch to Web: Submit application
8. Verify on Flutter: Application submitted

**Pass Criteria:** ✅ Data persists across platform switches

---

### Test 5.2: Guarantor Acceptance Cross-Platform
**Objective:** Invite guarantor from one platform, accept from another

**Scenario:**
1. Flutter: User creates loan, invites guarantor via email
2. Guarantor receives email
3. Web: Guarantor clicks link, accepts invitation
4. Flutter: Original user sees guarantor accepted

**Pass Criteria:** ✅ Status updates visible across platforms

---

### Test 5.3: Payment Recording Cross-Platform
**Objective:** Record payment from one app, verify in another

**Scenario:**
1. Web: User records loan payment
2. Flutter: Verify payment appears in loan details
3. Flutter: Verify remaining balance updated
4. Web: Verify payment history shows new entry

**Pass Criteria:** ✅ Payment data synchronized immediately

---

### Test 5.4: KYC Submission and Admin Review
**Objective:** Submit KYC from one platform, review on another

**Scenario:**
1. Flutter: User submits KYC data
2. Web Admin: Review KYC submission
3. Web Admin: Approve KYC
4. Flutter: User sees KYC status updated

**Pass Criteria:** ✅ Status changes propagate correctly

---

### Test 5.5: Profile Update Sync
**Objective:** Update profile on one platform, verify on another

**Scenario:**
1. Flutter: Update profile name and phone
2. Web: Immediately refresh, see updates
3. Web: Update email preference
4. Flutter: Refresh, see updates
5. Logout on Flutter, login on Web
6. Verify all changes persisted

**Pass Criteria:** ✅ All updates persist across sessions and platforms

---

## ✅ PHASE 6: PERFORMANCE & LOAD (3 tests)

### Test 6.1: Response Time Consistency
**Objective:** Verify similar response times from both platforms

**Test:**
1. Flutter: Measure response time for 10 loan list requests
2. Web: Measure response time for 10 loan list requests
3. Calculate average
4. Verify within 20% variance

**Pass Criteria:** ✅ Response times comparable

---

### Test 6.2: Large Data Set Handling
**Objective:** Verify both handle large lists

**Test:**
1. Create 100 transactions
2. Fetch from Flutter (with pagination)
3. Fetch from Web (with pagination)
4. Verify pagination format matches
5. Verify no data loss

**Pass Criteria:** ✅ Large lists handled consistently

---

### Test 6.3: Concurrent Request Handling
**Objective:** Verify no race conditions

**Test:**
1. Send 5 concurrent requests from Flutter
2. Send 5 concurrent requests from Web
3. Verify all respond correctly
4. Verify no data corruption

**Pass Criteria:** ✅ No race conditions

---

## 📋 FINAL VERIFICATION CHECKLIST

### Pre-Test Setup
- [ ] Backend API running
- [ ] Test database initialized with seed data
- [ ] Flutter app configured with API URL
- [ ] Web app configured with API URL
- [ ] Test user accounts created
- [ ] Test admin account created
- [ ] Network connectivity verified
- [ ] Both apps can connect to API

### During Tests
- [ ] Monitor API response times
- [ ] Check for any error logs
- [ ] Monitor database transactions
- [ ] Watch for data consistency issues
- [ ] Verify token handling

### Post-Test Analysis
- [ ] All 45+ tests passing ✅
- [ ] No data corruption detected ✅
- [ ] Response times acceptable ✅
- [ ] Error handling consistent ✅
- [ ] Cross-platform workflows working ✅

---

## 🎯 PASS/FAIL CRITERIA

### PASS: All of the following are true
- ✅ 45/45 test cases passing
- ✅ No data corruption detected
- ✅ Error responses consistent format
- ✅ Cross-platform workflows complete
- ✅ Response times < 2 seconds
- ✅ Zero race conditions
- ✅ 100% uptime during tests

### FAIL: Any of the following occur
- ❌ Any test case fails
- ❌ Data inconsistency detected
- ❌ Error format differs between platforms
- ❌ Cross-platform workflow broken
- ❌ Response time > 5 seconds
- ❌ Race condition detected
- ❌ API downtime during tests

---

## 🚀 POST-TEST DEPLOYMENT

**If ALL tests pass:**
✅ Proceed to production deployment

**If ANY test fails:**
❌ Investigate failure, fix issue, re-run tests

**Retest Checklist:**
- [ ] Issue identified
- [ ] Fix implemented
- [ ] Code reviewed
- [ ] Unit tests updated
- [ ] Re-run full test suite
- [ ] All 45+ tests passing
- [ ] Ready for production

---

## 📊 TEST EXECUTION RECORD

| Test Phase | Test Count | Status | Date |
|-----------|-----------|--------|------|
| Phase 1: Authentication | 5 | ⏳ Pending | |
| Phase 2: Data Models | 8 | ⏳ Pending | |
| Phase 3: Endpoints | 12 | ⏳ Pending | |
| Phase 4: Error Handling | 5 | ⏳ Pending | |
| Phase 5: Workflows | 5 | ⏳ Pending | |
| Phase 6: Performance | 3 | ⏳ Pending | |
| **TOTAL** | **45** | **⏳ Ready** | |

---

**Guide Created:** Current Session  
**Estimated Duration:** 2-3 hours  
**Recommended:** Run before production deployment  

