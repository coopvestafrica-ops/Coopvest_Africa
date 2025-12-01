class TransactionGoal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final String? description;
  final bool isCompleted;

  TransactionGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.description,
    this.isCompleted = false,
  });

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  double get progressPercentage => progress * 100;

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(endDate);
  bool get isStarted => currentAmount > 0;
  bool get isAchievable => !isOverdue || isCompleted;

  int get daysLeft => endDate.difference(DateTime.now()).inDays;
  double get dailyTargetAmount => daysLeft > 0 
      ? (targetAmount - currentAmount) / daysLeft 
      : 0.0;

  bool get needsAttention => isStarted && !isCompleted && 
      (progress < 0.5 || daysLeft < 7);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'description': description,
      'isCompleted': isCompleted,
      'progress': progress,
      'progressPercentage': progressPercentage,
      'isOverdue': isOverdue,
      'isStarted': isStarted,
      'isAchievable': isAchievable,
      'daysLeft': daysLeft,
      'dailyTargetAmount': dailyTargetAmount,
      'needsAttention': needsAttention,
    };
  }

  factory TransactionGoal.fromMap(Map<String, dynamic> map) {
    return TransactionGoal(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      targetAmount: map['targetAmount'].toDouble(),
      currentAmount: map['currentAmount'].toDouble(),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      category: map['category'],
      description: map['description'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  TransactionGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? description,
    bool? isCompleted,
  }) {
    return TransactionGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
