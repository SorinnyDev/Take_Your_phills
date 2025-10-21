
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../screens/notification_screen.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 🔥 iOS: 앱 시작 시 마지막 알림 확인
    final notificationAppLaunchDetails = 
        await _notifications.getNotificationAppLaunchDetails();
    
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      print('🍎 앱이 알림으로 시작됨! Payload: $payload');
      
      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
          // 🔥 약간의 딜레이 후 화면 이동
          Future.delayed(Duration(milliseconds: 1000), () {
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                    reminderId: reminderId,
                  ),
                ),
              );
            }
          });
        }
      }
    }

    await _requestPermissions();
    print('✅ NotificationHelper 초기화 완료');
  }

  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('🍎 iOS 포그라운드 알림 수신: $title');
    
    if (payload != null) {
      final reminderId = int.tryParse(payload);
      if (reminderId != null && navigatorKey.currentContext != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => NotificationScreen(
              reminderId: reminderId,
            ),
          ),
        );
      }
    }
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 알림 클릭됨!');
    print('   Notification ID: ${response.id}');
    print('   Payload: ${response.payload}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (response.payload == null) {
      print('❌ Payload가 null입니다!');
      return;
    }

    final reminderId = int.tryParse(response.payload!);
    
    if (reminderId == null) {
      print('❌ ReminderId 파싱 실패: ${response.payload}');
      return;
    }

    print('✅ ReminderId 파싱 성공: $reminderId');
    print('🔍 Navigator State: ${navigatorKey.currentState}');
    
    if (navigatorKey.currentState == null) {
      print('❌ Navigator State가 null - 500ms 후 재시도');
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentState != null) {
          print('✅ Navigator 복구됨 - 화면 이동');
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                reminderId: reminderId,
              ),
            ),
          );
        }
      });
      return;
    }

    print('✅ 화면 이동 시작');
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          reminderId: reminderId,
        ),
      ),
    );
  }

  static Future<void> scheduleOneMinuteNotification(int reminderId) async {
    final now = DateTime.now();
    final scheduledTime = now.add(Duration(minutes: 1));
    
    print('🔔 1분 후 알림 예약');
    print('   Reminder ID: $reminderId');

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '테스트 알림',
      channelDescription: '1분 후 테스트 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      998,
      '💊 약 먹을 시간!',
      '지금 바로 확인하세요',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );

    print('✅ 알림 예약 완료!');
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
