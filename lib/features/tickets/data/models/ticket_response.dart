import 'package:cloud_firestore/cloud_firestore.dart';

class TicketResponse {
  final String id;
  final String ticketId;
  final String userId;
  final String message;
  final bool isStaff;
  final DateTime createdAt;
  final List<String>? attachments;

  TicketResponse({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.isStaff,
    required this.createdAt,
    this.attachments,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      userId: json['userId'] as String,
      message: json['message'] as String,
      isStaff: json['isStaff'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      attachments:
          (json['attachments'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'message': message,
      'isStaff': isStaff,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
    };
  }

  TicketResponse copyWith({
    String? id,
    String? ticketId,
    String? userId,
    String? message,
    bool? isStaff,
    DateTime? createdAt,
    List<String>? attachments,
  }) {
    return TicketResponse(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      isStaff: isStaff ?? this.isStaff,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }
}
