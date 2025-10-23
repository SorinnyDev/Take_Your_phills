
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 추가
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../screens/notification_screen.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // 🔥 네이티브 채널 추가
  static const platform = MethodChannel('com.sorinnydev.take_your_pills/notification');

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

    // 🔥 네이티브 이벤트 리스너 등록
    platform.setMethodCallHandler(_handleNativeMethod);

    // iOS: 앱 시작 시 마지막 알림 확인
    final notificationAppLaunchDetails = 
        await _notifications.getNotificationAppLaunchDetails();
    
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      print('🍎 앱이 알림으로 시작됨! Payload: $payload');
      
      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
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

  // 🔥 네이티브에서 호출되는 메서드 처리
  static Future<void> _handleNativeMethod(MethodCall call) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    switch (call.method) {
      case 'onForegroundNotification':
        // 🔥 포그라운드 알림 - 바로 화면 이동!
        final reminderId = int.tryParse(call.arguments.toString());
        if (reminderId != null && navigatorKey.currentState != null) {
          print('✅ 포그라운드에서 바로 화면 이동!');
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
        // 🔥 백그라운드 알림 탭
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

  // 🔥 iOS 포그라운드 알림 수신 시 자동 화면 이동
  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🍎 iOS 포그라운드 알림 수신!');
    print('   ID: $id');
    print('   Title: $title');
    print('   Body: $body');
    print('   Payload: $payload');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (payload != null) {
      final reminderId = int.tryParse(payload);
      
      if (reminderId != null) {
        print('✅ ReminderId 파싱 성공: $reminderId');
        print('🔍 Navigator State: ${navigatorKey.currentState}');
        
        if (navigatorKey.currentState != null) {
          print('✅ 포그라운드에서 자동으로 화면 이동!');
          
          // 🔥 포그라운드에서 바로 화면 이동
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                reminderId: reminderId,
              ),
            ),
          );
        } else {
          print('❌ Navigator State가 null');
        }
      } else {
        print('❌ ReminderId 파싱 실패: $payload');
      }
    } else {
      print('❌ Payload가 null');
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

  // 🔥 백그라운드/종료 상태에서 알림 탭 처리
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 알림 클릭됨! (백그라운드/종료 상태)');
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

  // 🔥 10초 후 알림
  static Future<void> scheduleTenSecondsNotification(int reminderId) async {
    final now = DateTime.now();
    final scheduledTime = now.add(Duration(seconds: 10));
    
    print('🔔 10초 후 알림 예약');
    print('   Reminder ID: $reminderId');

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '테스트 알림',
      channelDescription: '10초 후 테스트 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // 🔥 userInfo 제거 - payload로만 전달
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
      payload: reminderId.toString(), // 🔥 이것만으로 충분!
    );

    print('✅ 알림 예약 완료! (10초 후)');
  }

  // 🔥 1분 후 알림 예약
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

    // 🔥 userInfo 제거
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
      999,
      '💊 약 먹을 시간!',
      '1분이 지났습니다. 지금 바로 확인하세요',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(), // 🔥 payload로 전달
    );

    print('✅ 알림 예약 완료! (1분 후)');
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
