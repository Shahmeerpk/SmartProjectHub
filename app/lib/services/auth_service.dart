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
  bool get isHod => _user?.isHod ?? false;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.login(email, password);
      _user = resp?.user;
      return resp != null;
    } catch (e) {
      rethrow; 
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
    String? department, 
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
        department: department, 
      );
      _user = resp?.user;
      return resp != null;
    } catch (e) {
      rethrow;
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

  // 🔥 NAYA: DP update karne aur Cache mein save karne ka mukammal function
  // 🔥 NAYA: DP update karne aur Cache mein save karne ka mukammal function
  Future<void> updateProfilePicture(String newUrl) async {
    if (_user != null) {
      _user = UserDto(
        id: _user!.id,
        email: _user!.email,
        fullName: _user!.fullName,
        role: _user!.role,
        universityId: _user!.universityId,
        universityName: _user!.universityName,
        department: _user!.department,
        profilePictureUrl: newUrl, 
      );
      
      await _api.updateCachedUser(_user!); // 🔥 YAHAN AWAIT LAGA DIYA
      notifyListeners();
    }
  }
}