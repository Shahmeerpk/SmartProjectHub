class UserDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int universityId;
  final String? universityName;
  final String? department;
  final String? profilePictureUrl; // 🔥 NAYA

  UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.universityId,
    this.universityName,
    this.department,
    this.profilePictureUrl, // 🔥 NAYA
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'Student',
      universityId: json['universityId'] as int? ?? 0,
      universityName: json['universityName'] as String?,
      department: json['department'] as String?,
      
      // 🔥 YEH WALI LINE MISSING THI JISKI WAJAH SE RESTART PAR DP GAYAB HOTI THI:
      profilePictureUrl: json['profilePictureUrl'] as String?, 
    );
  }

  bool get isTeacher => role == 'Teacher';
  bool get isStudent => role == 'Student';
  bool get isHod => role == 'HOD';
}