
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

  // 🔥 24시간 형식 시간
  int get hour24 {
    if (amPm == 'AM') {
      return hour == 12 ? 0 : hour;
    } else {
      return hour == 12 ? 12 : hour + 12;
    }
  }

  // 🔥 다음 알림 시간 계산
  DateTime get nextScheduledTime {
    final now = DateTime.now();
    
    // 오늘의 첫 알림 시간
    var nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour24,
      minute,
    );

    // 이미 지났으면 다음 스케줄로
    while (nextTime.isBefore(now)) {
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

  // 🔥 하루 동안의 모든 스케줄 시간 계산 (자정에서 리셋)
  List<DateTime> calculateDailySchedules(DateTime referenceDate) {
    final schedules = <DateTime>[];
    
    // 시작 시간 (오늘 날짜 기준)
    DateTime startTime = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour24,
      minute,
    );
    
    // 반복 간격 (분 단위)
    final intervalMinutes = (repeatHour * 60) + repeatMinute;
    
    // 🔥 간격이 0이면 하루에 한 번만 (반복 없음)
    if (intervalMinutes == 0) {
      schedules.add(startTime);
      return schedules;
    }
    
    // 🔥 하루의 끝 시간 (자정 직전)
    final endOfDay = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      23,
      59,
      59,
    );
    
    // 🔥 하루 동안만 반복 (자정 넘어가면 중단)
    DateTime currentTime = startTime;
    
    while (currentTime.isBefore(endOfDay) || currentTime.isAtSameMomentAs(endOfDay)) {
      schedules.add(currentTime);
      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
      
      // 🔥 다음 시간이 자정을 넘으면 중단
      if (currentTime.day != referenceDate.day) {
        break;
      }
    }
    
    return schedules;
  }

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
      createdAt: DateTime.parse(map['createdAt']), // 🔥 DB에서 가져온 값 사용
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
      'createdAt': createdAt.toIso8601String(), // 🔥 생성자에서 이미 설정된 값 사용
    };
  }
}
