import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'helpers/notification_helper.dart';
import 'helpers/database_helper.dart';
import 'screens/main_screen.dart';

Future<void> _rescheduleAllNotifications() async {
  await NotificationHelper.rescheduleAllNotifications();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 타임존 초기화
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 🔥 앱 시작 후 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationHelper.initialize(context);
      await _rescheduleAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Take Your Pills',
      navigatorKey: NotificationHelper.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppLifecycleWrapper(child: MainScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ 앱 포그라운드 진입');
        NotificationHelper.updateAppState(true);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        break;
      case AppLifecycleState.paused:
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('⏸️ 앱 백그라운드 진입');
        NotificationHelper.updateAppState(false);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
