
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../screens/notification_screen.dart';

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
    print('📱 앱 상태 업데이트: ${isInForeground ? "포그라운드" : "백그라운드"}');
  }

  static Future<void> _handleNativeMethod(MethodCall call) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    switch (call.method) {
      case 'onForegroundNotification':
        final reminderId = int.tryParse(call.arguments.toString());
        if (reminderId != null && navigatorKey.currentState != null) {
          print('✅ 포그라운드 - 바로 화면 이동!');
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                reminderId: reminderId,
              ),
            ),
          );
        }
        break;
        
      case 'onNotificationTap':
        final reminderId = int.tryParse(call.arguments.toString());
        if (reminderId != null && navigatorKey.currentState != null) {
          print('✅ 백그라운드 알림 탭 - 화면 이동!');
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                reminderId: reminderId,
              ),
            ),
          );
        }
        break;
    }
  }

  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🍎 iOS 포그라운드 알림 수신!');
    print('   ID: $id');
    print('   Payload: $payload');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> _requestPermissions() async {
    print('🔐 권한 요청 시작');

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('   Android 알림 권한: ${granted == true ? "✅ 허용됨" : "❌ 거부됨"}');
      
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      print('   Android 정확한 알람 권한: ${exactAlarmGranted == true ? "✅ 허용됨" : "❌ 거부됨"}');
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('   iOS 알림 권한 요청 완료');
    }

    print('✅ 권한 요청 완료');
  }

  // 🔥 10초 후 알림 (테스트용)
  static Future<void> scheduleTenSecondsNotification(int reminderId) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: 10));

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 10초 후 알림 예약 시작');
    print('   현재 시간: $now');
    print('   예약 시간: $scheduledDate');
    print('   Reminder ID: $reminderId');
    print('   플랫폼: ${Platform.isIOS ? "iOS" : "Android"}');
    print('   현재 앱 상태: ${_isAppInForeground ? "포그라운드" : "백그라운드"}');

    // 🔥 Android: 포그라운드면 바로 화면 이동
    if (Platform.isAndroid && _isAppInForeground) {
      print('✅ Android 포그라운드 - 10초 후 바로 화면 이동');
      
      Future.delayed(Duration(seconds: 10), () {
        if (navigatorKey.currentState != null) {
          print('✅ 10초 경과 - 화면 이동!');
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                reminderId: reminderId,
              ),
            ),
          );
        }
      });
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    // 🔥 iOS는 항상 알림 예약 (AppDelegate에서 처리)
    // 🔥 Android 백그라운드도 알림 예약
    print('✅ 알림 예약 (iOS 또는 Android 백그라운드)');

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      ticker: '약 먹을 시간입니다!',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      998,
      '💊 약 먹을 시간!',
      '지금 복용하세요',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );

    print('✅ 알림 예약 성공!');

    final pending = await getPendingNotifications();
    print('📋 현재 예약된 알림 개수: ${pending.length}');
    for (var notification in pending) {
      print('   - ID: ${notification.id}, 제목: ${notification.title}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
