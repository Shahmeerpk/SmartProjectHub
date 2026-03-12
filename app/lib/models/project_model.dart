class ProjectDto {
  final int id;
  final String title;
  final String abstract;
  final String status;
  final double progressPercent;
  final int studentId;
  final String? studentName;
  final String? rollNumber;

  ProjectDto({
    required this.id,
    required this.title,
    required this.abstract,
    required this.status,
    required this.progressPercent,
    required this.studentId,
    this.studentName,
    this.rollNumber,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Project',
      abstract: json['abstract'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      
      // Progress ko sahi se sambhalna
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      studentId: json['studentId'] as int? ?? 0,
      
      // 🔥 ASLI JADOO YAHAN HAI: Agar student null hai toh string mein fail na ho
      studentName: json['studentName'] as String?,
      rollNumber: json['rollNumber'] as String?,
    );
  }

  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isPending => status == 'Pending';
}