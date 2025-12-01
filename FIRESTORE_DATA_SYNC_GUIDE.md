# 🔥 Flutter to Firestore - Complete Data Sync Guide

**Objective:** Sync all Flutter app entries (Users, Loans, Applications, Guarantors, KYC, etc.) to Firestore  
**Status:** Implementation Guide  
**Date:** November 18, 2025  

---

## 📊 OVERVIEW

Your Flutter app will insert data into Firestore collections following this structure:

```
Firestore Database
├── users/
│   ├── {userId}
│   │   ├── email
│   │   ├── firstName
│   │   ├── lastName
│   │   ├── phoneNumber
│   │   ├── kycStatus
│   │   └── createdAt
│
├── loans/
│   ├── {loanId}
│   │   ├── userId
│   │   ├── amount
│   │   ├── status
│   │   ├── loanTypeId
│   │   └── createdAt
│
├── loanApplications/
│   ├── {applicationId}
│   │   ├── userId
│   │   ├── loanTypeId
│   │   ├── status
│   │   ├── stage
│   │   └── createdAt
│
├── guarantors/
│   ├── {guarantorId}
│   │   ├── loanId
│   │   ├── userId
│   │   ├── verificationStatus
│   │   └── createdAt
│
├── kycVerifications/
│   ├── {kycId}
│   │   ├── userId
│   │   ├── fullName
│   │   ├── status
│   │   └── createdAt
│
├── transactions/
│   ├── {transactionId}
│   │   ├── userId
│   │   ├── amount
│   │   ├── type
│   │   └── createdAt
│
└── documents/
    ├── {documentId}
    │   ├── userId
    │   ├── type
    │   ├── fileUrl
    │   └── uploadedAt
```

---

## ✅ STEP 1: CREATE FIRESTORE COLLECTIONS STRUCTURE

### Collections to Create

1. **users** - User profiles
2. **loans** - Active loans
3. **loanApplications** - Loan applications
4. **guarantors** - Guarantor relationships
5. **kycVerifications** - KYC data
6. **transactions** - Transaction history
7. **documents** - Uploaded documents
8. **loanPayments** - Payment records
9. **savings** - Savings accounts
10. **contributions** - Contribution records

---

## ✅ STEP 2: CREATE DATA SYNC SERVICES

### Create Loan Service for Firestore

Create file: `lib/core/services/firestore_loan_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../models/loan.dart';

/// Service for syncing loans to Firestore
class FirestoreLoanService {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('FirestoreLoanService');

  /// Insert a single loan into Firestore
  Future<void> insertLoan(Loan loan) async {
    try {
      _logger.info('Inserting loan: ${loan.id}');
      
      await _firebase.firestore
          .collection('loans')
          .doc(loan.id)
          .set(
            loan.toJson(),
            SetOptions(merge: true),
          );
      
      _logger.info('Successfully inserted loan: ${loan.id}');
    } catch (e, stack) {
      _logger.severe('Failed to insert loan', e, stack);
      rethrow;
    }
  }

  /// Insert multiple loans in batch (more efficient)
  Future<void> insertLoansInBatch(List<Loan> loans) async {
    try {
      _logger.info('Inserting ${loans.length} loans in batch');
      
      final batch = _firebase.firestore.batch();
      
      for (final loan in loans) {
        final docRef = _firebase.firestore.collection('loans').doc(loan.id);
        batch.set(docRef, loan.toJson(), SetOptions(merge: true));
      }
      
      await batch.commit();
      _logger.info('Successfully inserted ${loans.length} loans');
    } catch (e, stack) {
      _logger.severe('Failed to insert loans in batch', e, stack);
      rethrow;
    }
  }

  /// Update loan status
  Future<void> updateLoanStatus(String loanId, String status) async {
    try {
      await _firebase.firestore
          .collection('loans')
          .doc(loanId)
          .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      
      _logger.info('Updated loan $loanId status to $status');
    } catch (e, stack) {
      _logger.severe('Failed to update loan status', e, stack);
      rethrow;
    }
  }

  /// Get all loans for a user
  Future<List<Loan>> getUserLoans(String userId) async {
    try {
      final snapshot = await _firebase.firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Loan.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to get user loans', e, stack);
      rethrow;
    }
  }

  /// Stream loans for real-time updates
  Stream<List<Loan>> streamUserLoans(String userId) {
    return _firebase.firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Loan.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
```

---

### Create Loan Application Service

Create file: `lib/core/services/firestore_loan_application_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../models/loan_application.dart';

/// Service for syncing loan applications to Firestore
class FirestoreLoanApplicationService {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('FirestoreLoanApplicationService');

  /// Insert a loan application
  Future<void> insertApplication(LoanApplication app) async {
    try {
      _logger.info('Inserting loan application: ${app.id}');
      
      await _firebase.firestore
          .collection('loanApplications')
          .doc(app.id)
          .set(
            app.toJson(),
            SetOptions(merge: true),
          );
      
      _logger.info('Successfully inserted application: ${app.id}');
    } catch (e, stack) {
      _logger.severe('Failed to insert application', e, stack);
      rethrow;
    }
  }

  /// Insert applications in batch
  Future<void> insertApplicationsInBatch(List<LoanApplication> apps) async {
    try {
      _logger.info('Inserting ${apps.length} applications in batch');
      
      final batch = _firebase.firestore.batch();
      
      for (final app in apps) {
        final docRef = _firebase.firestore
            .collection('loanApplications')
            .doc(app.id);
        batch.set(docRef, app.toJson(), SetOptions(merge: true));
      }
      
      await batch.commit();
      _logger.info('Successfully inserted ${apps.length} applications');
    } catch (e, stack) {
      _logger.severe('Failed to insert applications batch', e, stack);
      rethrow;
    }
  }

  /// Update application stage
  Future<void> updateApplicationStage(String appId, String stage) async {
    try {
      await _firebase.firestore
          .collection('loanApplications')
          .doc(appId)
          .update({
            'stage': stage,
            'updatedAt': FieldValue.serverTimestamp()
          });
      
      _logger.info('Updated application $appId stage to $stage');
    } catch (e, stack) {
      _logger.severe('Failed to update application stage', e, stack);
      rethrow;
    }
  }

  /// Get applications for user
  Future<List<LoanApplication>> getUserApplications(String userId) async {
    try {
      final snapshot = await _firebase.firestore
          .collection('loanApplications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => LoanApplication.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to get user applications', e, stack);
      rethrow;
    }
  }
}
```

---

### Create Guarantor Service

Create file: `lib/core/services/firestore_guarantor_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../models/guarantor.dart';

/// Service for syncing guarantors to Firestore
class FirestoreGuarantorService {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('FirestoreGuarantorService');

  /// Insert a guarantor
  Future<void> insertGuarantor(Guarantor guarantor) async {
    try {
      _logger.info('Inserting guarantor: ${guarantor.id}');
      
      await _firebase.firestore
          .collection('guarantors')
          .doc(guarantor.id)
          .set(
            guarantor.toJson(),
            SetOptions(merge: true),
          );
      
      _logger.info('Successfully inserted guarantor: ${guarantor.id}');
    } catch (e, stack) {
      _logger.severe('Failed to insert guarantor', e, stack);
      rethrow;
    }
  }

  /// Insert multiple guarantors in batch
  Future<void> insertGuarantorsInBatch(List<Guarantor> guarantors) async {
    try {
      _logger.info('Inserting ${guarantors.length} guarantors in batch');
      
      final batch = _firebase.firestore.batch();
      
      for (final guarantor in guarantors) {
        final docRef = _firebase.firestore
            .collection('guarantors')
            .doc(guarantor.id);
        batch.set(docRef, guarantor.toJson(), SetOptions(merge: true));
      }
      
      await batch.commit();
      _logger.info('Successfully inserted ${guarantors.length} guarantors');
    } catch (e, stack) {
      _logger.severe('Failed to insert guarantors batch', e, stack);
      rethrow;
    }
  }

  /// Get guarantors for a loan
  Future<List<Guarantor>> getLoanGuarantors(String loanId) async {
    try {
      final snapshot = await _firebase.firestore
          .collection('guarantors')
          .where('loanId', isEqualTo: loanId)
          .get();
      
      return snapshot.docs
          .map((doc) => Guarantor.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to get loan guarantors', e, stack);
      rethrow;
    }
  }
}
```

---

### Create KYC Service

Create file: `lib/core/services/firestore_kyc_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../models/kyc_verification.dart';

/// Service for syncing KYC verifications to Firestore
class FirestoreKycService {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('FirestoreKycService');

  /// Insert KYC verification
  Future<void> insertKycVerification(KycVerification kyc) async {
    try {
      _logger.info('Inserting KYC for user: ${kyc.userId}');
      
      await _firebase.firestore
          .collection('kycVerifications')
          .doc(kyc.id)
          .set(
            kyc.toJson(),
            SetOptions(merge: true),
          );
      
      _logger.info('Successfully inserted KYC: ${kyc.id}');
    } catch (e, stack) {
      _logger.severe('Failed to insert KYC', e, stack);
      rethrow;
    }
  }

  /// Get KYC for user
  Future<KycVerification?> getUserKyc(String userId) async {
    try {
      final snapshot = await _firebase.firestore
          .collection('kycVerifications')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      return KycVerification.fromJson({
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id
      });
    } catch (e, stack) {
      _logger.severe('Failed to get user KYC', e, stack);
      rethrow;
    }
  }

  /// Update KYC status
  Future<void> updateKycStatus(String kycId, String status) async {
    try {
      await _firebase.firestore
          .collection('kycVerifications')
          .doc(kycId)
          .update({
            'verificationStatus': status,
            'updatedAt': FieldValue.serverTimestamp()
          });
      
      _logger.info('Updated KYC $kycId status to $status');
    } catch (e, stack) {
      _logger.severe('Failed to update KYC status', e, stack);
      rethrow;
    }
  }
}
```

---

## ✅ STEP 3: CREATE MASTER SYNC SERVICE

Create file: `lib/core/services/firestore_sync_service.dart`

```dart
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../services/firestore_loan_service.dart';
import '../services/firestore_loan_application_service.dart';
import '../services/firestore_guarantor_service.dart';
import '../services/firestore_kyc_service.dart';
import '../models/user.dart';
import '../models/loan.dart';
import '../models/loan_application.dart';
import '../models/guarantor.dart';
import '../models/kyc_verification.dart';

/// Master service to sync all app data to Firestore
class FirestoreSyncService {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('FirestoreSyncService');
  
  late final FirestoreLoanService loanService;
  late final FirestoreLoanApplicationService applicationService;
  late final FirestoreGuarantorService guarantorService;
  late final FirestoreKycService kycService;

  FirestoreSyncService() {
    loanService = FirestoreLoanService();
    applicationService = FirestoreLoanApplicationService();
    guarantorService = FirestoreGuarantorService();
    kycService = FirestoreKycService();
  }

  /// Sync user data to Firestore
  Future<void> syncUser(User user) async {
    try {
      _logger.info('Syncing user: ${user.id}');
      
      await _firebase.firestore
          .collection('users')
          .doc(user.id)
          .set(
            user.toJson(),
            SetOptions(merge: true),
          );
      
      _logger.info('Successfully synced user: ${user.id}');
    } catch (e, stack) {
      _logger.severe('Failed to sync user', e, stack);
      rethrow;
    }
  }

  /// Sync all loans for a user
  Future<void> syncUserLoans(String userId, List<Loan> loans) async {
    try {
      _logger.info('Syncing ${loans.length} loans for user: $userId');
      
      await loanService.insertLoansInBatch(loans);
      
      _logger.info('Successfully synced ${loans.length} loans');
    } catch (e, stack) {
      _logger.severe('Failed to sync loans', e, stack);
      rethrow;
    }
  }

  /// Sync all loan applications
  Future<void> syncLoanApplications(
      String userId, List<LoanApplication> applications) async {
    try {
      _logger.info('Syncing ${applications.length} applications for user: $userId');
      
      await applicationService.insertApplicationsInBatch(applications);
      
      _logger.info('Successfully synced ${applications.length} applications');
    } catch (e, stack) {
      _logger.severe('Failed to sync applications', e, stack);
      rethrow;
    }
  }

  /// Sync all guarantors for a loan
  Future<void> syncLoanGuarantors(
      String loanId, List<Guarantor> guarantors) async {
    try {
      _logger.info('Syncing ${guarantors.length} guarantors for loan: $loanId');
      
      await guarantorService.insertGuarantorsInBatch(guarantors);
      
      _logger.info('Successfully synced ${guarantors.length} guarantors');
    } catch (e, stack) {
      _logger.severe('Failed to sync guarantors', e, stack);
      rethrow;
    }
  }

  /// Sync KYC data
  Future<void> syncKycVerification(KycVerification kyc) async {
    try {
      _logger.info('Syncing KYC for user: ${kyc.userId}');
      
      await kycService.insertKycVerification(kyc);
      
      _logger.info('Successfully synced KYC');
    } catch (e, stack) {
      _logger.severe('Failed to sync KYC', e, stack);
      rethrow;
    }
  }

  /// Complete sync for a user (syncs everything)
  Future<Map<String, dynamic>> syncCompleteUserData({
    required User user,
    required List<Loan> loans,
    required List<LoanApplication> applications,
    required List<Guarantor> guarantors,
    required KycVerification? kyc,
  }) async {
    try {
      _logger.info('Starting complete sync for user: ${user.id}');
      
      final results = <String, dynamic>{};
      
      // Sync user
      await syncUser(user);
      results['userSynced'] = true;
      
      // Sync loans
      if (loans.isNotEmpty) {
        await syncUserLoans(user.id, loans);
        results['loansSynced'] = loans.length;
      }
      
      // Sync applications
      if (applications.isNotEmpty) {
        await syncLoanApplications(user.id, applications);
        results['applicationsSynced'] = applications.length;
      }
      
      // Sync guarantors
      if (guarantors.isNotEmpty) {
        await syncLoanGuarantors(user.id, guarantors);
        results['guarantorsSynced'] = guarantors.length;
      }
      
      // Sync KYC
      if (kyc != null) {
        await syncKycVerification(kyc);
        results['kycSynced'] = true;
      }
      
      _logger.info('Complete sync finished for user: ${user.id}');
      return results;
    } catch (e, stack) {
      _logger.severe('Failed to complete sync', e, stack);
      rethrow;
    }
  }
}
```

---

## ✅ STEP 4: INTEGRATE INTO YOUR APP

### Update your existing services to call Firestore sync

In your authentication flow (after login/signup):

```dart
// In your AuthService or similar
Future<void> onUserLoggedIn(User user) async {
  // ... existing auth logic ...
  
  // Sync user to Firestore
  final syncService = FirestoreSyncService();
  await syncService.syncUser(user);
}
```

### Sync loans when user fetches them

```dart
// In your LoanService
Future<List<Loan>> getLoans(String userId) async {
  // Fetch from API
  final loans = await _apiService.getLoans();
  
  // Sync to Firestore
  final syncService = FirestoreSyncService();
  await syncService.syncUserLoans(userId, loans);
  
  return loans;
}
```

### Sync loan applications

```dart
// In your LoanApplicationService
Future<List<LoanApplication>> getApplications(String userId) async {
  // Fetch from API
  final apps = await _apiService.getApplications();
  
  // Sync to Firestore
  final syncService = FirestoreSyncService();
  await syncService.syncLoanApplications(userId, apps);
  
  return apps;
}
```

---

## ✅ STEP 5: CREATE A BULK SYNC FEATURE

Create file: `lib/core/services/firestore_bulk_sync_service.dart`

```dart
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../services/firestore_sync_service.dart';

/// Service for bulk syncing all user data at once
class FirestoreBulkSyncService {
  final FirebaseService _firebase = FirebaseService.instance;
  final FirestoreSyncService _syncService = FirestoreSyncService();
  final Logger _logger = Logger('FirestoreBulkSyncService');

  /// Sync all local data to Firestore
  /// This should be called after user logs in or periodically
  Future<Map<String, dynamic>> syncAllData(String userId) async {
    try {
      _logger.info('Starting bulk sync for user: $userId');
      
      final startTime = DateTime.now();
      final results = <String, dynamic>{};
      
      // You would fetch all data from your local storage/API and sync
      // This is a template - adjust based on your actual data sources
      
      // Example:
      // final user = await _userService.getCurrentUser();
      // final loans = await _loanService.getLoans();
      // final apps = await _applicationService.getApplications();
      // final guarantors = await _guarantorService.getGuarantors();
      // final kyc = await _kycService.getKyc();
      
      // await _syncService.syncCompleteUserData(
      //   user: user,
      //   loans: loans,
      //   applications: apps,
      //   guarantors: guarantors,
      //   kyc: kyc,
      // );
      
      final duration = DateTime.now().difference(startTime);
      results['duration'] = duration.inSeconds;
      results['status'] = 'success';
      
      _logger.info('Bulk sync completed in ${duration.inSeconds}s');
      
      return results;
    } catch (e, stack) {
      _logger.severe('Bulk sync failed', e, stack);
      rethrow;
    }
  }
}
```

---

## ✅ STEP 6: FIRESTORE SECURITY RULES

Update your Firestore rules to secure the collections:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users: Can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Loans: Can read/write if user owns the loan
    match /loans/{loanId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Loan Applications: Can read/write if user owns the application
    match /loanApplications/{appId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Guarantors: Can read/write if user is related to the guarantor request
    match /guarantors/{guarantorId} {
      allow read, write: if 
        request.auth.uid == resource.data.userId ||
        request.auth.uid == resource.data.guarantorUserId;
    }
    
    // KYC: Can read/write if user owns the KYC
    match /kycVerifications/{kycId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Transactions: Can read/write if user owns the transaction
    match /transactions/{transactionId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // Documents: Can read/write if user owns the document
    match /documents/{documentId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 📋 IMPLEMENTATION CHECKLIST

- [ ] Create all Firestore service files
- [ ] Create master sync service
- [ ] Create bulk sync service
- [ ] Update authentication flow to sync user
- [ ] Update loan service to sync loans
- [ ] Update loan application service to sync apps
- [ ] Update guarantor service to sync guarantors
- [ ] Update KYC service to sync data
- [ ] Set Firestore security rules
- [ ] Test individual sync operations
- [ ] Test bulk sync
- [ ] Monitor Firestore console for data

---

## 🧪 TESTING THE SYNC

### Test individual operations

```dart
// Test syncing a user
final user = User(
  id: 'user123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
);

final syncService = FirestoreSyncService();
await syncService.syncUser(user);
```

### Test bulk sync

```dart
// Test bulk sync
final bulkSync = FirestoreBulkSyncService();
final results = await bulkSync.syncAllData('user123');
print('Sync results: $results');
```

---

## 🚀 DEPLOYMENT STEPS

1. **Backup Firestore data** (if existing)
2. **Deploy security rules** first
3. **Test individual services** in development
4. **Enable batch operations** gradually
5. **Monitor Firestore usage** during rollout
6. **Check data consistency** after sync
7. **Document the sync process**

---

## ⚠️ IMPORTANT NOTES

### Data Consistency
- Always sync after API calls to keep data fresh
- Use batch writes for efficiency
- Monitor for sync failures

### Performance
- Use batch writes for multiple documents (max 500 per batch)
- Consider pagination for large datasets
- Stream real-time updates for frequently-accessed data

### Costs
- Firestore charges per read/write/delete
- Batch writes count as individual operations
- Monitor your usage in Firebase console

### Troubleshooting
- Check Firebase logs for errors
- Verify security rules aren't blocking writes
- Ensure Firebase is initialized before use
- Check user authentication status

---

## 📞 NEXT STEPS

1. Create all the Firestore service files
2. Integrate sync into your existing services
3. Test with sample data
4. Deploy to production
5. Monitor Firestore console

Would you like me to create specific service implementations or help integrate this into your existing code?

