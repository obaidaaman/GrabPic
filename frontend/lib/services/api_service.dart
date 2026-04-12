// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/constants.dart';

class ApiService {
  final String _base;
  ApiService({String? baseUrl}) : _base = baseUrl ?? AppConstants.baseUri;

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// POST /auth/face-auth — sends raw image bytes as multipart file
  Future<AuthResponse> faceAuthenticate(Uint8List bytes, String fileName) async {
    final uri    = Uri.parse('$_base${AppConstants.authFaceAuth}');
    final req    = http.MultipartRequest('POST', uri);
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: http.MediaType('image', 'jpeg'),
      ),
    );
    final streamed = await req.send();
    final res      = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException('Face authentication failed', res.statusCode, res.body);
  }

  // ─── Spaces ────────────────────────────────────────────────────────────────

  /// POST /users/create-space
  Future<Space> createSpace({
    required String spaceName,
    required String spacePassword,
    required String userId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base${AppConstants.usersCreateSpace}'),
      headers: _headers(token: token),
      body: jsonEncode({
        'space_name':     spaceName,
        'space_password': spacePassword,
        'created_by':     userId,
      }),
    );
    if (res.statusCode == 201) {
      return Space.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException('Failed to create space', res.statusCode, res.body);
  }

  /// GET /users/get-spaces
  Future<List<Space>> getSpaces(String token) async {
    final res = await http.get(
      Uri.parse('$_base${AppConstants.usersGetSpaces}'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Space.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Failed to fetch spaces', res.statusCode, res.body);
  }

  /// POST /users/join-space
  Future<Space> joinSpace({
    required String spaceName,
    required String spacePassword,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base${AppConstants.usersJoinSpace}'),
      headers: _headers(token: token),
      body: jsonEncode({
        'space_name':     spaceName,
        'space_password': spacePassword,
        'created_by':     '',
      }),
    );
    if (res.statusCode == 200) {
      return Space.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException('Failed to join space', res.statusCode, res.body);
  }

  // ─── Images ────────────────────────────────────────────────────────────────

  /// GET /users/get-images?space_id=X
  Future<List<UserImage>> getImages({
    required String spaceId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_base${AppConstants.usersGetImages}?space_id=$spaceId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => UserImage.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('Failed to fetch images', res.statusCode, res.body);
  }

  // ─── File Upload ───────────────────────────────────────────────────────────

  /// POST /files/url — get pre-signed upload URLs
  Future<PresignedUrlsResponse> getPresignedUrls({
    required List<String> fileNames,
    required String spaceId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base${AppConstants.filesUrl}'),
      headers: _headers(token: token),
      body: jsonEncode({'fileName': fileNames, 'space_id': spaceId}),
    );
    if (res.statusCode == 200) {
      return PresignedUrlsResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('Failed to get upload URLs', res.statusCode, res.body);
  }

  /// PUT to GCS — upload raw bytes to the presigned URL
  Future<void> uploadToSignedUrl({
    required String signedUrl,
    required Uint8List bytes,
  }) async {
    final res = await http.put(
      Uri.parse(signedUrl),
      headers: {'Content-Type': 'image/jpeg'},
      body: bytes,
    );
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
      throw ApiException('Upload to storage failed', res.statusCode, res.body);
    }
  }

  /// POST /files/upload — trigger face embedding job
  Future<void> triggerEmbedding({
    required List<String> storagePaths,
    required String spaceId,
    required String token,
    String email = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_base${AppConstants.filesUpload}'),
      headers: _headers(token: token),
      body: jsonEncode({
        'storagePaths': storagePaths,
        'space_id':     spaceId,
        'email':        email,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException('Failed to trigger embedding', res.statusCode, res.body);
    }
  }

  /// GET /files/status?job_id=X
  Future<JobStatus> getJobStatus({
    required String jobId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_base${AppConstants.filesStatus}?job_id=$jobId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 200) {
      return JobStatus.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException('Failed to get job status', res.statusCode, res.body);
  }
}