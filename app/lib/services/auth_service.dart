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
      return resp != null;
    } catch (e) {
      rethrow; // Error ko aagay screen par bhej do
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required int universityId,
    String? rollNumber,
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
        rollNumber: rollNumber,
      );
      _user = resp?.user;
      return resp != null;
    } catch (e) {
      rethrow; // 🔥 YEH RAHI ASLI LINE: Error ko goli marne ke bajaye UI ko bhejo!
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