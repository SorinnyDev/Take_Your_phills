import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/reminder.dart';
import '../screens/notification_screen.dart';
import '../screens/notification_screen_blue.dart';
import '../screens/notification_screen_white.dart';
import 'database_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const platform =
      MethodChannel('com.sorinnydev.take_your_pills/notification');

  static bool _isAppInForeground = true;
  static bool _isHandlingNotification = false;

  static Future<void> initialize() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 NotificationHelper 초기화 시작');

    // 🔥 timezone 초기화 (수정됨!)
    try {
      tz_data.initializeTimeZones(); // 🔥 tz_data 사용!
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      print('✅ Timezone 초기화 완료');
    } catch (e) {
      print('⚠️  Timezone 초기화 실패: $e');
      // 기본 로컬 타임존 사용
      tz.setLocalLocation(tz.local);
    }

    // 🔥 Android 전용 - iOS에서는 실행하지 않음
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('updateAppState', {'isInForeground': true});
        print('   ✅ Android 상태 업데이트 성공');
      } catch (e) {
        print('   ⚠️  Android 상태 업데이트 실패: $e');
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (_isHandlingNotification) {
          print('⚠️  이미 알림 처리 중 - 무시');
          return;
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📱 알림 탭 감지 (Flutter)');
        print('   Payload: ${details.payload}');
        print('   앱 상태: ${_isAppInForeground ? "포그라운드" : "백그라운드"}');

        if (details.payload != null) {
          final reminderId = int.tryParse(details.payload!);
          if (reminderId != null) {
            await _navigateToNotificationScreen(reminderId);
          }
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
    );

    // 🔥 안드로이드 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'medication_channel',
      '약 알림',
      description: '약 복용 알림',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 🔥 네이티브 메서드 채널 설정
    platform.setMethodCallHandler(_handleNativeMethod);

    await _requestPermissions();

    print('✅ 알림 플러그인 초기화 완료');
    print('✅ NotificationHelper 초기화 완료');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 앱 상태 업데이트
  static Future<void> updateAppState(bool isInForeground) async {
    _isAppInForeground = isInForeground;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 앱 상태 변경: ${isInForeground ? "포그라운드" : "백그라운드"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 🔥 Android에도 상태 전달
    try {
      await platform.invokeMethod('updateAppState', {
        'isInForeground': isInForeground,
      });
    } catch (e) {
      print('⚠️  Android 상태 업데이트 실패: $e');
    }
  }

  static Future<void> _handleNativeMethod(MethodCall call) async {
    if (_isHandlingNotification) {
      print('⚠️  이미 알림 처리 중 - 무시');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');
    print('   Arguments Type: ${call.arguments.runtimeType}');

    if (call.method == 'onNotificationTap') {
      // 🔥 iOS/Android 모두 String으로 받아서 int로 변환
      final payload = call.arguments?.toString();
      print('   ✅ 백그라운드 알림 탭 - Payload: $payload');

      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
          print('   🚀 ReminderId 파싱 성공: $reminderId');
          await _navigateToNotificationScreen(reminderId);
        } else {
          print('   ❌ ReminderId 파싱 실패: $payload');
        }
      }
    } else if (call.method == 'onForegroundNotification') {
      print('   ✅ 포그라운드 알림 트리거 시작');

      int? reminderId;

      if (call.arguments == null) {
        print('   ❌ Arguments가 null입니다!');
        return;
      }

      if (call.arguments is int) {
        reminderId = call.arguments as int;
        print('   📍 ReminderId (int): $reminderId');
      } else if (call.arguments is String) {
        reminderId = int.tryParse(call.arguments as String);
        print('   📍 ReminderId (String → int): $reminderId');
      } else {
        print('   ❌ 지원하지 않는 타입: ${call.arguments.runtimeType}');
        return;
      }

      if (reminderId != null) {
        print('   🚀 화면 이동 시작...');
        await _navigateToNotificationScreen(reminderId);
        print('   ✅ 화면 이동 완료!');
      } else {
        print('   ❌ ReminderId 파싱 실패!');
      }
    } else if (call.method == 'updateAppState') {
      // 🔥 Android 전용 - iOS에서는 무시
      if (Platform.isAndroid) {
        final args = call.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('isInForeground')) {
          _isAppInForeground = args['isInForeground'] as bool;
          print('   📱 Android 앱 상태 업데이트: $_isAppInForeground');
        }
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 화면 이동 로직 통합
  static Future<void> _navigateToNotificationScreen(int reminderId) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ 네비게이터 컨텍스트를 찾을 수 없습니다. 화면 이동을 스킵합니다.');
      return;
    }

    final reminder = await DatabaseHelper.getReminderById(reminderId);
    if (reminder == null) {
      print('⚠️ 알림에 해당하는 Reminder를 찾을 수 없습니다: $reminderId');
      return;
    }

    // 테마를 랜덤으로 결정하여 적절한 화면으로 이동
    Widget notificationScreen;
    final randomTheme = Random().nextInt(3); // 0, 1, 2 중 하나를 랜덤으로 선택

    switch (randomTheme) {
      case 0:
        notificationScreen = NotificationScreen(reminderId: reminderId);
        break;
      case 1:
        notificationScreen = NotificationScreenBlue(reminderId: reminderId);
        break;
      case 2:
        notificationScreen = NotificationScreenWhite(reminderId: reminderId);
        break;
      default:
        notificationScreen = NotificationScreen(reminderId: reminderId);
        break;
    }

    // 화면 이동 로직
    void navigate(Widget screen) {
      // 현재 경로가 알림 화면이면 pushReplacement로 교체, 아니면 push
      if (ModalRoute.of(context)?.settings.name == '/notification') {
        print('🔄 기존 알림 화면을 새 화면으로 교체합니다.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/notification'),
            builder: (context) => screen,
          ),
        );
      } else {
        print('➡️ 새로운 알림 화면으로 이동합니다.');
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/notification'),
            builder: (context) => screen,
          ),
        );
      }
    }

    navigate(notificationScreen);
  }

  // 🔥 iOS 전용: 앱이 포그라운드에 있을 때 알림 수신
  static void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🍎 iOS 포그라운드 알림 수신');
    print('   ID: $id, Payload: $payload');

    if (_isAppInForeground && payload != null) {
      final reminderId = int.tryParse(payload);
      if (reminderId != null) {
        _navigateToNotificationScreen(reminderId);
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

      // 3. 각 Reminder의 다음 알림 시간 계산 & 예약
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
    // 오늘의 첫 알림 시간
    var nextTime = DateTime(
      from.year,
      from.month,
      from.day,
      reminder.hour24,
      reminder.minute,
    );

    // 이미 지났으면 다음 스케줄로
    while (nextTime.isBefore(from)) {
      if (reminder.repeatHour == 0 && reminder.repeatMinute == 0) {
        // 하루에 한 번 → 내일
        nextTime = nextTime.add(Duration(days: 1));
      } else {
        // 반복 간격만큼 추가
        nextTime = nextTime.add(Duration(
          hours: reminder.repeatHour,
          minutes: reminder.repeatMinute,
        ));
      }
    }

    return nextTime;
  }

  // 🔥 스누즈 예약 (10분 후)
  static Future<void> scheduleSnooze(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 스누즈 예약 시작: $reminderId');

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder == null) {
        print('❌ Reminder를 찾을 수 없습니다');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // 현재 스누즈 카운트 확인
      final currentCount = reminder.currentSnoozeCount;
      print('   현재 스누즈 카운트: $currentCount/3');

      if (currentCount >= 3) {
        print('   ⚠️  스누즈 횟수 초과! 자동 스킵 처리');

        // 자동 스킵 기록 저장
        await DatabaseHelper.insertMedicationRecord(
          reminderId: reminderId,
          scheduledTime: DateTime.now(),
          status: 'auto_skipped',
          note: '3회 스누즈 후 자동 스킵',
        );

        // 스누즈 카운트 리셋
        await DatabaseHelper.resetSnoozeCount(reminderId);

        // 다음 정규 알림 예약
        await scheduleNextNotification(reminderId);

        print('   ✅ 자동 스킵 완료 + 다음 알림 예약');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // 스누즈 카운트 증가
      final newCount = currentCount + 1;
      await DatabaseHelper.updateSnoozeCount(reminderId, newCount);

      // 10분 후 알림 예약
      final snoozeTime = DateTime.now().add(Duration(minutes: 10));
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

  // 🔥 알림 다시 울림 (스누즈)
  static Future<void> snoozeNotification(int reminderId, int minutes) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔄 $minutes분 후 알림 예약: $reminderId');

      await cancelNotification(reminderId);

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder != null && reminder.isEnabled) {
        final snoozedTime = DateTime.now().add(Duration(minutes: minutes));
        await _scheduleNotificationAt(reminder, snoozedTime);
        print('   ✅ $minutes분 후 알림 예약 완료: $snoozedTime');
      } else {
        print('   ⚠️  알림을 찾을 수 없거나 비활성화 상태');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 다시 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 다음 날로 알림 건너뛰기
  static Future<void> skipToNextDay(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏭️  내일 알림으로 건너뛰기: $reminderId');

      await cancelNotification(reminderId);

      final reminder = await DatabaseHelper.getReminderById(reminderId);
      if (reminder != null && reminder.isEnabled) {
        final now = DateTime.now();
        // 오늘 밤 자정을 기준으로 다음 스케줄 계산
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        // 🔥 수정: _calculateNextNotificationTime 헬퍼 함수 사용
        final nextTime = _calculateNextNotificationTime(reminder, tomorrow);

        await _scheduleNotificationAt(reminder, nextTime);
        print('   ✅ 내일 알림 예약 완료: $nextTime');
      } else {
        print('   ⚠️  알림을 찾을 수 없거나 비활성화 상태');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 내일 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // 🔥 특정 시간에 알림 예약 (내부용)
  static Future<void> _scheduleNotificationAt(
      Reminder reminder, DateTime scheduledTime) async {
    await _notifications.zonedSchedule(
      reminder.id!,
      '약 먹을 시간이에요!',
      reminder.title,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          '약 알림',
          channelDescription: '약 복용 알림',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          additionalFlags: Int32List.fromList([4]),
          styleInformation: BigTextStyleInformation(
            reminder.title,
            contentTitle: '약 먹을 시간이에요!',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'medication',
          attachments: [],
        ),
      ),
      payload: reminder.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
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
    final scheduledTime = DateTime.now().add(Duration(seconds: 10));

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('⏰ 10초 후 알림 예약: $reminderId');
    print('   예약 시간: $scheduledTime');

    final reminder = await DatabaseHelper.getReminderById(reminderId);
    if (reminder == null) {
      print('❌ Reminder를 찾을 수 없습니다');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    await _notifications.zonedSchedule(
      reminderId,
      '약 먹을 시간이에요!',
      reminder.title,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          '약 알림',
          channelDescription: '약 복용 알림',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          // 🔥 payload를 extras에 추가
          additionalFlags: Int32List.fromList([4]),
          styleInformation: BigTextStyleInformation(
            reminder.title,
            contentTitle: '약 먹을 시간이에요!',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'medication',
        ),
      ),
      payload: reminderId.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('✅ 10초 후 알림 예약 완료!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 새로운 알림 예약 메서드
  static Future<void> scheduleNotification(Reminder reminder) async {
    try {
      final scheduledDate = reminder.nextScheduledTime; // 🔥 이제 작동!

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 알림 예약: ${reminder.id}');
      print('   예약 시간: $scheduledDate');

      await _scheduleNotificationAt(reminder, scheduledDate);

      print('✅ 알림 예약 완료!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 알림 예약 실패: $e');
    }
  }

  // 🔥 테스트 알림 예약 메서드
  static Future<void> scheduleTestNotification(Reminder reminder) async {
    try {
      final testTime = DateTime.now().add(Duration(seconds: 10));

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 10초 후 알림 예약: ${reminder.id}');
      print('   예약 시간: $testTime');

      await _scheduleNotificationAt(reminder, testTime);

      print('✅ 10초 후 알림 예약 완료!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 테스트 알림 예약 실패: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // 🔥 새로운 알림 표시 메서드
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

    // 🔥 const 제거!
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

  // 🔥 알림 탭 처리 메서드
  static Future<void> onSelectNotification(String? payload) async {
    if (payload == null) return;
    final reminderId = int.tryParse(payload);
    if (reminderId == null) return;

    // 🔥 화면 이동 로직을 _handleNotificationTap으로 위임
    await _handleNotificationTap(reminderId);
  }

  // 🔥 알림 탭 시 화면 이동을 처리하는 새로운 비공개 메서드
  static Future<void> _handleNotificationTap(int reminderId) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ 네비게이터 컨텍스트를 찾을 수 없습니다.');
      return;
    }

    final reminder = await DatabaseHelper.getReminderById(reminderId);
    if (reminder == null) {
      print('⚠️ 알림에 해당하는 Reminder를 찾을 수 없습니다: $reminderId');
      return;
    }

    // 테마를 랜덤으로 결정하여 적절한 화면으로 이동
    Widget notificationScreen;
    final randomTheme = Random().nextInt(3); // 0, 1, 2 중 하나를 랜덤으로 선택

    switch (randomTheme) {
      case 0:
        notificationScreen = NotificationScreen(reminderId: reminderId);
        break;
      case 1:
        notificationScreen = NotificationScreenBlue(reminderId: reminderId);
        break;
      case 2:
        notificationScreen = NotificationScreenWhite(reminderId: reminderId);
        break;
      default:
        notificationScreen = NotificationScreen(reminderId: reminderId);
        break;
    }

    // 화면 이동 로직
    void navigate(Widget screen) {
      // 현재 경로가 알림 화면이면 pushReplacement로 교체, 아니면 push
      if (ModalRoute.of(context)?.settings.name == '/notification') {
        print('🔄 기존 알림 화면을 새 화면으로 교체합니다.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/notification'),
            builder: (context) => screen,
          ),
        );
      } else {
        print('➡️ 새로운 알림 화면으로 이동합니다.');
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/notification'),
            builder: (context) => screen,
          ),
        );
      }
    }

    navigate(notificationScreen);
  }
}
