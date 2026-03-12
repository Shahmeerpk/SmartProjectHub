import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_response.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';

class ApiService {
  static const _baseUrl =
      'http://192.168.100.62:5264'; // Match Api/Properties/launchSettings.json
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'user';

  final SharedPreferences _prefs;
  String? _accessToken;

  ApiService(this._prefs) {
    _accessToken = _prefs.getString(_keyAccessToken);
  }

  String get baseUrl => _baseUrl;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    UserDto user,
  ) async {
    _accessToken = accessToken;
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setString(
      _keyUser,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role,
        'universityId': user.universityId,
        'universityName': user.universityName,
      }),
    );
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUser);
  }

  UserDto? get cachedUser {
    final s = _prefs.getString(_keyUser);
    if (s == null) return null;
    try {
      return UserDto.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<LoginResponse?> login(String email, String password) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode != 200) return null;
    final resp = LoginResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
    await _saveTokens(resp.accessToken, resp.refreshToken, resp.user);
    return resp;
  }

  Future<LoginResponse?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required int universityId,
    String? rollNumber,
    String? department, // 🔥 NAYA
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
        'universityId': universityId,
        'rollNumber': rollNumber,
        'department': department, // 🔥 NAYA
      }),
    );
    
    if (r.statusCode != 200) {
      print('🚨 C# NE YEH ERROR BHEJA HAI: Status ${r.statusCode} -> ${r.body}'); 
      String errorMsg = 'Registration failed.';
      try {
        final body = jsonDecode(r.body);
        if (body['message'] != null) errorMsg = body['message'];
      } catch (_) {}
      throw Exception(errorMsg); 
    }
    
    final resp = LoginResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    await _saveTokens(resp.accessToken, resp.refreshToken, resp.user);
    return resp;
  }
  Future<bool> logout({String? refreshToken}) async {
    final token = refreshToken ?? _prefs.getString(_keyRefreshToken);
    if (_accessToken != null) {
      await http.post(
        Uri.parse('$_baseUrl/api/auth/logout'),
        headers: _headers,
        body: token != null ? jsonEncode({'refreshToken': token}) : null,
      );
    }
    await clearAuth();
    return true;
  }

  Future<List<Map<String, dynamic>>> getUniversities() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/api/universities'));
      if (r.statusCode != 200) return [];
      final list = jsonDecode(r.body) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProjectDto>> getMyProjects() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/projects'),
      headers: _headers,
    );
    if (r.statusCode != 200) return [];
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProjectDto>> getPendingProjects() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/projects/pending'),
      headers: _headers,
    );
    if (r.statusCode != 200) return [];
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectDto?> submitProject(String title, String abstract) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/projects'),
      headers: _headers,
      body: jsonEncode({'title': title, 'abstract': abstract}),
    );
    if (r.statusCode != 200) return null;
    return ProjectDto.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<bool> reviewProject(
    int projectId, {
    required bool approve,
    String? rejectionReason,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/projects/$projectId/review'),
      headers: _headers,
      body: jsonEncode({
        'approve': approve,
        'rejectionReason': rejectionReason,
      }),
    );
    return r.statusCode == 200;
  }

  Future<bool> updateProgress(int projectId, double progressPercent) async {
    final r = await http.patch(
      Uri.parse('$_baseUrl/api/projects/$projectId/progress'),
      headers: _headers,
      body: jsonEncode({'progressPercent': progressPercent}),
    );
    return r.statusCode == 200;
  }
}