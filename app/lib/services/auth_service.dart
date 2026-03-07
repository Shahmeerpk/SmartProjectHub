import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;

  UserDto? _user;
  bool _isLoading = false;

  AuthService(this._api) {
    _user = _api.cachedUser;
  }

  UserDto? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.login(email, password);
      _user = resp?.user;
      notifyListeners();
      return resp != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required int universityId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        universityId: universityId,
      );
      _user = resp?.user;
      notifyListeners();
      return resp != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }
}
