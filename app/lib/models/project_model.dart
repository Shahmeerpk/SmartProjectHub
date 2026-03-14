class ProjectDto {
  final int id;
  final String title;
  final String abstract;
  final String status;
  final double progressPercent;
  final double similarityScore; 
  final String? rejectionReason;
  
  final int studentId;
  final String? studentName;
  final String? rollNumber;
  
  final int? teacherId;
  final String? teacherName;
  
  final int universityId;
  final String? universityName;
  
  // 🔥 WORKSPACE KE LIYE 3 NAYI CHEEZEIN 🔥
  final String? videoUrl;
  final String? model3DUrl;
  final String? projectLinks;

  final DateTime createdAt;
  final DateTime? reviewedAt;

  ProjectDto({
    required this.id,
    required this.title,
    required this.abstract,
    required this.status,
    required this.progressPercent,
    required this.similarityScore,
    this.rejectionReason,
    required this.studentId,
    this.studentName,
    this.rollNumber,
    this.teacherId,
    this.teacherName,
    required this.universityId,
    this.universityName,
    this.videoUrl, // Naya
    this.model3DUrl, // Naya
    this.projectLinks, // Naya
    required this.createdAt,
    this.reviewedAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      abstract: json['abstract'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
      rejectionReason: json['rejectionReason'] as String?,
      
      studentId: json['studentId'] as int? ?? 0,
      studentName: json['studentName'] as String?,
      rollNumber: json['rollNumber'] as String?,
      
      teacherId: json['teacherId'] as int?,
      teacherName: json['teacherName'] as String?,
      
      universityId: json['universityId'] as int? ?? 0,
      universityName: json['universityName'] as String?,
      
      // 🔥 Yahan Flutter ko sikhaya ke naye links kaise parhne hain
      videoUrl: json['videoUrl'] as String?,
      model3DUrl: json['model3DUrl'] as String?,
      projectLinks: json['projectLinks'] as String?,
      
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );
  }

  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isPending => status == 'Pending';
}