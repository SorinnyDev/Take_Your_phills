import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/reminder.dart';
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
  static DateTime? _lastHandlingTime;

  static Future<void> initialize() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 NotificationHelper 초기화 시작');

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      print('✅ Timezone 초기화 완료');
    } catch (e) {
      print('⚠️  Timezone 초기화 실패: $e');
      tz.setLocalLocation(tz.local);
    }

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
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📱 알림 탭 감지 (Flutter)');
        print('   Payload: ${details.payload}');
        print('   _isHandlingNotification: $_isHandlingNotification');

        if (details.payload != null) {
          final reminderId = int.tryParse(details.payload!);
          if (reminderId != null) {
            await _navigateToNotificationScreen(reminderId);
          }
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
    );

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

    platform.setMethodCallHandler(_handleNativeMethod);
    await _requestPermissions();

    print('✅ NotificationHelper 초기화 완료');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<void> updateAppState(bool isInForeground) async {
    _isAppInForeground = isInForeground;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 앱 상태 변경: ${isInForeground ? "포그라운드" : "백그라운드"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      await platform.invokeMethod('updateAppState', {
        'isInForeground': isInForeground,
      });
    } catch (e) {
      print('⚠️  Android 상태 업데이트 실패: $e');
    }
  }

  static Future<void> _handleNativeMethod(MethodCall call) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 네이티브 메서드 호출: ${call.method}');
    print('   Arguments: ${call.arguments}');
    print('   _isHandlingNotification: $_isHandlingNotification');

    // 🔥 중복 호출 방지 강화
    if (_isHandlingNotification) {
      final now = DateTime.now();
      if (_lastHandlingTime != null &&
          now.difference(_lastHandlingTime!).inSeconds < 5) {
        // 3초 → 5초로 증가
        print(
            '⚠️  이미 알림 처리 중 - 무시 (${now.difference(_lastHandlingTime!).inSeconds}초 경과)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      } else {
        print('⚠️  플래그 강제 리셋 (타임아웃)');
        _isHandlingNotification = false;
      }
    }

    if (call.method == 'onNotificationTap') {
      final payload = call.arguments?.toString();
      print('   ✅ 백그라운드 알림 탭 - Payload: $payload');

      if (payload != null) {
        final reminderId = int.tryParse(payload);
        if (reminderId != null) {
          print('   🚀 ReminderId 파싱 성공: $reminderId');
          await _navigateToNotificationScreen(reminderId);
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
      } else if (call.arguments is String) {
        reminderId = int.tryParse(call.arguments as String);
      }

      if (reminderId != null) {
        print('   🚀 화면 이동 시작...');
        await _navigateToNotificationScreen(reminderId);
        print('   ✅ 화면 이동 완료!');
      }
    } else if (call.method == 'updateAppState') {
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

  // 🔥 화면 이동 로직 (중복 방지 강화)
  static Future<void> _navigateToNotificationScreen(int reminderId) async {
    // 🔥 타임아웃 체크 강화
    if (_isHandlingNotification) {
      final now = DateTime.now();
      if (_lastHandlingTime != null &&
          now.difference(_lastHandlingTime!).inSeconds < 3) {
        // 5초 → 3초로 감소
        print('⚠️  이미 화면 이동 중 - 무시');
        return;
      } else {
        print('⚠️  플래그 강제 리셋 (타임아웃)');
        _isHandlingNotification = false;
      }
    }

    try {
      _isHandlingNotification = true;
      _lastHandlingTime = DateTime.now(); // 🔥 시간 기록
      print('   🚀 NotificationScreen으로 이동: reminderId=$reminderId');

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
        print('   ✅ 화면 이동 완료!');
      } else {
        print('   ❌ navigatorKey.currentState가 null입니다!');
      }
    } catch (e) {
      print('   ❌ 화면 이동 실패: $e');
    } finally {
      // 🔥 finally로 확실하게 플래그 리셋
      await Future.delayed(Duration(milliseconds: 500)); // 300ms → 500ms로 증가
      _isHandlingNotification = false;
      print('   🔓 플래그 리셋 완료');
    }
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

  // 🔥 10분 후 알림 예약 함수
  static Future<void> scheduleTenMinutesLater(int reminderId) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏰ 10분 후 알림 예약: $reminderId');

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(Duration(minutes: 10));

      print('   예약 시간: $scheduledDate');

      await _notifications.zonedSchedule(
        reminderId,
        '약 먹을 시간이에요!',
        '10분 전에 미룬 알림입니다',
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

      print('✅ 10분 후 알림 예약 완료!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 10분 후 알림 예약 실패: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
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
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm_sound.wav',
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
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm_sound.wav',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );
    
    print('✅ 리마인더 알림 예약: ${scheduledDate.toString()}');
  }

  /// 스누즈 알림 (10분 후)
  static Future<void> snoozeNotification(
    int reminderId,
    int delayMinutes,
  ) async {
    final reminder = await DatabaseHelper.getReminderById(reminderId);
    if (reminder == null) return;
    
    final scheduledDate = DateTime.now().add(Duration(minutes: delayMinutes));
    
    await _notifications.zonedSchedule(
      reminderId + 30000, // 스누즈용 고유 ID
      '약 먹을 시간이에요!',
      '${reminder.title} - 다시 알려드립니다',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'snooze_channel',
          'Snooze Notifications',
          channelDescription: 'Snooze notification channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm_sound.wav',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminderId.toString(),
    );
    
    print('✅ 스누즈 알림 예약: ${scheduledDate.toString()}');
  }
}
