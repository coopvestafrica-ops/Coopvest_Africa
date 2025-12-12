import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../models/document_model.dart';

class DocumentService {
  static const int maxFileSize = 20 * 1024 * 1024; // 20MB
  static const List<String> validStatuses = ['pending', 'verified', 'rejected'];
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadDocument({
    required File file,
    required String userId,
    required String documentType,
    String? description,
    void Function(double)? onProgress,
  }) async {
    String? storagePath;
    try {
      // Validate file
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) { // 20MB limit
        throw Exception('File size exceeds 20MB limit');
      }

      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      storagePath = 'documents/$userId/${documentType}_${timestamp}_$fileName';
      
      // Upload file to Firebase Storage with progress tracking
      final storageRef = _storage.ref(storagePath);
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'userId': userId,
            'documentType': documentType,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      await uploadTask.whenComplete(() => null);
      
      // Check if upload was successful
      final snapshot = await uploadTask;
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed: ${snapshot.state}');
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save document metadata to Firestore
      final docRef = await _firestore.collection('documents').add({
        'userId': userId,
        'type': documentType,
        'description': description,
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'fileSize': fileSize,
        'contentType': _getContentType(fileName),
        'path': storagePath,
      });

      // Update storage reference with document ID
      await storageRef.updateMetadata(
        SettableMetadata(
          customMetadata: {'documentId': docRef.id},
        ),
      );

      return downloadUrl;
    } catch (e) {
      // Clean up if upload fails
      try {
        if (storagePath != null) {
          final ref = _storage.ref(storagePath);
          await ref.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      throw Exception('Failed to upload document: $e');
    }
  }

  String _getContentType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<DocumentModel>> getUserDocuments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user documents: $e');
    }
  }

  Stream<List<DocumentModel>> streamUserDocuments(String userId) {
    return _firestore
        .collection('documents')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final doc = await _firestore.collection('documents').doc(documentId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return DocumentModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      // Get the document reference
      final docRef = _firestore.collection('documents').doc(documentId);
      
      // Get the document data
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Document not found');
      }
      
      // Delete the file from storage
      final storagePath = doc.data()!['path'] as String;
      await _storage.ref(storagePath).delete();

      // Delete the document metadata from Firestore
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<void> updateDocumentStatus(String documentId, String status) async {
    try {
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status: $status');
      }

      await _firestore.collection('documents').doc(documentId).update({
        'status': status,
        'verifiedAt': status == 'verified' ? FieldValue.serverTimestamp() : null,
        'rejectedAt': status == 'rejected' ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update document status: $e');
    }
  }

  Future<bool> checkDocumentExists(String userId, String documentType) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: documentType)
          .where('status', whereIn: ['pending', 'verified'])
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check document existence: $e');
    }
  }

  Future<Map<String, DocumentModel?>> getUserDocumentsByType(
    String userId,
    List<String> documentTypes,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: documentTypes)
          .where('status', whereIn: ['pending', 'verified'])
          .get();

      final documents = snapshot.docs
          .map((doc) => DocumentModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Map.fromEntries(
        documentTypes.map(
          (type) => MapEntry(
            type,
            documents.where((doc) => doc.type == type).isNotEmpty
                ? documents.firstWhere((doc) => doc.type == type)
                : null,
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch user documents by type: $e');
    }
  }
}
