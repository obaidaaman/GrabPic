class UserImage {
  final String id;
  final String fileName;
  final String url;
  final DateTime? uploadedAt;
 
  const UserImage({
    required this.id,
    required this.fileName,
    required this.url,
    this.uploadedAt,
  });
 
  factory UserImage.fromJson(Map<String, dynamic> json) => UserImage(
        id:         json['id'] ?? '',
        fileName:   json['file_name'] ?? '',
        url:        json['url'] ?? '',
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at'].toString())
            : null,
      );
}