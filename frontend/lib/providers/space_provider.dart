// lib/providers/space_provider.dart

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SpaceProvider with ChangeNotifier {
  final ApiService     _api;
  final StorageService _storage;

  SpaceProvider({ApiService? api, StorageService? storage})
      : _api     = api     ?? ApiService(),
        _storage = storage ?? StorageService();

  List<Space> _spaces    = [];
  bool        _isLoading = false;
  String?     _error;

  List<Space> get spaces    => _spaces;
  bool        get isLoading => _isLoading;
  String?     get error     => _error;

  String? get _token => _storage.getJwtToken();
  String? get _uid   => _storage.getUserId();

  Future<void> loadSpaces() async {
    final t = _token;
    if (t == null) return;

    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _spaces    = await _api.getSpaces(t);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error     = e is ApiException ? e.userMessage : e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Space> createSpace({
    required String spaceName,
    required String spacePassword,
  }) async {
    final t = _token;
    final u = _uid;
    if (t == null || u == null) throw Exception('Not authenticated');

    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final space = await _api.createSpace(
        spaceName:     spaceName,
        spacePassword: spacePassword,
        userId:        u,
        token:         t,
      );
      _spaces.add(space);
      _isLoading = false;
      notifyListeners();
      return space;
    } catch (e) {
      _error     = e is ApiException ? e.userMessage : e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Space> joinSpace({
    required String spaceName,
    required String spacePassword,
  }) async {
    final t = _token;
    if (t == null) throw Exception('Not authenticated');

    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final space = await _api.joinSpace(
        spaceName:     spaceName,
        spacePassword: spacePassword,
        token:         t,
      );
      if (!_spaces.any((s) => s.id == space.id)) _spaces.add(space);
      _isLoading = false;
      notifyListeners();
      return space;
    } catch (e) {
      _error     = e is ApiException ? e.userMessage : e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Image Provider
// ─────────────────────────────────────────────────────────────────────────────

class GrabImageProvider with ChangeNotifier {
  final ApiService     _api;
  final StorageService _storage;

  GrabImageProvider({ApiService? api, StorageService? storage})
      : _api     = api     ?? ApiService(),
        _storage = storage ?? StorageService();

  List<UserImage> _images    = [];
  bool            _isLoading = false;
  String?         _error;
  String?         _currentSpaceId;

  List<UserImage> get images        => _images;
  bool            get isLoading     => _isLoading;
  String?         get error         => _error;
  String?         get currentSpaceId => _currentSpaceId;

  String? get _token => _storage.getJwtToken();

  Future<void> loadImages(String spaceId) async {
    final t = _token;
    if (t == null) return;

    _isLoading      = true;
    _error          = null;
    _currentSpaceId = spaceId;
    notifyListeners();

    try {
      _images    = await _api.getImages(spaceId: spaceId, token: t);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error     = e is ApiException ? e.userMessage : e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}