import 'dart:convert';

class PresignedUrlInfo {
  final String signedUrl;
  final String storagePath;
  final String originalName;
 
  const PresignedUrlInfo({
    required this.signedUrl,
    required this.storagePath,
    required this.originalName,
  });
 
  factory PresignedUrlInfo.fromJson(Map<String, dynamic> json) => PresignedUrlInfo(
        signedUrl:    json['signed_url'] ?? '',
        storagePath:  json['storage_path'] ?? '',
        originalName: json['original_name'] ?? '',
      );
}
 
class PresignedUrlsResponse {
  final List<PresignedUrlInfo> urls;
  const PresignedUrlsResponse({required this.urls});
 
  factory PresignedUrlsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['urls'] as List<dynamic>? ?? []);
    return PresignedUrlsResponse(
      urls: list.map((e) => PresignedUrlInfo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
 
class JobStatus {
  final String jobId;
  final String status;
 
  const JobStatus({required this.jobId, required this.status});
 
  factory JobStatus.fromJson(Map<String, dynamic> json) => JobStatus(
        jobId:  json['job_id'] ?? '',
        status: json['status'] ?? 'unknown',
      );
}


class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;
 
  const ApiException(this.message, this.statusCode, this.responseBody);
 
  @override
  String toString() => message;
 
  String get userMessage {
    try {
      final body = jsonDecode(responseBody);
      return body['detail'] ?? message;
    } catch (_) {
      return message;
    }
  }
}
 