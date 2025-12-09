import 'package:firebase_auth/firebase_auth.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';

/// Firebase Authentication Service
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting sign up with email: $email');

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info('Sign up successful for user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      AppLogger.error('Sign up failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting sign in with email: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info('Sign in successful for user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      AppLogger.error('Sign in failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.info('Signing out user');
      await _firebaseAuth.signOut();
      AppLogger.info('Sign out successful');
    } catch (e) {
      AppLogger.error('Sign out failed', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent');
    } catch (e) {
      AppLogger.error('Failed to send password reset email', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('Confirming password reset');
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      AppLogger.info('Password reset confirmed');
    } catch (e) {
      AppLogger.error('Failed to confirm password reset', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      AppLogger.info('Updating user email to: $newEmail');
      await _firebaseAuth.currentUser?.updateEmail(newEmail);
      AppLogger.info('Email updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update email', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      AppLogger.info('Updating user password');
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
      AppLogger.info('Password updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update password', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      AppLogger.info('Updating user profile');
      await _firebaseAuth.currentUser?.updateProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );
      AppLogger.info('User profile updated');
    } catch (e) {
      AppLogger.error('Failed to update user profile', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Get ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      AppLogger.debug('Getting ID token');
      final token = await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
      return token;
    } catch (e) {
      AppLogger.error('Failed to get ID token', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Verify email
  Future<void> sendEmailVerification() async {
    try {
      AppLogger.info('Sending email verification');
      await _firebaseAuth.currentUser?.sendEmailVerification();
      AppLogger.info('Email verification sent');
    } catch (e) {
      AppLogger.error('Failed to send email verification', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Delete user account
  Future<void> deleteUser() async {
    try {
      AppLogger.warning('Deleting user account');
      await _firebaseAuth.currentUser?.delete();
      AppLogger.info('User account deleted');
    } catch (e) {
      AppLogger.error('Failed to delete user account', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    try {
      AppLogger.debug('Reloading user data');
      await _firebaseAuth.currentUser?.reload();
      AppLogger.debug('User data reloaded');
    } catch (e) {
      AppLogger.error('Failed to reload user data', e);
      throw ErrorHandler.handleException(e);
    }
  }

  /// Get user info
  Map<String, dynamic>? getUserInfo() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'metadata': {
        'creationTime': user.metadata.creationTime,
        'lastSignInTime': user.metadata.lastSignInTime,
      },
    };
  }
}
