

class AppConstants {

  static const String baseUri = 'http://127.0.0.1:8000';

  // Auth
  static const String authFaceAuth     = '/auth/face';

  // Spaces
  static const String usersCreateSpace = '/users/spaces';
  static const String usersGetSpaces   = '/users/spaces/';
  static const String usersJoinSpace   = '/users/spaces/join';
  static const String usersGetImages   = '/users/spaces/images';

  // Files
  static const String filesUrl         = '/files/url';
  static const String filesUpload      = '/files/upload';
  static const String filesStatus      = '/files/status';

  // Storage keys
  static const String jwtTokenKey      = 'jwt_token';
  static const String userIdKey        = 'user_id';
}