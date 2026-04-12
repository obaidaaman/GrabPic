class AuthResponse {
  final String id;
  final String? token;
  final String message;
  final bool isNewUser;
  final String? username;
  final String? email;
  final bool? isProfileComplete;
 
  const AuthResponse({
    required this.id,
    this.token,
    required this.message,
    this.isNewUser = false,
    this.username,
    this.email,
    this.isProfileComplete,
  });
 
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        id:                json['id'] ?? '',
        token:             json['token'],
        message:           json['message'] ?? '',
        isNewUser:         json['is_new_user'] ?? false,
        username:          json['username'],
        email:             json['email'],
        isProfileComplete: json['is_profile_complete'],
      );
}