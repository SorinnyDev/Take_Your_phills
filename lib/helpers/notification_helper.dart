
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static const platform = MethodChannel('com.sorinnydev.take_your_pills/notification');

  // 🔥 앱이 포그라운드인지 추적
  static bool _isAppInForeground = true;

  static Future<void> initialize() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 NotificationHelper 초기화 시작');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
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

    await _notifications.initialize(initSettings);

    print('✅ 알림 플러그인 초기화 완료');

    platform.setMethodCallHandler(_handleNativeMethod);

    await _requestPermissions();
    
    print('✅ NotificationHelper 초기화 완료');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 🔥 앱 상태 업데이트
  static void updateAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 앱 상태 변경: ${isInForeground ? "포그라운드" : "백그라운드"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> _handleNativeMethod(MethodCall call) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');

    if (call.method == 'onNotificationTap' || call.method == 'onForegroundNotification') {
      final payload = call.arguments as String?;
      print('   ✅ 알림 수신 - Payload: $payload');
      
      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
          print('   🚀 NotificationScreen으로 이동: reminderId=$reminderId');
          
          // 🔥 navigatorKey 상태 확인
          print('   navigatorKey.currentState: ${navigatorKey.currentState}');
          print('   navigatorKey.currentContext: ${navigatorKey.currentContext}');
          
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => NotificationScreen(reminderId: reminderId),
              ),
            );
            print('   ✅ 화면 이동 완료!');
          } else {
            print('   ❌ navigatorKey.currentState가 null입니다!');
          }
        }
      }
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
    print('🍎 iOS 로컬 알림 수신');
    print('   ID: $id');
    print('   Title: $title');
    print('   Body: $body');
    print('   Payload: $payload');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print('✅ iOS 알림 권한: ${granted == true ? "허용됨" : "거부됨"}');
    } else if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      print('✅ Android 알림 권한: ${granted == true ? "허용됨" : "거부됨"}');
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
  static DateTime _calculateNextNotificationTime(Reminder reminder, DateTime from) {
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
  static Future<void> _scheduleNotificationAt(Reminder reminder, DateTime scheduledTime) async {
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
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: reminder.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 🔥 ========== 여기까지 새로 추가된 부분 ==========

  // 🔥 10초 후 알림 (테스트용) - 기존 코드 유지
  static Future<void> scheduleTenSecondsNotification(int reminderId) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: 10));

    await _notifications.zonedSchedule(
      reminderId,
      '약 먹을 시간이에요!',
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
        ),
      ),
      payload: reminderId.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('⏰ 10초 후 알림 예약: ${reminderId}');
    print('   예약 시간: $scheduledTime');
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

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
