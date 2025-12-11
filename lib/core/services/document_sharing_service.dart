import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

/// Custom exception for document sharing errors
class DocumentSharingException implements Exception {
  final String message;
  final String operation;
  final dynamic cause;

  DocumentSharingException(this.message, this.operation, {this.cause});

  @override
  String toString() => 'DocumentSharingException: [$operation] $message';
}

typedef ProgressCallback = void Function(int received, int total);

/// Service for sharing and downloading documents
class DocumentSharingService {
  final _logger = Logger('DocumentSharingService');
  final _client = http.Client();
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);
  
  static DocumentSharingService? _instance;
  
  DocumentSharingService._();
  
  static DocumentSharingService get instance {
    _instance ??= DocumentSharingService._();
    return _instance!;
  }
  
  /// List of supported file extensions
  static const supportedExtensions = [
    '.pdf', '.jpg', '.jpeg', '.png', '.doc', 
    '.docx', '.xls', '.xlsx', '.txt'
  ];

  /// Shares a document from a URL with progress tracking
  Future<void> shareDocument({
    required String documentUrl,
    required String documentName,
    ProgressCallback? onProgress,
  }) async {
    if (!Uri.parse(documentUrl).isAbsolute) {
      throw ArgumentError('Invalid document URL');
    }

    if (!isFileTypeSupported(documentName)) {
      throw ArgumentError('Unsupported file type');
    }

    File? tempFile;
    try {
      _logger.info('Downloading document for sharing: $documentName');
      
      // Download the document with retry logic and progress tracking
      final bytes = await _downloadWithRetry(
        documentUrl,
        onProgress: onProgress,
      );

      // Get temporary directory to store the file
      final tempDir = await getTemporaryDirectory();
      tempFile = File(path.join(tempDir.path, documentName));
      
      // Write the file
      await tempFile.writeAsBytes(bytes);

      _logger.info('Sharing document: $documentName');
      
      // Share the file
      await SharePlus.instance.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Sharing $documentName',
      );

    } catch (e, stack) {
      _logger.severe('Error sharing document: $documentName', e, stack);
      rethrow;
    } finally {
      // Clean up the temporary file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          _logger.warning('Failed to delete temporary file: ${tempFile.path}', e);
        }
      }
    }
  }

  /// Downloads a document to the device
  Future<String> downloadDocument({
    required String documentUrl,
    required String documentName,
    ProgressCallback? onProgress,
  }) async {
    if (!Uri.parse(documentUrl).isAbsolute) {
      throw ArgumentError('Invalid document URL');
    }

    if (!isFileTypeSupported(documentName)) {
      throw ArgumentError('Unsupported file type');
    }

    try {
      _logger.info('Starting download: $documentName');
      
      // Get the downloads directory
      final downloadsDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();

      // Create a unique filename
      final String filePath = await _createUniqueFilePath(
        downloadsDir.path, 
        documentName
      );

      // Download and save the file
      final response = await http.get(Uri.parse(documentUrl))
          .timeout(const Duration(minutes: 5));
          
      if (response.statusCode != 200) {
        throw Exception('Failed to download document: ${response.statusCode}');
      }

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _logger.info('Download completed: $filePath');
      return filePath;
    } catch (e, stack) {
      _logger.severe('Error downloading document: $documentName', e, stack);
      rethrow;
    }
  }

  /// Downloads a file with retry logic and progress tracking
  Future<List<int>> _downloadWithRetry(
    String url, {
    ProgressCallback? onProgress,
    int retryCount = 0,
  }) async {
    try {
      final response = await _client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to download: Status ${response.statusCode}'
        );
      }

      final contentLength = response.contentLength ?? -1;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, contentLength);
      }

      return bytes;
    } catch (e) {
      if (retryCount < _maxRetries) {
        _logger.warning(
          'Download attempt ${retryCount + 1} failed, retrying...',
          e,
        );
        await Future.delayed(_retryDelay);
        return _downloadWithRetry(
          url,
          onProgress: onProgress,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  /// Creates a unique file path
  Future<String> _createUniqueFilePath(
    String directory, 
    String fileName
  ) async {
    String filePath = path.join(directory, fileName);
    int counter = 1;

    while (await File(filePath).exists()) {
      final extension = path.extension(fileName);
      final nameWithoutExtension = path.basenameWithoutExtension(fileName);
      final newFileName = '$nameWithoutExtension ($counter)$extension';
      filePath = path.join(directory, newFileName);
      counter++;
    }

    return filePath;
  }

  /// Gets the filename from a URL
  String getFileNameFromUrl(String url) {
    if (!Uri.parse(url).isAbsolute) {
      throw ArgumentError('Invalid URL');
    }

    final uri = Uri.parse(url);
    final fileName = path.basename(uri.path);
    return fileName.isNotEmpty ? fileName : 'document${path.extension(uri.path)}';
  }

  /// Checks if the file type is supported
  bool isFileTypeSupported(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return [
      '.pdf',
      '.jpg',
      '.jpeg',
      '.png',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.txt',
    ].contains(extension);
  }

  /// Disposes of the http client and cleans up resources
  void dispose() {
    _client.close();
    _instance = null;
  }
}
