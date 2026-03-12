class UserDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int universityId;
  final String? universityName;
  final String? department;

  UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.universityId,
    this.universityName,
    this.department,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      // Agar C# se id nahi aayi toh 0 kardo, warna error mat do
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'Student',
      universityId: json['universityId'] as int? ?? 0,
      
      // ? ka matlab hai ke yeh null ho sakte hain
      universityName: json['universityName'] as String?,
      department: json['department'] as String?,
    );
  }

  bool get isTeacher => role == 'Teacher';
  bool get isStudent => role == 'Student';
  bool get isHod => role == 'HOD';
}