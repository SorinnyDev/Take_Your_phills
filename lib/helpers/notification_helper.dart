import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import '../models/reminder.dart';
import '../main.dart';
import '../screens/notification_screen_blue.dart';
import '../screens/notification_screen_white.dart';
import 'database_helper.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static BuildContext? _context;
  static bool _isInitialized = false;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // 🔥 앱 상태 관리
  static bool _isAppInForeground = true;

  // 🔥 MethodChannel 추가
  static const platform =
      MethodChannel('com.sorinnydev.take_your_pills/notification');

  // 🔥 진동 패턴 (카카오톡 스타일 - 강하고 짧게 2번)
  static final List<int> _vibrationPattern = [
    0, // 대기 없음
    200, // 강한 진동 200ms
    100, // 짧은 멈춤
    200, // 강한 진동 200ms
  ];

  // 🔥 AudioPlayer 추가
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 🔥 반복 재생 제어 변수
  static int _currentPlayCount = 0;
  static const int _maxPlayCount = 10; // 🔥 3번 → 10번으로 변경
  static Timer? _soundTimer;
  static StreamSubscription? _playerCompleteSubscription;

  static bool _isHandlingNotification = false;
  static DateTime? _lastHandlingTime;

  // ... 기존 코드 ...

  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      print('⚠️  NotificationHelper 이미 초기화됨');
      return;
    }

    _context = context;

    // 🔥 MethodChannel 핸들러 등록
    platform.setMethodCallHandler(_handleMethodCall);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📬 알림 응답 수신: ${details.payload}');
        if (details.payload != null) {
          final reminderId = int.tryParse(details.payload!);
          if (reminderId != null) {
            _navigateToNotificationScreen(reminderId);
          }
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
    );

    await _requestPermissions();

    _isInitialized = true;
    print('✅ NotificationHelper 초기화 완료');
  }

  // 🔥 MethodChannel 핸들러
  static Future<void> _handleMethodCall(MethodCall call) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📞 MethodChannel 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');

    switch (call.method) {
      case 'onForegroundNotification':
        final reminderId = int.tryParse(call.arguments.toString());
        if (reminderId != null) {
          print('   🚀 포그라운드 알림 처리: $reminderId');
          await _navigateToNotificationScreen(reminderId);
        }
        break;
      default:
        print('   ⚠️ 알 수 없는 메서드: ${call.method}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 앱 상태 업데이트
  static void updateAppState(bool isForeground) {
    _isAppInForeground = isForeground;
    print('📱 앱 상태 업데이트: ${isForeground ? "포그라운드" : "백그라운드"}');
  }

  // 🔥 사운드 재생 메서드 (10번 반복 후 자동 정지)
  static Future<void> _playNotificationSound() async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔊 알림 사운드 재생 시작...');

      // 🔥 수정: 이미 재생 중이면 스킵
      if (_currentPlayCount > 0) {
        print('⚠️  이미 사운드 재생 중 - 스킵');
        return;
      }

      // 재생 횟수 초기화
      _currentPlayCount = 0;

      // 사운드 반복 재생
      await _playSoundLoop();

      print('✅ 알림 사운드 재생 시작 완료');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 알림 사운드 재생 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 사운드 반복 재생 로직 (10번 반복 후 자동 정지)
  static Future<void> _playSoundLoop() async {
    if (_currentPlayCount >= _maxPlayCount) {
      print('🔇 최대 재생 횟수 도달 ($_maxPlayCount회) - 자동 정지');
      await stopNotificationSound();
      return;
    }

    _currentPlayCount++;
    print('🔊 사운드 재생 중... ($_currentPlayCount/$_maxPlayCount)');

    try {
      // 🔥 진동 추가 (카카오톡 스타일 - 강하고 짧게)
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(
          pattern: _vibrationPattern,
          intensities: [0, 255, 0, 255], // 🔥 최대 강도 (255)
        );
        print('📳 진동 시작 (강도: 최대)');
      }

      // 기존 리스너 제거
      await _playerCompleteSubscription?.cancel();

      // 사운드 재생
      await _audioPlayer.play(
        AssetSource('sounds/alarm03.mp3'),
        volume: 1.0,
      );

      // 🔥 사운드 완료 리스너
      _playerCompleteSubscription =
          _audioPlayer.onPlayerComplete.listen((event) {
        print('✅ 사운드 재생 완료 ($_currentPlayCount/$_maxPlayCount)');

        // 다음 재생 예약 (1초 대기 후)
        _soundTimer = Timer(Duration(seconds: 1), () {
          _playSoundLoop();
        });
      });
    } catch (e) {
      print('❌ 사운드 재생 중 오류: $e');
      await stopNotificationSound();
    }
  }

  // 🔥 사운드 정지 메서드
  static Future<void> stopNotificationSound() async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔇 사운드 정지 시작...');

      // 타이머 취소
      _soundTimer?.cancel();
      _soundTimer = null;

      // 리스너 제거
      await _playerCompleteSubscription?.cancel();
      _playerCompleteSubscription = null;

      // 오디오 정지
      await _audioPlayer.stop();

      // 🔥 진동 정지
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.cancel();
        print('📳 진동 정지 완료');
      }

      // 재생 횟수 초기화
      _currentPlayCount = 0;

      print('✅ 알림 사운드 정지 완료');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 알림 사운드 정지 실패: $e');
    }
  }

  // 🔥 화면 이동 메서드
  static Future<void> _navigateToNotificationScreen(int reminderId) async {
    // 🔥 타임아웃 체크 강화
    if (_isHandlingNotification) {
      final now = DateTime.now();
      if (_lastHandlingTime != null &&
          now.difference(_lastHandlingTime!).inSeconds < 3) {
        print('⚠️  이미 화면 이동 중 - 무시');
        return;
      } else {
        print('⚠️  플래그 강제 리셋 (타임아웃)');
        _isHandlingNotification = false;
      }
    }

    try {
      _isHandlingNotification = true;
      _lastHandlingTime = DateTime.now();
      print('   🚀 NotificationScreen으로 이동: reminderId=$reminderId');

      // 🔥 수정: 포그라운드/백그라운드 관계없이 항상 사운드 재생
      await _playNotificationSound();

      if (navigatorKey.currentState != null) {
        // 🔥 랜덤으로 Blue/White 화면 선택
        final random = Random();
        final useBlueScreen = random.nextBool();

        print('   🎨 화면 선택: ${useBlueScreen ? "Blue" : "White"}');

        await navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => useBlueScreen
                ? NotificationScreenBlue(reminderId: reminderId)
                : NotificationScreenWhite(reminderId: reminderId),
          ),
        );

        // 🔥 화면 닫힐 때 사운드 정지
        await stopNotificationSound();

        print('   ✅ 화면 이동 완료!');
      } else {
        print('   ❌ navigatorKey.currentState가 null입니다!');
      }
    } catch (e) {
      print('   ❌ 화면 이동 실패: $e');
      await stopNotificationSound();
    } finally {
      await Future.delayed(Duration(milliseconds: 500));
      _isHandlingNotification = false;
      print('   🔓 플래그 리셋 완료');
    }
  }

  // 🔥 알림 탭 핸들러
  static Future<void> handleNotificationTap(String? payload) async {
    if (payload == null) return;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📬 알림 탭 감지: payload=$payload');

    final reminderId = int.tryParse(payload);
    if (reminderId != null) {
      await _navigateToNotificationScreen(reminderId);
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🍎 iOS 포그라운드 알림 수신');
    print('   ID: $id, Payload: $payload');

    if (_isAppInForeground && payload != null) {
      final reminderId = int.tryParse(payload);
      if (reminderId != null) {
        await _navigateToNotificationScreen(reminderId);
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // 🔥 모든 활성화된 알림 재예약
  static Future<void> rescheduleAllNotifications() async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔄 알림 재예약 시작...');

      await _notifications.cancelAll();
      print('   ✅ 기존 알림 전부 취소');

      final reminders = await DatabaseHelper.getEnabledReminders();
      print('   📋 활성화된 알림: ${reminders.length}개');

      if (reminders.isEmpty) {
        print('   ⚠️  활성화된 알림이 없습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      final now = DateTime.now();

      for (var reminder in reminders) {
        final nextTime = _calculateNextNotificationTime(reminder, now);
        await _scheduleNotificationAt(reminder, nextTime);
        print('   ✅ ${reminder.title} - $nextTime 예약');
      }

      print('🎉 알림 재예약 완료!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 알림 재예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 다음 알림 시간 계산
  static DateTime _calculateNextNotificationTime(
      Reminder reminder, DateTime from) {
    var nextTime = DateTime(
      from.year,
      from.month,
      from.day,
      reminder.hour24,
      reminder.minute,
    );

    while (nextTime.isBefore(from)) {
      if (reminder.repeatHour == 0 && reminder.repeatMinute == 0) {
        nextTime = nextTime.add(Duration(days: 1));
      } else {
        nextTime = nextTime.add(Duration(
          hours: reminder.repeatHour,
          minutes: reminder.repeatMinute,
        ));
      }
    }

    return nextTime;
  }

  // 🔥 특정 시간에 알림 예약
  static Future<void> _scheduleNotificationAt(
      Reminder reminder, DateTime scheduledTime) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminder',
        channelDescription: 'Reminds you to take your medication',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        vibrationPattern: Int64List.fromList(_vibrationPattern),
      );

      final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        sound: 'sounds/alarm03.mp3',
        badgeNumber: 1,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.zonedSchedule(
        reminder.id!,
        reminder.title,
        '지금 약을 복용하세요!',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
      );

      print('   ✅ ${reminder.title} - $tzScheduledTime 에 예약');
    } catch (e) {
      print('   ❌ 알림 예약 실패: $e');
    }
  }

  // 🔥 알림 표시 메서드
  static Future<void> _showNotification(int reminderId, String title) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 알림 표시 시작');
    print('   ReminderId: $reminderId');
    print('   Title: $title');

    // 🔥 포그라운드일 때는 즉시 화면 이동
    if (_isAppInForeground) {
      print('   🚀 포그라운드 → 즉시 화면 이동!');
      await _navigateToNotificationScreen(reminderId);
    }

    // 🔥 알림은 항상 표시 (백그라운드/포그라운드 모두)
    final androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        title,
        htmlFormatBigText: false,
        contentTitle: '💊 약 먹을 시간이에요!',
        htmlFormatContentTitle: false,
      ),
      additionalFlags: Int32List.fromList([
        0x10000000, // FLAG_ACTIVITY_NEW_TASK
        0x20000000, // FLAG_ACTIVITY_SINGLE_TOP
      ]),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      reminderId,
      '💊 약 먹을 시간이에요!',
      title,
      details,
      payload: reminderId.toString(),
    );

    print('✅ 알림 표시 완료!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 스누즈 예약 (10분 후)
  static Future<void> snoozeNotification(int reminderId, int minutes) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 스누즈 예약 시작: $reminderId');

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder == null) {
        print('❌ Reminder를 찾을 수 없습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      final currentCount = reminder.currentSnoozeCount;
      print('   현재 스누즈 카운트: $currentCount/3');

      if (currentCount >= 3) {
        print('   ⚠️  스누즈 횟수 초과! 자동 스킵 처리');

        await DatabaseHelper.insertMedicationRecord(
          reminderId: reminderId,
          scheduledTime: DateTime.now(),
          status: 'auto_skipped',
          note: '3회 스누즈 후 자동 스킵',
        );

        await DatabaseHelper.resetSnoozeCount(reminderId);
        await scheduleNextNotification(reminderId);

        print('   ✅ 자동 스킵 완료 + 다음 알림 예약');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // 스누즈 카운트 증가
      final newCount = currentCount + 1;
      await DatabaseHelper.updateSnoozeCount(reminderId, newCount);

      // 10분 후 알림 예약
      final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
      await _scheduleNotificationAt(reminder, snoozeTime);

      print('   ✅ 스누즈 예약 완료!');
      print('   📍 예약 시간: $snoozeTime');
      print('   📊 스누즈 카운트: $newCount/3');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 스누즈 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 다음 정규 알림 예약
  static Future<void> scheduleNextNotification(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 다음 정규 알림 예약: $reminderId');

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder == null) {
        print('❌ Reminder를 찾을 수 없습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      if (!reminder.isEnabled) {
        print('⚠️  알림이 비활성화되어 있습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // 스누즈 카운트 리셋
      await DatabaseHelper.resetSnoozeCount(reminderId);

      // 🔥 현재 시간 이후의 다음 알림 시간 계산
      final now = DateTime.now();
      final nextTime = _calculateNextNotificationTime(reminder, now);

      // 알림 예약
      await _scheduleNotificationAt(reminder, nextTime);

      print('   ✅ 다음 알림 예약 완료!');
      print('   📍 예약 시간: $nextTime');
      print('   🔄 스누즈 카운트 리셋: 0/3');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 다음 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 복용 완료 처리
  static Future<void> markAsTaken(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ 복용 완료 처리: $reminderId');

      // 복용 기록 저장
      await DatabaseHelper.insertMedicationRecord(
        reminderId: reminderId,
        scheduledTime: DateTime.now(),
        takenAt: DateTime.now(),
        status: 'taken',
        note: '복용 완료',
      );

      // 현재 알림 취소
      await cancelNotification(reminderId);

      // 다음 알림 예약
      await scheduleNextNotification(reminderId);

      print('   ✅ 복용 완료 + 다음 알림 예약');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 복용 완료 처리 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 건너뛰기 처리
  static Future<void> markAsSkipped(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏭️  건너뛰기 처리: $reminderId');

      // 건너뛰기 기록 저장
      await DatabaseHelper.insertMedicationRecord(
        reminderId: reminderId,
        scheduledTime: DateTime.now(),
        status: 'skipped',
        note: '사용자가 건너뛰기',
      );

      // 현재 알림 취소
      await cancelNotification(reminderId);

      // 다음 알림 예약
      await scheduleNextNotification(reminderId);

      print('   ✅ 건너뛰기 + 다음 알림 예약');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 건너뛰기 처리 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 알림 취소
  static Future<void> cancelNotification(int? reminderId) async {
    if (reminderId == null) return;

    try {
      await _notifications.cancel(reminderId);
      print('✅ 알림 취소 완료: $reminderId');
    } catch (e) {
      print('❌ 알림 취소 실패: $e');
    }
  }

  // 🔥 10초 후 알림 (테스트용)
  static Future<void> scheduleTenSecondsNotification(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 10초 후 알림 예약: $reminderId');

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(Duration(seconds: 10));

      print('   예약 시간: $scheduledDate');

      await _notifications.zonedSchedule(
        reminderId,
        '약 먹을 시간이에요!',
        '10초 테스트 알림입니다',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // 🔥 sound 제거 (기본 알림음 사용)
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // 🔥 sound 제거 (기본 알림음 사용)
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminderId.toString(),
      );

      print('✅ 10초 후 알림 예약 완료!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 10초 후 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 새로운 알림 예약 메서드
  static Future<void> scheduleNotification(Reminder reminder) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📅 알림 예약: ${reminder.title}');

      final scheduledTime = reminder.getNextScheduledTimeAfter(DateTime.now());
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      print('   ⏰ 예약 시간: $tzScheduledTime');

      // 🔥 Android 설정 (카카오톡 스타일 진동)
      final androidDetails = AndroidNotificationDetails(
        'medication_channel',
        '복약 알림',
        channelDescription: '약 복용 시간을 알려드립니다',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPattern), // 🔥 카카오톡 스타일
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          '${reminder.title}\n지금 약을 복용하세요!',
          contentTitle: '💊 약 먹을 시간',
          summaryText: '복약 알림',
        ),
      );

      // 🔥 iOS 설정
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        reminder.id!,
        '💊 약 먹을 시간',
        '${reminder.title} - 지금 복용하세요!',
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
      );

      print('   ✅ 알림 예약 완료');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 즉시 알림 (테스트용)
  static Future<void> scheduleImmediateNotification(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⚡ 즉시 알림 예약: $reminderId');

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder == null) {
        print('❌ Reminder를 찾을 수 없습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // 1초 후 알림 (즉시)
      final immediateTime = DateTime.now().add(Duration(seconds: 1));
      await _scheduleNotificationAt(reminder, immediateTime);

      print('   ✅ 즉시 알림 예약 완료!');
      print('   📍 예약 시간: $immediateTime');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 즉시 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 앱 종료 시 알림 취소
  static Future<void> cancelAllNotifications() async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🙅‍♂️ 앱 종료 - 모든 알림 취소...');

      await _notifications.cancelAll();
      print('   ✅ 모든 알림 취소 완료');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('   ❌ 모든 알림 취소 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 앱 종료 시 알림 취소
  static void onAppExit() {
    print('📱 앱 종료 - 모든 알림 취소...');
    cancelAllNotifications();
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // 🔥 추가 필요한 메서드들

  /// 테스트용 알림 (10초 후)
  static Future<void> scheduleTestNotification(
    int reminderId,
    String title,
    int delaySeconds,
  ) async {
    final scheduledDate = DateTime.now().add(Duration(seconds: delaySeconds));

    await _notifications.zonedSchedule(
      reminderId + 10000, // 테스트 알림용 고유 ID
      '테스트 알림',
      '$title - $delaySeconds초 후 알림',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm03'), // 🔥 수정
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm03.mp3', // 🔥 수정
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );

    print('✅ 테스트 알림 예약: ${scheduledDate.toString()}');
  }

  /// 리마인더 알림 (2시간 후)
  static Future<void> scheduleReminderNotification(
    int reminderId,
    String title,
    int delayMinutes,
  ) async {
    final scheduledDate = DateTime.now().add(Duration(minutes: delayMinutes));

    await _notifications.zonedSchedule(
      reminderId + 20000, // 리마인더용 고유 ID
      '약 복용 확인',
      '$title - 복용하셨나요?',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          channelDescription: 'Reminder notification channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm03'), // 🔥 수정
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm03.mp3', // 🔥 수정
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );

    print('✅ 리마인더 알림 예약: ${scheduledDate.toString()}');
  }
}
