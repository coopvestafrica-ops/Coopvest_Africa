import 'package:cloud_firestore/cloud_firestore.dart';
import 'ticket_response.dart';

enum TicketStatus { open, inProgress, resolved, closed, cancelled }

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

enum TicketCategory { general, technical, financial, account, security, other }

class TicketModel {
  final String id;
  final String userId;
  final String userEmail;
  final String subject;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? assignedTo;
  final List<String>? attachments;
  final List<TicketResponse> responses;
  final Map<String, dynamic>? metadata;

  TicketModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.category = TicketCategory.general,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.assignedTo,
    this.attachments,
    this.responses = const [],
    this.metadata,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: TicketStatus.values.firstWhere(
        (e) => e.toString() == 'TicketStatus.${json['status']}',
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.toString() == 'TicketPriority.${json['priority']}',
        orElse: () => TicketPriority.medium,
      ),
      category: TicketCategory.values.firstWhere(
        (e) => e.toString() == 'TicketCategory.${json['category']}',
        orElse: () => TicketCategory.general,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as Timestamp).toDate()
          : null,
      closedAt: json['closedAt'] != null
          ? (json['closedAt'] as Timestamp).toDate()
          : null,
      assignedTo: json['assignedTo'] as String?,
      attachments: (json['attachments'] as List?)?.cast<String>(),
      responses: (json['responses'] as List?)
              ?.map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'subject': subject,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'assignedTo': assignedTo,
      'attachments': attachments,
      'responses': responses.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }

  TicketModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? subject,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    String? assignedTo,
    List<String>? attachments,
    List<TicketResponse>? responses,
    Map<String, dynamic>? metadata,
  }) {
    return TicketModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      attachments: attachments ?? this.attachments,
      responses: responses ?? this.responses,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;
  bool get isClosed => status == TicketStatus.closed;
  bool get isCancelled => status == TicketStatus.cancelled;
  bool get isActive => !isClosed && !isCancelled;

  Duration? get timeSinceCreation => DateTime.now().difference(createdAt);
  Duration? get timeToResolution => resolvedAt?.difference(createdAt);
  Duration? get timeToClosure => closedAt?.difference(createdAt);

  int get responseCount => responses.length;
  DateTime get lastActivityTime => updatedAt ?? createdAt;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  bool get isAssigned => assignedTo != null;

  // Returns the last response in the ticket
  TicketResponse? get lastResponse =>
      responses.isNotEmpty ? responses.last : null;

  // Checks if the ticket has been updated since the user's last view
  bool hasUpdatedSince(DateTime lastViewTime) {
    return lastActivityTime.isAfter(lastViewTime);
  }

  // Checks if the ticket requires attention (no response for X days)
  bool requiresAttention(Duration threshold) {
    if (isClosed || isCancelled) return false;
    final lastActivity = lastActivityTime;
    return DateTime.now().difference(lastActivity) > threshold;
  }
}
