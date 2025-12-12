import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/transaction.dart';
import '../models/transaction_goal.dart';
import '../models/transaction_validation.dart';
import '../utils/retry_options.dart';
import './transaction_cache_manager.dart';

class TransactionException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  TransactionException(this.message, {this.error, this.stackTrace});

  @override
  String toString() => 'TransactionException: $message${error != null ? ' ($error)' : ''}';
}

class TransactionService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final TransactionCacheManager _cacheManager;

  TransactionService(this._cacheManager);

  // Batch size for Firestore operations
  static const int _batchSize = 500;

  TransactionType _parseTransactionType(String type) {
    final normalizedType = type.toLowerCase().trim();
    return TransactionType.values.firstWhere(
      (t) => t.toString().split('.').last.toLowerCase() == normalizedType,
      orElse: () => TransactionType.other,
    );
  }

  TransactionCategory _parseTransactionCategory(String category) {
    final normalizedCategory = category.toLowerCase().trim();
    return TransactionCategory.values.firstWhere(
      (c) => c.toString().split('.').last.toLowerCase() == normalizedCategory,
      orElse: () => TransactionCategory.other,
    );
  }


  Future<String> recordTransaction({
    required String userId,
    required String type,
    required double amount,
    required String currency,
    required String status,
    String? reference,
    String? description,
    Map<String, dynamic>? metadata,
    String? goalId,
  }) async {
    // Validate transaction data
    final validation = TransactionValidator.validateTransaction(
      userId: userId,
      type: type,
      amount: amount,
      currency: currency,
      status: status,
      reference: reference,
      description: description,
      metadata: metadata,
      goalId: goalId,
    );

    if (!validation.isValid) {
      throw TransactionException(
        'Invalid transaction data: ${validation.errors.join(", ")}',
      );
    }

    final retryOptions = const RetryOptions(maxAttempts: 3);

    return retryOptions.retry(() async {
      try {
        final batch = _firestore.batch();
        final transactionRef = _firestore.collection('transactions').doc();

        final transactionData = {
          'userId': userId,
          'type': type,
          'amount': amount,
          'currency': currency,
          'status': status,
          'reference': reference,
          'description': description,
          'metadata': {
            ...?metadata,
            if (goalId != null) 'goalId': goalId,
          },
          'timestamp': firestore.FieldValue.serverTimestamp(),
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        };

        batch.set(transactionRef, transactionData);

        // If this is a goal-related transaction, update the goal progress
        if (goalId != null && status == 'completed') {
          await _updateGoalProgress(goalId, amount);
        }

        await batch.commit();
        
        // Clear cache since data has changed
        await _cacheManager.clearCache();
        
        return transactionRef.id;
      } on firestore.FirebaseException catch (e) {
        throw TransactionException(
          'Failed to record transaction',
          error: e,
          stackTrace: e.stackTrace,
        );
      } catch (e, st) {
        throw TransactionException(
          'Unexpected error recording transaction',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Stream<firestore.QuerySnapshot> getTransactionStream(
    String userId, {
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    firestore.Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    return query.snapshots();
  }

  Future<Map<String, dynamic>> getTransactionSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final retryOptions = const RetryOptions(maxAttempts: 3);

    return retryOptions.retry(() async {
      try {
        // Try to get from aggregates first
        final aggregates = await _getAggregatesForPeriod(userId, startDate, endDate);
        if (aggregates.isNotEmpty) {
          double totalIncome = 0;
          double totalExpense = 0;
          int transactionCount = 0;

          for (var agg in aggregates) {
            final data = agg.data();
            totalIncome += (data['totalIncome'] as num).toDouble();
            totalExpense += (data['totalExpense'] as num).toDouble();
            transactionCount += data['transactionCount'] as int;
          }

          return {
            'totalIncome': totalIncome,
            'totalExpense': totalExpense,
            'netAmount': totalIncome - totalExpense,
            'transactionCount': transactionCount,
            'fromAggregates': true,
          };
        }

        // If no aggregates, query transactions directly
        var query = _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .where('status', isEqualTo: 'completed');

        double totalIncome = 0;
        double totalExpense = 0;
        int transactionCount = 0;

        var currentBatch = await query.limit(_batchSize).get();
        
        while (currentBatch.docs.isNotEmpty) {
          for (var doc in currentBatch.docs) {
            final data = doc.data();
            final amount = (data['amount'] as num).toDouble();
            
            if (data['type'] == 'credit') {
              totalIncome += amount;
            } else if (data['type'] == 'debit') {
              totalExpense += amount;
            }
            transactionCount++;
          }

          if (currentBatch.docs.length < _batchSize) break;

          final lastDoc = currentBatch.docs.last;
          currentBatch = await query.startAfterDocument(lastDoc).limit(_batchSize).get();
        }

        return {
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'netAmount': totalIncome - totalExpense,
          'transactionCount': transactionCount,
          'fromAggregates': false,
        };
      } on firestore.FirebaseException catch (e) {
        throw TransactionException(
          'Failed to get transaction summary',
          error: e,
          stackTrace: e.stackTrace,
        );
      } catch (e, st) {
        throw TransactionException(
          'Unexpected error getting transaction summary',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<void> aggregateTransactionData(
    String userId,
    DateTime date, {
    bool force = false,
  }) async {
    final retryOptions = const RetryOptions(maxAttempts: 3);

    await retryOptions.retry(() async {
      try {
        // Check if aggregation already exists
        final existingDaily = await _firestore
            .collection('transaction_aggregates')
            .where('userId', isEqualTo: userId)
            .where('period', isEqualTo: 'daily')
            .where('date', isEqualTo: DateTime(date.year, date.month, date.day))
            .limit(1)
            .get();

        if (!force && existingDaily.docs.isNotEmpty) {
          return; // Already aggregated
        }

        // Get transactions for the day
        final startDate = DateTime(date.year, date.month, date.day);
        final endDate = startDate.add(const Duration(days: 1));

        final transactions = await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .where('status', isEqualTo: 'completed')
            .get();

        if (transactions.docs.isEmpty) return;

        // Calculate aggregates
        double totalIncome = 0;
        double totalExpense = 0;
        final categoryTotals = <String, double>{};

        for (var doc in transactions.docs) {
          final data = doc.data();
          final amount = (data['amount'] as num).toDouble();
          final category = data['metadata']?['category'] ?? 'Others';

          if (data['type'] == 'credit') {
            totalIncome += amount;
          } else if (data['type'] == 'debit') {
            totalExpense += amount;
          }

          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        }

        // Create/update daily aggregate
        final dailyRef = _firestore.collection('transaction_aggregates').doc();
        final dailyData = {
          'userId': userId,
          'period': 'daily',
          'date': startDate,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'netAmount': totalIncome - totalExpense,
          'transactionCount': transactions.docs.length,
          'categoryTotals': categoryTotals,
          'createdAt': firestore.FieldValue.serverTimestamp(),
        };

        final batch = _firestore.batch();
        batch.set(dailyRef, dailyData);

        // If it's the first day of the month, create monthly aggregate
        if (date.day == 1 || force) {
          final monthlyRef = _firestore.collection('transaction_aggregates').doc();
          final monthlyData = {
            'userId': userId,
            'period': 'monthly',
            'date': DateTime(date.year, date.month, 1),
            'totalIncome': totalIncome,
            'totalExpense': totalExpense,
            'netAmount': totalIncome - totalExpense,
            'transactionCount': transactions.docs.length,
            'categoryTotals': categoryTotals,
            'createdAt': firestore.FieldValue.serverTimestamp(),
          };
          batch.set(monthlyRef, monthlyData);
        }

        await batch.commit();
      } on firestore.FirebaseException catch (e) {
        throw TransactionException(
          'Failed to aggregate transaction data',
          error: e,
          stackTrace: e.stackTrace,
        );
      } catch (e, st) {
        throw TransactionException(
          'Unexpected error aggregating transaction data',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<List<firestore.QueryDocumentSnapshot<Map<String, dynamic>>>> _getAggregatesForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final aggregates = await _firestore
        .collection('transaction_aggregates')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateTime(startDate.year, startDate.month, startDate.day))
        .where('date', isLessThanOrEqualTo: DateTime(endDate.year, endDate.month, endDate.day))
        .orderBy('date')
        .get();

    return aggregates.docs;
  }

  Future<void> updateTransactionStatus(
    String transactionId,
    String status, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': status,
        'updatedAt': firestore.FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'completed')
          .get();

      final Map<String, double> categoryTotals = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final category = data['metadata']?['category'] ?? 'Others';

        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      return categoryTotals.entries
          .map((e) => {
                'category': e.key,
                'amount': e.value,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get category analytics: $e');
    }
  }

  Future<List<Transaction>> getAllTransactions({bool useCache = true}) async {
    if (useCache) {
      final cachedTransactions = await _cacheManager.getCachedTransactions();
      if (cachedTransactions != null) {
        return cachedTransactions;
      }
    }

    final retryOptions = const RetryOptions(maxAttempts: 3);
    
    return retryOptions.retry(() async {
      try {
        final List<Transaction> allTransactions = [];
        var query = _firestore
            .collection('transactions')
            .where('status', isEqualTo: 'completed')
            .orderBy('timestamp', descending: true);

        // Get the first batch
        var currentBatch = await query.limit(_batchSize).get();
        
        while (currentBatch.docs.isNotEmpty) {
          final transactions = currentBatch.docs.map((doc) {
            final data = doc.data();
            return Transaction(
              id: doc.id,
              userId: data['userId'],
              amount: (data['amount'] as num).toDouble(),
              date: (data['timestamp'] as firestore.Timestamp).toDate(),
              description: data['description'] ?? '',
              type: _parseTransactionType(data['type'].toString()),
              category: _parseTransactionCategory(data['metadata']?['category']?.toString() ?? ''),
              reference: data['reference'],
            );
          }).toList();

          allTransactions.addAll(transactions);

          // If we got less than the batch size, we're done
          if (currentBatch.docs.length < _batchSize) break;

          // Get the next batch starting after the last document
          final lastDoc = currentBatch.docs.last;
          currentBatch = await query.startAfterDocument(lastDoc).limit(_batchSize).get();
        }

        // Cache the results
        await _cacheManager.cacheTransactions(allTransactions);
        
        return allTransactions;
      } on firestore.FirebaseException catch (e) {
        throw TransactionException(
          'Failed to get transactions',
          error: e,
          stackTrace: e.stackTrace,
        );
      } catch (e, st) {
        throw TransactionException(
          'Unexpected error getting transactions',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<List<Transaction>> getTransactionsForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'completed')
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Transaction(
          id: doc.id,
          userId: data['userId'],
          amount: (data['amount'] as num).toDouble(),
          date: (data['timestamp'] as firestore.Timestamp).toDate(),
          description: data['description'] ?? '',
          type: _parseTransactionType(data['type'].toString()),
          category: _parseTransactionCategory(data['metadata']?['category']?.toString() ?? ''),
          reference: data['reference'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<List<TransactionGoal>> getTransactionGoals(
    String userId, {
    bool useCache = true,
    bool includeCompleted = true,
  }) async {
    if (useCache) {
      final cachedGoals = await _cacheManager.getCachedGoals();
      if (cachedGoals != null) {
        return cachedGoals.where((goal) => 
          goal.userId == userId && 
          (includeCompleted || !goal.isCompleted)
        ).toList();
      }
    }

    final retryOptions = const RetryOptions(maxAttempts: 3);
    
    return retryOptions.retry(() async {
      try {
        var query = _firestore
            .collection('transaction_goals')
            .where('userId', isEqualTo: userId);
            
        if (!includeCompleted) {
          query = query.where('isCompleted', isEqualTo: false);
        }
        
        query = query.orderBy('endDate');

        final List<TransactionGoal> allGoals = [];
        var currentBatch = await query.limit(_batchSize).get();
        
        while (currentBatch.docs.isNotEmpty) {
          final goals = currentBatch.docs.map((doc) {
            final data = doc.data();
            return TransactionGoal(
              id: doc.id,
              userId: data['userId'],
              title: data['title'],
              targetAmount: (data['targetAmount'] as num).toDouble(),
              currentAmount: (data['currentAmount'] as num).toDouble(),
              startDate: (data['startDate'] as firestore.Timestamp).toDate(),
              endDate: (data['endDate'] as firestore.Timestamp).toDate(),
              category: data['category'],
              description: data['description'],
              isCompleted: data['isCompleted'] ?? false,
            );
          }).toList();

          allGoals.addAll(goals);

          if (currentBatch.docs.length < _batchSize) break;

          final lastDoc = currentBatch.docs.last;
          currentBatch = await query.startAfterDocument(lastDoc).limit(_batchSize).get();
        }

        // Cache all goals
        await _cacheManager.cacheTransactionGoals(allGoals);
        
        return allGoals;
      } on firestore.FirebaseException catch (e) {
        throw TransactionException(
          'Failed to get transaction goals',
          error: e,
          stackTrace: e.stackTrace,
        );
      } catch (e, st) {
        throw TransactionException(
          'Unexpected error getting transaction goals',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  Future<String> createTransactionGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
    required String category,
    String? description,
  }) async {
    try {
      final doc = await _firestore.collection('transaction_goals').add({
        'userId': userId,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': 0.0,
        'startDate': startDate,
        'endDate': endDate,
        'category': category,
        'description': description,
        'isCompleted': false,
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      throw Exception('Failed to create transaction goal: $e');
    }
  }

  Future<void> updateTransactionGoal({
    required String goalId,
    String? title,
    double? targetAmount,
    DateTime? endDate,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': firestore.FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (targetAmount != null) updates['targetAmount'] = targetAmount;
      if (endDate != null) updates['endDate'] = endDate;
      if (description != null) updates['description'] = description;

      await _firestore.collection('transaction_goals').doc(goalId).update(updates);
    } catch (e) {
      throw Exception('Failed to update transaction goal: $e');
    }
  }

  Future<TransactionGoal?> getTransactionGoal(String goalId) async {
    try {
      final doc = await _firestore.collection('transaction_goals').doc(goalId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return TransactionGoal(
        id: doc.id,
        userId: data['userId'],
        title: data['title'],
        targetAmount: (data['targetAmount'] as num).toDouble(),
        currentAmount: (data['currentAmount'] as num).toDouble(),
        startDate: (data['startDate'] as firestore.Timestamp).toDate(),
        endDate: (data['endDate'] as firestore.Timestamp).toDate(),
        category: data['category'],
        description: data['description'],
        isCompleted: data['isCompleted'] ?? false,
      );
    } catch (e) {
      throw Exception('Failed to get transaction goal: $e');
    }
  }

  Future<void> _updateGoalProgress(String goalId, double amount) async {
    try {
      final goalRef = _firestore.collection('transaction_goals').doc(goalId);
      
      await _firestore.runTransaction((transaction) async {
        final goalDoc = await transaction.get(goalRef);
        if (!goalDoc.exists) {
          throw Exception('Goal not found');
        }

        final currentAmount = (goalDoc.data()?['currentAmount'] as num?)?.toDouble() ?? 0.0;
        final targetAmount = (goalDoc.data()?['targetAmount'] as num).toDouble();
        final newAmount = currentAmount + amount;
        final isCompleted = newAmount >= targetAmount;

        transaction.update(goalRef, {
          'currentAmount': newAmount,
          'isCompleted': isCompleted,
          'updatedAt': firestore.FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to update goal progress: $e');
    }
  }

  Future<Map<String, dynamic>> getGoalProgress(String goalId) async {
    try {
      final goal = await getTransactionGoal(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final transactions = await _firestore
          .collection('transactions')
          .where('metadata.goalId', isEqualTo: goalId)
          .where('status', isEqualTo: 'completed')
          .orderBy('timestamp')
          .get();

      final List<Map<String, dynamic>> contributionHistory = transactions.docs.map((doc) {
        final data = doc.data();
        return {
          'amount': (data['amount'] as num).toDouble(),
          'date': (data['timestamp'] as firestore.Timestamp).toDate(),
          'type': data['type'],
        };
      }).toList();

      final daysLeft = goal.endDate.difference(DateTime.now()).inDays;
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
      final dailyTargetAmount = daysLeft > 0 
          ? (goal.targetAmount - goal.currentAmount) / daysLeft 
          : 0.0;

      return {
        'currentAmount': goal.currentAmount,
        'targetAmount': goal.targetAmount,
        'progressPercentage': progressPercentage,
        'daysLeft': daysLeft,
        'dailyTargetAmount': dailyTargetAmount,
        'isCompleted': goal.isCompleted,
        'contributionHistory': contributionHistory,
      };
    } catch (e) {
        throw Exception('Failed to get goal progress: $e');
      }
    }
  }
