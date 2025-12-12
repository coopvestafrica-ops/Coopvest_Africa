import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String userId;
  final String type;
  final String? description;
  final String fileName;
  final String fileUrl;
  final String path;
  final int fileSize;
  final String contentType;
  final String status;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final DateTime? updatedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.type,
    this.description,
    required this.fileName,
    required this.fileUrl,
    required this.path,
    required this.fileSize,
    required this.contentType,
    required this.status,
    required this.uploadedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      path: json['path'] as String,
      fileSize: json['fileSize'] as int,
      contentType: json['contentType'] as String,
      status: json['status'] as String,
      uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : (json['verifiedAt'] as Timestamp).toDate(),
      rejectedAt: json['rejectedAt'] == null
          ? null
          : (json['rejectedAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] == null
          ? null
          : (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'description': description,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'path': path,
      'fileSize': fileSize,
      'contentType': contentType,
      'status': status,
      'uploadedAt': uploadedAt,
      'verifiedAt': verifiedAt,
      'rejectedAt': rejectedAt,
      'updatedAt': updatedAt,
    };
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? description,
    String? fileName,
    String? fileUrl,
    String? path,
    int? fileSize,
    String? contentType,
    String? status,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
    DateTime? rejectedAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      path: path ?? this.path,
      fileSize: fileSize ?? this.fileSize,
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DocumentModel &&
      other.id == id &&
      other.userId == userId &&
      other.type == type &&
      other.description == description &&
      other.fileName == fileName &&
      other.fileUrl == fileUrl &&
      other.path == path &&
      other.fileSize == fileSize &&
      other.contentType == contentType &&
      other.status == status &&
      other.uploadedAt == uploadedAt &&
      other.verifiedAt == verifiedAt &&
      other.rejectedAt == rejectedAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      description.hashCode ^
      fileName.hashCode ^
      fileUrl.hashCode ^
      path.hashCode ^
      fileSize.hashCode ^
      contentType.hashCode ^
      status.hashCode ^
      uploadedAt.hashCode ^
      verifiedAt.hashCode ^
      rejectedAt.hashCode ^
      updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, userId: $userId, type: $type, fileName: $fileName, status: $status)';
  }
}
