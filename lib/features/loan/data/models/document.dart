class Document {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;
  final String? status;
  final String? verificationStatus;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
    this.status,
    this.verificationStatus,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      url: map['url'] as String,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      status: map['status'] as String?,
      verificationStatus: map['verificationStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status,
      'verificationStatus': verificationStatus,
    };
  }
}
