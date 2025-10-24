
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'helpers/notification_helper.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  tz.initializeTimeZones();
  await NotificationHelper.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약 챙겨 먹었니',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
      ),
      navigatorKey: NotificationHelper.navigatorKey,
      home: AppLifecycleObserver(child: MainScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 🔥 앱 라이프사이클 관찰 위젯
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  
  AppLifecycleObserver({required this.child});

  @override
  _AppLifecycleObserverState createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver> 
    with WidgetsBindingObserver {
  
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
        print('   ✅ 앱이 포그라운드로 전환됨');
        NotificationHelper.updateAppState(true); // 🔥 추가
        print('   🔍 Navigator 상태: ${NotificationHelper.navigatorKey.currentState}');
        break;
        
      case AppLifecycleState.inactive:
        print('   ⏸️  앱이 비활성 상태');
        break;
        
      case AppLifecycleState.paused:
        print('   ⏸️  앱이 백그라운드로 전환됨');
        NotificationHelper.updateAppState(false); // 🔥 추가
        break;
        
      case AppLifecycleState.detached:
        print('   🛑 앱이 종료됨');
        NotificationHelper.updateAppState(false); // 🔥 추가
        break;
        
      case AppLifecycleState.hidden:
        print('   👻 앱이 숨겨짐');
        break;
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
