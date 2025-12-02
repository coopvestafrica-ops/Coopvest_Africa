import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';

import '../exceptions/repository_exception.dart';

/// Repository class for managing user data in Firestore
class UserRepository {
  final FirebaseService _firebase = FirebaseService.instance;
  final Logger _logger = Logger('UserRepository');

  /// Creates a new user in Firestore
  /// 
  /// Throws [RepositoryException] if creation fails
  Future<void> createUser(User user) async {
    try {
      _logger.info('Creating new user with ID: ${user.id}');
      
      if (!_isValidUser(user)) {
        throw RepositoryException(
          'Invalid user data: Required fields missing',
          'createUser'
        );
      }

      await _firebase.users.doc(user.id).set(
        user.toJson(),
        SetOptions(merge: true),
      );
      
      _logger.info('Successfully created user: ${user.id}');
    } catch (e, stack) {
      _logger.severe('Failed to create user', e, stack);
      throw RepositoryException(
        'Failed to create user: $e',
        'createUser',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Retrieves a user by their ID
  /// 
  /// Returns null if user doesn't exist
  /// Throws [RepositoryException] if retrieval fails
  Future<User?> getUserById(String userId) async {
    try {
      _logger.info('Fetching user with ID: $userId');
      
      final doc = await _firebase.users.doc(userId).get();
      
      if (!doc.exists) {
        _logger.info('No user found with ID: $userId');
        return null;
      }

      return User.fromJson(doc.data()!);
    } catch (e, stack) {
      _logger.severe('Failed to get user: $userId', e, stack);
      throw RepositoryException(
        'Failed to get user: $e',
        'getUserById',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Updates user data
  /// 
  /// Only updates the fields provided in updates
  /// Throws [RepositoryException] if update fails
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      _logger.info('Updating user: $userId');
      
      // Validate update fields
      final validFields = [
        'email', 'username', 'firstName', 'lastName', 'phoneNumber',
        'avatarUrl', 'role', 'permissions', 'meta', 'isEmailVerified',
        'isPhoneVerified'
      ];
      
      if (!updates.keys.every((key) => validFields.contains(key))) {
        throw RepositoryException(
          'Invalid update data: Contains invalid fields',
          'updateUser'
        );
      }

      await _firebase.users.doc(userId).update(updates);
      _logger.info('Successfully updated user: $userId');
    } catch (e, stack) {
      _logger.severe('Failed to update user: $userId', e, stack);
      throw RepositoryException(
        'Failed to update user: $e',
        'updateUser',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Deletes a user and all associated data
  /// 
  /// Throws [RepositoryException] if deletion fails
  Future<void> deleteUser(String userId) async {
    try {
      _logger.info('Deleting user: $userId');

      // Start a batch operation
      final batch = _firebase.firestore.batch();
      
      // Delete user document
      batch.delete(_firebase.users.doc(userId));
      
      // Delete associated data (customize based on your data model)
      // Example: Delete user's notifications
      final notificationsQuery = _firebase.notifications.where('userId', isEqualTo: userId);
      final notificationsSnapshot = await notificationsQuery.get();
      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
      _logger.info('Successfully deleted user and associated data: $userId');
    } catch (e, stack) {
      _logger.severe('Failed to delete user: $userId', e, stack);
      throw RepositoryException(
        'Failed to delete user: $e',
        'deleteUser',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Get all users with pagination support
  /// 
  /// [limit] - Maximum number of users to fetch per page
  /// [startAfter] - Last document from previous page for pagination
  Stream<List<User>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    try {
      var query = _firebase.users
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => User.fromJson(doc.data()))
            .toList();
      });
    } catch (e, stack) {
      _logger.severe('Failed to get users stream', e, stack);
      throw RepositoryException(
        'Failed to get users stream: $e',
        'getAllUsers',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Query users by field value
  /// 
  /// [field] - Field to query on
  /// [value] - Value to match
  /// [limit] - Maximum number of results to return
  Future<List<User>> queryUsers({
    required String field,
    required dynamic value,
    int limit = 20,
  }) async {
    try {
      _logger.info('Querying users where $field equals $value');

      final querySnapshot = await _firebase.users
          .where(field, isEqualTo: value)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .toList();
    } catch (e, stack) {
      _logger.severe('Failed to query users', e, stack);
      throw RepositoryException(
        'Failed to query users: $e',
        'queryUsers',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Batch create multiple users
  /// 
  /// Throws [RepositoryException] if batch creation fails
  Future<void> batchCreateUsers(List<User> users) async {
    try {
      _logger.info('Batch creating ${users.length} users');

      final batch = _firebase.firestore.batch();
      
      for (var user in users) {
        if (!_isValidUser(user)) {
          throw RepositoryException(
            'Invalid user data in batch: ${user.id}',
            'batchCreateUsers'
          );
        }
        batch.set(
          _firebase.users.doc(user.id),
          user.toJson(),
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      _logger.info('Successfully created ${users.length} users');
    } catch (e, stack) {
      _logger.severe('Failed to batch create users', e, stack);
      throw RepositoryException(
        'Failed to batch create users: $e',
        'batchCreateUsers',
        innerException: e,
        stackTrace: stack,
      );
    }
  }

  /// Validates user data before creation/update
  bool _isValidUser(User user) {
    return user.id.isNotEmpty &&
           user.email.isNotEmpty &&
           user.username.isNotEmpty &&
           user.firstName.isNotEmpty &&
           user.lastName.isNotEmpty;
  }
}
