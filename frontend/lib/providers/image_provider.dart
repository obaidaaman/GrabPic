import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class ImageProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  ImageProvider({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  List<UserImage> _images = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  String? _uploadStatus;
  double _uploadProgress = 0.0;

  List<UserImage> get images => _images;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  String? get uploadStatus => _uploadStatus;
  double get uploadProgress => _uploadProgress;

  Future<void> loadImages(String spaceId) async {
    final token = _storageService.getJwtToken();
    if (token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _images = await _apiService.getImages(spaceId: spaceId, token: token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadImages({
    required List<FileWithBytes> files,
    required String spaceId,
    Function(String)? onProgress,
  }) async {
    final token = _storageService.getJwtToken();
    if (token == null) throw Exception('User not authenticated');

    _isUploading = true;
    _uploadProgress = 0.0;
    _error = null;
    _uploadStatus = 'Getting upload URLs...';
    notifyListeners();

    try {
      // Step 1: Get presigned URLs
      final fileNames = files.map((f) => f.fileName).toList();
      final urlsResponse = await _apiService.getPresignedUrls(
        fileNames: fileNames,
        spaceId: spaceId,
        token: token,
      );

      // Step 2: Upload files to presigned URLs
      _uploadStatus = 'Uploading ${files.length} images...';
      final storagePaths = <String>[];

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final urlInfo = urlsResponse.urls[i];

        onProgress?.call('Uploading ${file.fileName}...');

        // Upload to presigned URL
        final uploadResponse = await http.put(
          Uri.parse(urlInfo.signedUrl),
          body: file.bytes,
          headers: {'Content-Type': 'image/jpeg'},
        );

        if (uploadResponse.statusCode == 200 ||
            uploadResponse.statusCode == 201) {
          storagePaths.add(urlInfo.storagePath);
        } else {
          throw Exception('Failed to upload ${file.fileName}');
        }

        _uploadProgress = (i + 1) / files.length;
        notifyListeners();
      }

      // Step 3: Trigger background processing
      _uploadStatus = 'Starting background processing...';
      await _apiService.triggerEmbedding(
        storagePaths: storagePaths,
        spaceId: spaceId,
        token: token,
      );

      _uploadStatus = 'Processing started! Images will be available soon.';
      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isUploading = false;
      _uploadStatus = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<JobStatus> checkJobStatus(String jobId) async {
    final token = _storageService.getJwtToken();
    if (token == null) throw Exception('User not authenticated');

    return await _apiService.getJobStatus(jobId: jobId, token: token);
  }

  void clear() {
    _images = [];
    _error = null;
    _uploadStatus = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class FileWithBytes {
  final String fileName;
  final Uint8List bytes;

  FileWithBytes({
    required this.fileName,
    required this.bytes,
  });
}
