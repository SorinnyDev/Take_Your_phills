
class MedicationRecord {
  final int? id;
  final int? reminderId; // 🔥 nullable로 변경 (수동 기록용)
  final String? medicineName; // 🔥 추가 (수동 기록용)
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final String status;
  final String? note;

  MedicationRecord({
    this.id,
    this.reminderId,
    this.medicineName,
    required this.scheduledTime,
    this.takenAt,
    required this.status,
    this.note,
  });

  // 🔥 ManualRecordScreen용 간편 생성자
  MedicationRecord.manual({
    required String medicineName,
    required DateTime takenAt,
    String? note,
  }) : this(
          medicineName: medicineName,
          scheduledTime: takenAt,
          takenAt: takenAt,
          status: 'taken',
          note: note,
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderId': reminderId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenAt': takenAt?.toIso8601String(),
      'status': status,
      'note': note,
    };
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'],
      reminderId: map['reminderId'],
      medicineName: map['medicineName'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
      status: map['status'],
      note: map['note'],
    );
  }
}
