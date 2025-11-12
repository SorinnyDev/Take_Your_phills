
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../screens/notification_screen.dart';
import '../models/reminder.dart';
import 'database_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const platform = MethodChannel('com.sorinnydev.take_your_pills/notification');

  // 🔥 앱이 포그라운드인지 추적
  static bool _isAppInForeground = true;
  
  // 🔥 중복 호출 방지 플래그
  static bool _isHandlingNotification = false;

  static Future<void> initialize() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 NotificationHelper 초기화 시작');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification, // 🔥 추가
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // 🔥 이미 처리 중이면 무시
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
      playSound: false, // 시스템 소리 끔 (앱에서 직접 재생)
      enableVibration: false, // 시스템 진동 끔 (앱에서 직접 제어)
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
  static void updateAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    
    // 🔥 Android에만 상태 전달
    if (Platform.isAndroid) {
      platform.invokeMethod('updateAppState', {'isInForeground': isInForeground});
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 앱 상태 변경: ${isInForeground ? "포그라운드" : "백그라운드"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> _handleNativeMethod(MethodCall call) async {
    // 🔥 이미 처리 중이면 무시
    if (_isHandlingNotification) {
      print('⚠️  이미 알림 처리 중 - 무시');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');
    print('   Arguments Type: ${call.arguments.runtimeType}'); // 🔥 타입 확인

    if (call.method == 'onNotificationTap') {
      // 🔥 백그라운드에서 알림 탭
      final payload = call.arguments as String?;
      print('   ✅ 백그라운드 알림 탭 - Payload: $payload');

      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
          await _navigateToNotificationScreen(reminderId);
        }
      }
    } else if (call.method == 'onForegroundNotification') {
      // 🔥 포그라운드에서 알림 트리거
      print('   ✅ 포그라운드 알림 트리거 시작');
      
      // 🔥 Arguments 타입 체크 강화
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
      // 🔥 Android에서 앱 상태 업데이트
      final args = call.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('isInForeground')) {
        _isAppInForeground = args['isInForeground'] as bool;
        print('   📱 Android 앱 상태 업데이트: $_isAppInForeground');
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 화면 이동 로직 통합 (중복 방지)
  static Future<void> _navigateToNotificationScreen(int reminderId) async {
    if (_isHandlingNotification) {
      print('⚠️  이미 화면 이동 중 - 무시');
      return;
    }

    _isHandlingNotification = true;
    print('   🚀 NotificationScreen으로 이동: reminderId=$reminderId');

    if (navigatorKey.currentState != null) {
      await navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => NotificationScreen(reminderId: reminderId),
        ),
      );
      print('   ✅ 화면 이동 완료!');
    } else {
      print('   ❌ navigatorKey.currentState가 null입니다!');
    }

    // 🔥 화면이 닫힌 후 플래그 리셋
    await Future.delayed(Duration(milliseconds: 500));
    _isHandlingNotification = false;
  }

  // 🔥 iOS 포그라운드 알림 처리
  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🍎 iOS 포그라운드 알림 수신');
    print('   ID: $id, Payload: $payload');
    
    // 🔥 포그라운드면 바로 화면 이동
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
      // 🔥 Android 13+ 알림 권한 요청
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // 🔥 ========== 여기부터 새로 추가된 부분 ==========

  // 🔥 모든 활성화된 알림 재예약
  static Future<void> rescheduleAllNotifications() async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔄 알림 재예약 시작...');

      // 1. 기존 예약된 알림 전부 취소
      await _notifications.cancelAll();
      print('   ✅ 기존 알림 전부 취소');

      // 2. DB에서 활성화된 Reminder 가져오기
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
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // 🔥 payload 전달
          threadIdentifier: 'medication',
        ),
      ),
      payload: reminder.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 🔥 ========== 여기까지 새로 추가된 부분 ==========

  // 🔥 10초 후 알림 (테스트용)
  static Future<void> scheduleTenSecondsNotification(int reminderId) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: 10));

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('⏰ 10초 후 알림 예약: $reminderId');
    print('   예약 시간: $scheduledTime');

    // 🔥 항상 시스템 알림 예약
    await _notifications.zonedSchedule(
      reminderId,
      '💊 약 먹을 시간이에요!',
      '10초 테스트 알림',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          '약 알림',
          channelDescription: '약 복용 알림',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
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

    print('   ✅ 시스템 알림 예약 완료');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 새로운 알림 예약 메서드
  static Future<void> scheduleNotification(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    // 🔥 기존 알림 취소
    await _notifications.cancel(reminder.id!);

    // 🔥 오늘 날짜 기준으로 스케줄 계산
    final today = DateTime.now();
    final schedules = reminder.calculateDailySchedules(today);

    print('📅 ${reminder.title} - ${schedules.length}개 스케줄 예약');

    for (var scheduleTime in schedules) {
      if (scheduleTime.isAfter(DateTime.now())) {
        // 🔥 알림 예약 로직
        await _notifications.zonedSchedule(
          reminder.id! + schedules.indexOf(scheduleTime), // 고유 ID
          reminder.title,
          '${reminder.title} 복용 시간입니다',
          tz.TZDateTime.from(scheduleTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_channel',
              'Medication Reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        print('⏰ ${scheduleTime.toString()} 예약 완료');
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
