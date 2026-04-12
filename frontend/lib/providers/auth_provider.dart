// lib/providers/auth_provider.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService     _api;
  final StorageService _storage;

  AuthProvider({ApiService? api, StorageService? storage})
      : _api     = api     ?? ApiService(),
        _storage = storage ?? StorageService();

  AuthResponse? _user;
  bool          _isLoading = false;
  String?       _error;

  AuthResponse? get user         => _user;
  bool          get isLoading    => _isLoading;
  String?       get error        => _error;
  bool          get isAuthenticated => _user != null;

  set user(AuthResponse? value) {
    _user = value;
    notifyListeners();
  }

  /// Face-authenticate using a selfie captured by the browser.
  Future<AuthResponse> authenticateWithFace(Uint8List bytes, String fileName) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final resp = await _api.faceAuthenticate(bytes, fileName);
      _user = resp;

      if (resp.token != null) await _storage.saveJwtToken(resp.token!);
      await _storage.saveUserId(resp.id);

      _isLoading = false;
      notifyListeners();
      return resp;
    } catch (e) {
      _error     = e is ApiException ? e.userMessage : e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    _user  = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}