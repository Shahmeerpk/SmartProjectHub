import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // 🔥 NAYA: User ko phone memory mein update karne ka function
  Future<void> updateCachedUser(UserDto user) async {
    await _prefs.setString(
      _keyUser,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role,
        'universityId': user.universityId,
        'universityName': user.universityName,
        'department': user.department, // 🔥 YAHAN SE DP AUR DEPT GAYAB THE
        'profilePictureUrl': user.profilePictureUrl, 
      }),
    );
  }

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    UserDto user,
  ) async {
    _accessToken = accessToken;
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await updateCachedUser(user); // Upar wala function call kiya
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
    String? department,
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
        'department': department,
      }),
    );
    
    if (r.statusCode != 200) {
      debugPrint('🚨 C# NE YEH ERROR BHEJA HAI: Status ${r.statusCode} -> ${r.body}'); 
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

  // 🔥 NAYA: Web aur Mobile dono par chalne wala Upload Function
  Future<String?> uploadProfilePicture(dynamic pickedFile) async {
    try {
      if (_accessToken == null) return null;

      final uri = Uri.parse('$_baseUrl/api/auth/profile-picture');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $_accessToken';
      
      final bytes = await pickedFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: pickedFile.name,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonMap = json.decode(respStr);
        return jsonMap['profilePictureUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }
  // 🔥 NAYE WORKSPACE ENDPOINTS 🔥

  // 1. Links Update Karne Ka Function
  Future<bool> updateProjectLinks(int projectId, String links) async {
    if (_accessToken == null) return false;
    final r = await http.put(
      Uri.parse('$_baseUrl/api/projects/$projectId/links'),
      headers: _headers,
      body: jsonEncode({'linksJson': links}),
    );
    return r.statusCode == 200;
  }

  // 2. Video aur 3D Model dono ke liye ek Master Upload Function
  Future<String?> uploadWorkspaceFile(int projectId, Uint8List fileBytes, String fileName, String type) async {
    try {
      if (_accessToken == null) return null;
      
      // Check karega ke Video hai ya 3D Model
      final endpoint = type == 'video' ? 'upload-video' : 'upload-3dmodel';
      final uri = Uri.parse('$_baseUrl/api/projects/$projectId/$endpoint');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_accessToken';

      // Web aur Mobile dono pe chalne wala file format (Bytes)
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonMap = json.decode(respStr);
        return type == 'video' ? jsonMap['videoUrl'] : jsonMap['model3DUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }
}