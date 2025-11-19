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
  final int currentSnoozeCount;

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
    this.currentSnoozeCount = 0,
  });

  // 24시간 형식 시간
  int get hour24 {
    if (amPm == 'AM') {
      return hour == 12 ? 0 : hour;
    } else {
      return hour == 12 ? 12 : hour + 12;
    }
  }

  // 다음 예정 시간 계산
  DateTime get nextScheduledTime {
    final now = DateTime.now();
    return getNextScheduledTimeAfter(now);
  }

  // 🔥 특정 시간 이후의 다음 알림 시간 계산
  DateTime getNextScheduledTimeAfter(DateTime from) {
    var nextTime = DateTime(
      from.year,
      from.month,
      from.day,
      hour24,
      minute,
    );

    // 이미 지난 시간이면 다음 스케줄로
    while (nextTime.isBefore(from) || nextTime.isAtSameMomentAs(from)) {
      if (repeatHour == 0 && repeatMinute == 0) {
        // 하루에 한 번 → 내일
        nextTime = nextTime.add(Duration(days: 1));
      } else {
        // 반복 간격만큼 추가
        nextTime = nextTime.add(Duration(
          hours: repeatHour,
          minutes: repeatMinute,
        ));
      }
    }

    return nextTime;
  }

  // 하루 일정 계산
  List<DateTime> calculateDailySchedules(DateTime date) {
    final schedules = <DateTime>[];

    var currentTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour24,
      minute,
    );

    schedules.add(currentTime);

    if (repeatHour > 0 || repeatMinute > 0) {
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      while (true) {
        currentTime = currentTime.add(Duration(
          hours: repeatHour,
          minutes: repeatMinute,
        ));

        if (currentTime.isAfter(endOfDay)) break;
        schedules.add(currentTime);
      }
    }

    return schedules;
  }

  // Map으로 변환
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
      'currentSnoozeCount': currentSnoozeCount,
    };
  }

  // Map에서 생성
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
      currentSnoozeCount: map['currentSnoozeCount'] ?? 0,
    );
  }

  // copyWith 메서드
  Reminder copyWith({
    int? id,
    String? title,
    String? amPm,
    int? hour,
    int? minute,
    int? repeatHour,
    int? repeatMinute,
    bool? isEnabled,
    DateTime? createdAt,
    int? currentSnoozeCount,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amPm: amPm ?? this.amPm,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatHour: repeatHour ?? this.repeatHour,
      repeatMinute: repeatMinute ?? this.repeatMinute,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      currentSnoozeCount: currentSnoozeCount ?? this.currentSnoozeCount,
    );
  }
}
