
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'helpers/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 시작할 때 DB 데이터 확인
  await DatabaseHelper.printAllData();
  
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
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
