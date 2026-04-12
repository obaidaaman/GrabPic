// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  Future<void> saveJwtToken(String token) async =>
      _prefs?.setString(AppConstants.jwtTokenKey, token);
  String? getJwtToken() => _prefs?.getString(AppConstants.jwtTokenKey);

  // User ID
  Future<void> saveUserId(String id) async =>
      _prefs?.setString(AppConstants.userIdKey, id);
  String? getUserId() => _prefs?.getString(AppConstants.userIdKey);

  // Clear all
  Future<void> clearAuth() async {
    await _prefs?.remove(AppConstants.jwtTokenKey);
    await _prefs?.remove(AppConstants.userIdKey);
  }

  bool get isAuthenticated => getJwtToken() != null && getUserId() != null;
}