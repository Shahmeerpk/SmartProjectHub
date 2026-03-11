class ProjectDto {
  final int id;
  final String title;
  final String abstract;
  final String status;
  final double progressPercent;
  final double? similarityScore;
  final String? rejectionReason;
  final String? objModelUrl;
  final int studentId;
  final String? studentName;
  final String? rollNumber; // <-- 1. NAYA VARIABLE YAHAN ADD KIYA HAI
  final int? teacherId;
  final String? teacherName;
  final int universityId;
  final String? universityName;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  ProjectDto({
    required this.id,
    required this.title,
    required this.abstract,
    required this.status,
    required this.progressPercent,
    this.similarityScore,
    this.rejectionReason,
    this.objModelUrl,
    required this.studentId,
    this.studentName,
    this.rollNumber, // <-- 2. CONSTRUCTOR MEIN ADD KIYA HAI
    this.teacherId,
    this.teacherName,
    required this.universityId,
    this.universityName,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) => ProjectDto(
        id: json['id'] as int,
        title: json['title'] as String,
        abstract: json['abstract'] as String,
        status: json['status'] as String,
        progressPercent: (json['progressPercent'] as num).toDouble(),
        similarityScore: json['similarityScore'] != null
            ? (json['similarityScore'] as num).toDouble()
            : null,
        rejectionReason: json['rejectionReason'] as String?,
        objModelUrl: json['objModelUrl'] as String?,
        studentId: json['studentId'] as int,
        studentName: json['studentName'] as String?,
        rollNumber: json['rollNumber'] as String?, // <-- 3. JSON PARSING MEIN ADD KIYA HAI
        teacherId: json['teacherId'] as int?,
        teacherName: json['teacherName'] as String?,
        universityId: json['universityId'] as int,
        universityName: json['universityName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.tryParse(json['reviewedAt'] as String)
            : null,
      );

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
}