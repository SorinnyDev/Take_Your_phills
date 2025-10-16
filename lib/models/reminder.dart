
class Reminder {
  final int? id;
  final String title;
  final String amPm;
  final int hour;
  final int minute;
  final int repeatHour;
  final int repeatMinute;
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    this.id,
    required this.title,
    required this.amPm,
    required this.hour,
    required this.minute,
    required this.repeatHour,
    required this.repeatMinute,
    required this.isEnabled,
    required this.createdAt,
  });

  // DB에서 가져올 때 사용
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      amPm: map['amPm'],
      hour: map['hour'],
      minute: map['minute'],
      repeatHour: map['repeatHour'],
      repeatMinute: map['repeatMinute'],
      isEnabled: map['isEnabled'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // DB에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amPm': amPm,
      'hour': hour,
      'minute': minute,
      'repeatHour': repeatHour,
      'repeatMinute': repeatMinute,
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
