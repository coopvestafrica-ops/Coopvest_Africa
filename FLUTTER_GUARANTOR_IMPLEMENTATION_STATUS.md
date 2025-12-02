# Flutter App - Guarantor System Implementation Status

**Last Updated:** November 12, 2025
**Status:** ✅ Core implementation COMPLETE | 🔄 Enhancements IN PROGRESS

---

## Executive Summary

The Flutter app has **extensive guarantor system infrastructure** already implemented across multiple layers:
- ✅ **3 Core Models** (Guarantor, GuarantorInvitation, GuarantorVerification)
- ✅ **2 Service Classes** (GuarantorService, GuarantorEligibilityService)
- ✅ **3 Main Screens** (GuarantorScanScreen, GuarantorLoanScreen, MyGuaranteesScreen)
- ✅ **8+ UI Widgets** (GuarantorCard, GuarantorStatusBadge, GuarantorLiabilityCard, etc.)
- ✅ **QR Code Integration** (Mobile scanner + generation)
- ✅ **Document Upload Capability** (Verification documents)
- ✅ **Eligibility Checking** (Dedicated service)

**Key Finding:** The Flutter app is actually **MORE COMPLETE** than the web app was at the start. Most core features are implemented; what remains are enhancements and minor fixes.

---

## PART 1: WHAT'S ALREADY IMPLEMENTED ✅

### 1.1 Models (lib/models/)

#### **Guarantor.dart** (209 lines)
```
Status: ✅ FULLY IMPLEMENTED
Lines: 209 | Complexity: HIGH
```

**Features:**
- Complete guarantor profile with all fields
- Relationship tracking (friend, family, colleague, business_partner)
- Dual status system: verification + confirmation
- Employment verification support
- QR code management (generation, token, expiration)
- Liability amount tracking
- Full JSON serialization/deserialization
- Helper properties:
  - `hasAccepted` - Check confirmation status
  - `isVerified` - Check verification status
  - `isQrCodeValid` - Check QR expiration
  - `liabilityPercentage` - Calculate percentage

**Database Fields:**
```
id, loanId, guarantorUserId, guarantorName, guarantorEmail, guarantorPhone,
relationship, verificationStatus, confirmationStatus, employmentVerificationRequired,
employmentVerificationCompleted, employmentVerificationUrl, qrCode, qrCodeToken,
qrCodeExpiresAt, notes, liabilityAmount, createdAt, updatedAt
```

---

#### **GuarantorInvitation.dart** (159 lines)
```
Status: ✅ FULLY IMPLEMENTED
Lines: 159 | Complexity: MEDIUM
```

**Features:**
- Invitation lifecycle tracking
- Token-based access (for QR scanning)
- Expiration management (7-day default)
- Status workflow: pending → accepted/declined/expired
- Contextual data (loan amount, duration)
- Time remaining calculation
- Full JSON serialization

**Database Fields:**
```
id, loanId, guarantorEmail, guarantorPhone, guarantorName, invitationToken,
invitationLink, status, sentAt, acceptedAt, expiresAt, relationship,
loanAmount, loanDurationMonths
```

**Helper Methods:**
- `isValid` - Check if invitation is still active
- `hasExpired` - Check if expired
- `timeRemaining` - Get duration until expiration
- `hoursRemaining` - Get hours remaining

---

#### **GuarantorVerification.dart** (177 lines)
```
Status: ✅ FULLY IMPLEMENTED
Lines: 177 | Complexity: MEDIUM
```

**Structures:**
1. **VerificationDocument** - Individual document tracking
2. **GuarantorVerification** - Overall verification status

**Features:**
- Document management (6 types supported)
- Status workflow: pending → verified/rejected
- Rejection reason tracking
- Verifier notes
- Employment verification specific handling
- Full JSON serialization

**Document Types Supported:**
- employment_letter
- payslip
- bank_statement
- id_card
- business_license
- registration_document

---

### 1.2 Services (lib/services/)

#### **GuarantorService.dart** (413 lines)
```
Status: ✅ FULLY IMPLEMENTED
Lines: 413 | Complexity: HIGH
```

**API Endpoints Implemented (19 methods):**

**Guarantor Management (5 methods):**
1. `getGuarantorsForLoan(String loanId)` - GET all guarantors for loan
2. `getGuarantorById(String guarantorId)` - GET specific guarantor
3. `inviteGuarantor(...)` - POST create/invite guarantor
4. `removeGuarantor(String loanId, guarantorId)` - DELETE guarantor

**Guarantor Invitations (5 methods):**
1. `getPendingInvitations()` - GET user's pending invitations
2. `getInvitationByToken(String token)` - GET invitation by token (public)
3. `acceptInvitation(String token)` - POST accept via token
4. `declineInvitation(String token, reason?)` - POST decline invitation

**Guarantor Verification (3 methods):**
1. `getVerificationStatus(String guarantorId)` - GET verification status
2. `submitVerificationDocuments(guarantorId, documentPaths)` - POST documents
3. `uploadEmploymentVerification(guarantorId, documentPath)` - POST employment doc

**Legacy Methods (6 methods - for compatibility):**
1. `validateGuarantorEligibility(String loanId)`
2. `getLoanDetails(String code)`
3. `confirmGuarantee(String code)`
4. `getMyGuarantees()`
5. `revokeGuarantee(String loanId, reason?)`
6. `getQrCode(String loanId)`

**Authentication:**
- ✅ Bearer token handling
- ✅ Automatic header generation
- ✅ Token refresh logic
- ✅ Error handling with descriptive messages

---

#### **GuarantorEligibilityService.dart** (varies)
```
Status: ✅ IMPLEMENTED
Complexity: MEDIUM
```

**Features:**
- Eligibility checking per member
- Risk score calculation
- Integration with WordPress backend

---

### 1.3 Screens (lib/)

#### **GuarantorScanScreen.dart** (229 lines)
```
Status: ✅ FULLY IMPLEMENTED
Type: QR Scanner Screen
```

**Features:**
- Mobile camera integration (mobile_scanner plugin)
- QR code detection and parsing
- Error handling and user feedback
- Camera permission management
- Torch (flashlight) control
- Loading states
- Scanned result processing

**Flow:**
```
Camera → QR Detected → Parse Data → Navigate to Confirmation → Process
```

---

#### **GuarantorLoanScreen.dart** (460 lines)
```
Status: ✅ FULLY IMPLEMENTED
Type: Guarantor Acceptance Screen (Loan Recipient View)
```

**Features:**
- QR code scanning for guarantor invitations
- Manual code entry field
- Eligibility validation
- Savings threshold checking
- Membership verification
- Loan details display
- Guarantee statistics

**Workflow:**
1. Scan guarantor QR code
2. Validate membership & savings
3. Show loan details
4. Request guarantee confirmation
5. Submit guarantee

---

#### **MyGuaranteesScreen.dart** (216 lines)
```
Status: ✅ FULLY IMPLEMENTED
Type: User's Guarantor Obligations View
```

**Features:**
- List of user's active guarantees
- Loan information display
- Liability tracking
- Revocation functionality
- Warning messages about liability
- Load more / pagination support
- Refresh capability

**Displayed Information:**
- Borrower name and profile
- Loan amount & status
- User's liability amount
- Repayment status
- Revocation reason dialog

---

### 1.4 UI Widgets (lib/widgets/ & lib/features/)

#### **GuarantorCard.dart** ✅
```
Purpose: Display guarantor profile card
Status: IMPLEMENTED
Features: Name, email, phone, status badges, liability
```

#### **GuarantorStatusBadge.dart** ✅
```
Purpose: Visual status indicator
Status: IMPLEMENTED
Features: Color-coded status (pending, accepted, verified, rejected)
```

#### **GuarantorLiabilityCard.dart** ✅
```
Purpose: Display liability information
Status: IMPLEMENTED
Features: Amount, percentage, loan reference
```

#### **GuarantorEligibilityCard.dart** ✅
```
Purpose: Eligibility indicator
Status: IMPLEMENTED
Features: Eligibility status, requirements check
```

#### **GuarantorQRCode.dart** (in features/) ✅
```
Purpose: Display QR code
Status: IMPLEMENTED
```

#### **GuarantorStatusCard.dart** (in features/) ✅
```
Purpose: Status display card
Status: IMPLEMENTED
```

#### **GuarantorApprovalDialog.dart** (in features/) ✅
```
Purpose: Approval confirmation dialog
Status: IMPLEMENTED
```

#### **LoanGuarantorWidget** (in features/loan/) ✅
```
Purpose: Loan-specific guarantor display
Status: IMPLEMENTED
```

---

### 1.5 Additional Models

#### **LoanApplicationGuarantor.dart** ✅
```
Purpose: Guarantor model for loan applications
Status: IMPLEMENTED
```

#### **LoanGuarantor.dart** (in features/loan/domain/) ✅
```
Purpose: Domain model for loan guarantors
Status: IMPLEMENTED
```

---

## PART 2: WHAT NEEDS IMPLEMENTATION 🔄

### 2.1 HIGH PRIORITY (Must Have)

#### **A. API Integration Updates**
```
Priority: HIGH
Effort: 2-3 hours
Blocker: None
```

**Issue:** Some legacy endpoints are still being used. Need to migrate to new backend API.

**Required Actions:**
1. ✅ Verify all `GuarantorService` endpoints match web app API
   - Update `getPendingInvitations()` endpoint (currently uses `/guarantor/pending-invitations`)
   - Backend endpoint: `GET /guarantor/pending-requests` (per web app)
   
2. ✅ Verify QR code acceptance flow
   - Backend endpoint: `POST /guarantor-invitations/{token}/accept`
   - Backend endpoint: `POST /guarantor-invitations/{token}/decline`

3. ⚠️ Check document upload endpoints
   - Backend endpoint: `POST /guarantors/{id}/documents`
   - Need multipart form data support (already implemented!)

4. ⚠️ Verify email notification on invitation
   - Backend: GuarantorInvitationMail should send when invitation created
   - Flutter doesn't need to send emails (backend handles)

---

#### **B. QR Code Acceptance Completion**
```
Priority: HIGH
Effort: 4-6 hours
Blocker: API compatibility
```

**Current Status:** QR scanning works, but acceptance flow may be incomplete.

**Required Enhancements:**
1. ✅ Implement full QR code acceptance flow
   - Parse QR token from scanned code
   - Call `acceptInvitation(token)` 
   - Handle email field (required by backend for verification)
   - Show loading state during submission

2. ⚠️ Add verification phone number field
   - Backend expects verification via phone during acceptance
   - Need to collect phone number in acceptance form
   - Validate phone format

3. ✅ Handle acceptance errors gracefully
   - Expired token
   - Invalid token
   - Already accepted
   - User already a guarantor

4. 🟡 Confirmation dialog after acceptance
   - Show success message
   - Display guarantor obligations
   - Show liability amount
   - Confirm understanding of liability

---

#### **C. Loan Application Integration**
```
Priority: HIGH
Effort: 5-6 hours
Blocker: None (optional feature, can work independently)
```

**Required Enhancements:**
1. ⚠️ Add guarantor section to `LoanApplicationScreen`
   - Section after loan details
   - "Add Guarantors" button
   - Guarantor list with status
   - Option to invite more guarantors

2. 🟡 Implement inviter functionality
   - Display QR code for guarantors to scan
   - Copy invitation link to clipboard
   - Send invitation via WhatsApp/SMS
   - Email integration (copy link)

3. ⚠️ Validation before submission
   - Require 3 guarantors for most loan types
   - Check all guarantors are verified (for some loan types)
   - Warn if not all guarantors accepted yet

4. 🟡 Display in application summary
   - Show list of guarantors
   - Show status of each guarantor
   - Allow removal/addition before final submission

---

### 2.2 MEDIUM PRIORITY (Should Have)

#### **D. Guarantor Verification Document Upload**
```
Priority: MEDIUM
Effort: 3-4 hours
Blocker: None (optional enhancement)
```

**Current Status:** Service methods exist, but UI may be incomplete.

**Required Enhancements:**
1. ⚠️ Create DocumentUploadScreen
   - File picker integration (file_picker plugin)
   - Support multiple document types:
     - employment_letter
     - id_document
     - bank_statement
     - payslip
     - business_license
     - registration_document
   - File size limit: 5MB
   - Allowed formats: PDF, JPG, PNG

2. 🟡 Image compression
   - Compress images before upload
   - Use flutter_image_compress plugin
   - Target size: 2-3MB per file

3. 🟡 Upload progress tracking
   - Show progress bar during upload
   - Retry on failure
   - Handle network errors

4. 🟡 Document status display
   - Show uploaded documents
   - Display verification status (pending/verified/rejected)
   - Show rejection reason if rejected
   - Allow re-upload

---

#### **E. Employment Verification Workflow**
```
Priority: MEDIUM
Effort: 4-5 hours
Blocker: None
```

**Current Status:** Models support it, but UI flow may need work.

**Required Enhancements:**
1. 🟡 Create EmploymentVerificationFlow
   - Check if employment verification required
   - If yes, show verification section
   - Allow upload of employment letter or payslip
   - Show status: pending/verified/rejected

2. 🟡 Optional vs Required handling
   - Make section optional/required based on guarantor setup
   - Skip if not required
   - Require if marked as required

---

#### **F. Guarantor List & Management Screen**
```
Priority: MEDIUM
Effort: 3-4 hours
Blocker: None
```

**Current Status:** Basic screens exist.

**Required Enhancements:**
1. 🟡 Create comprehensive GuarantorListScreen
   - Borrowed guarantors (guarantors for user's loans)
   - Active guarantees (user's obligations)
   - Pending invitations (awaiting response)
   - Past guarantees (completed/revoked)

2. 🟡 Filter & sort options
   - Filter by status
   - Sort by date, name, amount
   - Search by name/email

3. 🟡 Guarantor details view
   - Full profile display
   - Liability details
   - Verification documents
   - Timeline of actions

4. 🟡 Action buttons
   - Resend invitation (if pending)
   - Remove guarantor (if not verified)
   - View documents
   - Contact guarantor

---

### 2.3 LOW PRIORITY (Nice to Have)

#### **G. Notifications System**
```
Priority: LOW
Effort: 2-3 hours
Blocker: None
```

**Required Enhancements:**
1. 📱 Push notifications
   - New guarantor invitation
   - Guarantor accepted/declined
   - Guarantor verified/rejected
   - Documents uploaded
   - Verification completed

2. 📧 In-app notifications
   - Notification center
   - Mark as read
   - Clear old notifications

---

#### **H. Analytics & Reporting**
```
Priority: LOW
Effort: 2-3 hours
Blocker: None
```

**Required Enhancements:**
1. 📊 Stats dashboard
   - Total guarantees given
   - Total guarantees received
   - Success rate
   - Average response time

---

#### **I. Admin Features**
```
Priority: LOW (Requires backend support)
Effort: 3-4 hours
Blocker: Backend admin endpoints
```

**Required Enhancements:**
1. 👨‍💼 Admin dashboard (if user is admin)
   - Pending guarantor verifications
   - Approve/reject guarantors
   - View all guarantees
   - Statistics and reports

---

## PART 3: NEXT STEPS (RECOMMENDED ORDER)

### Phase 1: Fix API Compatibility (1-2 hours)
**Goal:** Ensure all Flutter API calls match backend endpoints

```dart
✅ COMPLETED IN WEB APP:
- GET /api/loans/{loanId}/guarantors
- POST /api/loans/{loanId}/guarantors/invite
- DELETE /api/loans/{loanId}/guarantors/{id}
- GET /api/guarantors/{id}
- GET /api/guarantor/pending-requests  ⚠️ Flutter uses /pending-invitations
- GET /api/guarantor/my-obligations
- POST /api/guarantor-invitations/{token}/accept
- POST /api/guarantor-invitations/{token}/decline
- GET /api/guarantors/{id}/documents
- POST /api/guarantors/{id}/documents
- GET /api/guarantors/{id}/qr-code

ACTIONS:
1. Search `guarantor_service.dart` for wrong endpoint paths
2. Update endpoint URLs to match backend
3. Test each endpoint with Postman/Insomnia first
4. Update any failed requests handling
```

**Files to Check:**
- `lib/services/guarantor_service.dart` - Update endpoint paths
- `lib/guarantor_loan_screen.dart` - Verify API calls
- `lib/guarantor_scan_screen.dart` - Verify API calls
- `lib/my_guarantees_screen.dart` - Verify API calls

---

### Phase 2: Complete QR Code Acceptance (3-4 hours)
**Goal:** Full end-to-end guarantor acceptance workflow

**Steps:**
1. Create `GuarantorAcceptanceForm` with:
   - Display scanned loan details
   - Email field (auto-filled if logged in)
   - Phone number field (for verification)
   - Terms & conditions checkbox
   - Accept button with loading state

2. Update `GuarantorScanScreen` to show form after scan

3. Implement error handling:
   - Expired QR code
   - Invalid format
   - Already accepted
   - Not eligible

4. Test with real QR codes from web app

---

### Phase 3: Loan Application Integration (4-5 hours)
**Goal:** Seamlessly integrate guarantor workflow with loan application

**Steps:**
1. Update `LoanApplicationScreen`:
   - Add "Add Guarantors" section after loan details
   - Show guarantor list
   - Display invite QR code
   - Show guarantor status indicators

2. Create `GuarantorInvitationWidget`:
   - Display QR code
   - Show copy link button
   - Share via WhatsApp/SMS/Email

3. Validation before submission:
   - Check minimum guarantors (usually 3)
   - Check all guarantors accepted
   - Check verification status based on loan type

4. Display in summary:
   - Show all guarantors with status
   - Option to edit before final submit

---

### Phase 4: Document Upload UI (2-3 hours)
**Goal:** Complete document upload workflow

**Steps:**
1. Create `DocumentUploadScreen`:
   - File picker for each document type
   - Image compression before upload
   - Progress bar during upload
   - Success/error messages

2. Create `DocumentStatusWidget`:
   - Show uploaded documents
   - Display verification status
   - Show rejection reason
   - Allow re-upload

3. Integrate into guarantor flow:
   - After acceptance, show document upload section
   - Make optional/required based on settings

---

### Phase 5: Testing & Quality Assurance (2-3 hours)
**Goal:** Ensure all flows work end-to-end

**Test Cases:**
```
1. QR Code Scanning
   ✓ Valid QR codes parse correctly
   ✓ Invalid codes show error
   ✓ Expired codes handled gracefully

2. Guarantor Acceptance
   ✓ Accept with valid token
   ✓ Decline with reason
   ✓ Email verification works
   ✓ Already accepted error

3. Document Upload
   ✓ Single file upload works
   ✓ Multiple files upload correctly
   ✓ File size validation works
   ✓ Compression works (large images)

4. Loan Integration
   ✓ Guarantors required before submission
   ✓ Status displayed correctly
   ✓ Can edit guarantors before final submit

5. End-to-End Workflow
   ✓ Create loan → Invite guarantors → Accept → Verify → Submit
```

---

## PART 4: CODE EXAMPLES

### Example 1: Fix API Endpoint

**Current (possibly wrong):**
```dart
// ❌ May be wrong endpoint
final response = await http.get(
  Uri.parse('$baseUrl/api/guarantor/pending-invitations'),
  headers: headers,
);
```

**Should be (web app standard):**
```dart
// ✅ Correct endpoint matching web app
final response = await http.get(
  Uri.parse('$baseUrl/api/guarantor/pending-requests'),
  headers: headers,
);
```

---

### Example 2: Complete QR Code Acceptance Form

```dart
class GuarantorAcceptanceForm extends StatefulWidget {
  final String token;
  final Map<String, dynamic> loanDetails;

  const GuarantorAcceptanceForm({
    required this.token,
    required this.loanDetails,
  });

  @override
  State<GuarantorAcceptanceForm> createState() =>
      _GuarantorAcceptanceFormState();
}

class _GuarantorAcceptanceFormState extends State<GuarantorAcceptanceForm> {
  late TextEditingController emailController;
  late TextEditingController phoneController;
  bool acceptedTerms = false;
  bool isLoading = false;
  final _guarantorService = GuarantorService();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    // Pre-fill with current user's email if available
  }

  Future<void> _submitAcceptance() async {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final guarantor = await _guarantorService.acceptInvitation(widget.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted successfully!')),
        );
        Navigator.pop(context, guarantor);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accept Guarantor Invitation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Loan details display
            // Email field
            // Phone field
            // Terms checkbox
            // Accept button with loading state
          ],
        ),
      ),
    );
  }
}
```

---

### Example 3: Loan Application Integration

```dart
// In LoanApplicationScreen

@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // ... existing loan details ...
        
        // NEW: Guarantor section
        const SizedBox(height: 24),
        Text('Guarantors', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        
        // Guarantor count
        if (_guarantors.isEmpty)
          const Text('No guarantors added yet')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _guarantors.length,
            itemBuilder: (context, index) {
              final guarantor = _guarantors[index];
              return GuarantorCard(guarantor: guarantor);
            },
          ),
        
        const SizedBox(height: 12),
        
        // Add guarantor button
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Guarantor'),
          onPressed: _showAddGuarantorDialog,
        ),
        
        // Validation message
        if (_guarantors.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'You need at least 3 guarantors',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
      ],
    ),
  );
}
```

---

## PART 5: IMPLEMENTATION CHECKLIST

### Phase 1: API Compatibility
- [ ] Review all `GuarantorService` methods
- [ ] Verify endpoint URLs match backend
- [ ] Test each endpoint
- [ ] Update any mismatched URLs
- [ ] Update error handling
- [ ] Deploy and test in staging

### Phase 2: QR Code Acceptance
- [ ] Create acceptance form screen
- [ ] Implement full acceptance flow
- [ ] Add phone verification field
- [ ] Error handling for all cases
- [ ] Test with real QR codes
- [ ] Update tests

### Phase 3: Loan Integration
- [ ] Add guarantor section to loan application
- [ ] Create invitation QR display widget
- [ ] Implement validation logic
- [ ] Update loan submission
- [ ] Test full workflow
- [ ] Update tests

### Phase 4: Document Upload
- [ ] Create upload screen
- [ ] Implement file picker
- [ ] Add image compression
- [ ] Create status display
- [ ] Error handling
- [ ] Update tests

### Phase 5: Testing
- [ ] Unit tests for all methods
- [ ] Widget tests for all screens
- [ ] Integration tests for workflows
- [ ] QR code scanning tests
- [ ] Document upload tests
- [ ] End-to-end tests

---

## PART 6: KNOWN ISSUES & GOTCHAS

### Issue 1: Endpoint Mismatch ⚠️
```
Issue: Flutter may use different endpoint paths than web app
Solution: Update all paths in GuarantorService to match web app backend
Status: NEEDS VERIFICATION
```

### Issue 2: Phone Number Verification
```
Issue: Backend may require phone number during acceptance for OTP
Solution: Add phone field to acceptance form, implement OTP if needed
Status: TO BE CONFIRMED WITH BACKEND
```

### Issue 3: Email Field During Acceptance
```
Issue: Backend expects email in acceptance request
Solution: Pre-fill with user's email or request user input
Status: NEEDS IMPLEMENTATION
```

### Issue 4: Document Compression
```
Issue: Large image uploads may timeout
Solution: Implement image compression before upload (use flutter_image_compress)
Status: SERVICE READY, UI PENDING
```

### Issue 5: QR Code Generation
```
Issue: Flutter needs to generate QR codes for sharing
Solution: Already integrated? Verify qr_flutter or similar plugin
Status: NEEDS VERIFICATION
```

---

## PART 7: DEPENDENCIES CHECK

**Already in pubspec.yaml (verify):**
- ✅ `mobile_scanner` - QR code scanning
- ✅ `http` - API calls
- ✅ `shared_preferences` - Token storage
- ✅ `file_picker` - File selection (if installed)

**May need to add:**
- 📦 `flutter_image_compress` - Image compression
- 📦 `qr_flutter` - QR code generation
- 📦 `share_plus` - Share functionality
- 📦 `url_launcher` - Open WhatsApp/SMS links

---

## SUMMARY

| Component | Status | Priority | Time | Notes |
|-----------|--------|----------|------|-------|
| Models | ✅ Complete | - | - | All 3 models fully implemented |
| Services | ✅ Complete | High | 1-2h | Need endpoint verification |
| Screens | ✅ Complete | High | 4-6h | QR acceptance flow enhancement |
| Widgets | ✅ Complete | - | - | All 8+ widgets implemented |
| Integration | 🔄 Partial | High | 4-5h | Loan app integration needed |
| Documents | 🟡 Partial | Medium | 2-3h | UI components needed |
| Verification | 🟡 Partial | Medium | 3-4h | Workflow refinement |
| Notifications | ❌ Not Started | Low | 2-3h | Nice to have |
| Admin | ❌ Not Started | Low | 3-4h | Backend dependent |

**Total Estimated Time:** 20-30 hours for full completion

**Critical Path:** API Verification (2h) → QR Acceptance (4h) → Loan Integration (5h) = 11 hours

---

## FILES REFERENCE

**Models:**
- `lib/models/guarantor.dart`
- `lib/models/guarantor_invitation.dart`
- `lib/models/guarantor_verification.dart`
- `lib/models/loan_application_guarantor.dart`
- `lib/features/loan/domain/models/loan_guarantor.dart`

**Services:**
- `lib/services/guarantor_service.dart`
- `lib/services/guarantor_eligibility_service.dart`

**Screens:**
- `lib/guarantor_scan_screen.dart`
- `lib/guarantor_loan_screen.dart`
- `lib/my_guarantees_screen.dart`

**Widgets:**
- `lib/widgets/guarantor_card.dart`
- `lib/widgets/guarantor_status_badge.dart`
- `lib/widgets/guarantor_liability_card.dart`
- `lib/widgets/guarantor_eligibility_card.dart`
- `lib/features/loan/presentation/widgets/guarantor_qr_code.dart`
- `lib/features/loan/presentation/widgets/guarantor_status_card.dart`
- `lib/features/loan/presentation/widgets/guarantor_approval_dialog.dart`

---

## NEXT IMMEDIATE ACTION

**Start with Phase 1 (API Verification):**
1. Open `lib/services/guarantor_service.dart`
2. Compare each endpoint with web app backend API
3. Create a table of all 19 methods vs their backend endpoints
4. Test each endpoint with Postman
5. Fix any mismatches
6. Deploy and test in staging

**Estimated Time:** 1-2 hours
**Blocker Level:** CRITICAL - Must complete before moving to other phases

---

**Document prepared for:** Development Team
**Contact:** [Your Name]
**Last Updated:** November 12, 2025
