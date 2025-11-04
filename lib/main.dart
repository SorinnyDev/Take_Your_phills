
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'helpers/notification_helper.dart';
import 'helpers/database_helper.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 타임존 초기화
  tz.initializeTimeZones();
  
  // 🔥 알림 초기화
  await NotificationHelper.initialize();
  
  // 🔥 앱 시작 시 알림 재예약 (재부팅 대응)
  await _rescheduleAllNotifications();
  
  runApp(MyApp());  // 🔥 AppLifecycleObserver 제거
}

// 🔥 모든 활성화된 알림 재예약
Future<void> _rescheduleAllNotifications() async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🔄 알림 재예약 시작...');
  
  try {
    final reminders = await DatabaseHelper.getAllReminders();
    final enabledReminders = reminders.where((r) => r.isEnabled).toList();
    
    print('📋 활성화된 알림: ${enabledReminders.length}개');
    
    for (var reminder in enabledReminders) {
      await NotificationHelper.scheduleNotification(reminder);
      print('✅ ${reminder.title} 재예약 완료');
    }
    
    print('🎉 알림 재예약 완료!');
  } catch (e) {
    print('❌ 알림 재예약 실패: $e');
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

class MyApp extends StatefulWidget {  // 🔥 StatefulWidget으로 변경
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {  // 🔥 LifecycleObserver 통합
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🎯 AppLifecycleObserver 시작');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 앱 상태 변경: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('✅ 앱 포그라운드 진입 - 알림 재예약 시작');
        _rescheduleAllNotifications();
        break;
        
      case AppLifecycleState.paused:
        print('⏸️ 앱 백그라운드 진입');
        break;
        
      case AppLifecycleState.inactive:
        print('⏸️ 앱 비활성 상태');
        break;
        
      case AppLifecycleState.detached:
        print('🔴 앱 종료 중');
        break;
        
      case AppLifecycleState.hidden:
        print('👻 앱 숨김 상태');
        break;
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Take Your Pills',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      navigatorKey: NotificationHelper.navigatorKey,  // 🔥 추가!
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
