
class MedicationRecord {
  final int? id;
  final int? reminderId;
  final String medicineName;
  final DateTime takenAt;
  final String? note;

  MedicationRecord({
    this.id,
    this.reminderId,
    required this.medicineName,
    required this.takenAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'medicine_name': medicineName,
      'taken_at': takenAt.toIso8601String(),
      'note': note,
    };
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'],
      reminderId: map['reminder_id'],
      medicineName: map['medicine_name'],
      takenAt: DateTime.parse(map['taken_at']),
      note: map['note'],
    );
  }
}
