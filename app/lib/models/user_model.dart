class UserDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int universityId;
  final String? universityName;

  UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.universityId,
    this.universityName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        universityId: json['universityId'] as int,
        universityName: json['universityName'] as String?,
      );

  bool get isTeacher => role == 'Teacher';
  bool get isStudent => role == 'Student';
}
