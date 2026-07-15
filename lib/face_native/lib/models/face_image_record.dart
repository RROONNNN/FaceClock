class FaceImageRecord {
  final int empId;
  final String personName;
  final List<double> faceEmbedding;
  const FaceImageRecord({
    required this.empId,
    required this.personName,
    required this.faceEmbedding,
  });
  factory FaceImageRecord.fromMap(Map<dynamic, dynamic> map) {
    return FaceImageRecord(
      empId: map['empId'] ?? 0,
      personName: map['personName'] ?? '',
      faceEmbedding: List<double>.from(map['faceEmbedding'] ?? []),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'empId': empId,
      'personName': personName,
      'faceEmbedding': faceEmbedding,
    };
  }
}
