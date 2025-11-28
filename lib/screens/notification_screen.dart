
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🗂️ 백업용 파일 (현재 사용 안 함)
// 
// 현재는 notification_screen_blue.dart와 notification_screen_white.dart를 사용합니다.
// 이 파일은 참고용으로만 보관하며, 추후 삭제 예정입니다.
// 
// 사용 중인 파일:
// - lib/screens/notification_screen_blue.dart  (파란색 테마)
// - lib/screens/notification_screen_white.dart (흰색 테마)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart'; // 🔥 추가!

class NotificationScreen extends StatefulWidget {
  final int reminderId;

  const NotificationScreen({
    Key? key,
    required this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Reminder? _reminder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    
    // 🔥 화면 진입 시 알림 취소
    NotificationHelper.cancelNotification(widget.reminderId);
  }

  Future<void> _loadReminder() async {
    try {
      final allReminders = await DatabaseHelper.getAllReminders();

      if (allReminders.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Reminder? targetReminder = allReminders.firstWhere(
        (r) => r.id == widget.reminderId,
        orElse: () => allReminders.first,
      );

      setState(() {
        _reminder = targetReminder;
        _isLoading = false;
      });
    } catch (e) {
      print('알림 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFormattedTime() {
    if (_reminder == null) return '';
    
    final hour = _reminder!.hour.toString().padLeft(2, '0');
    final minute = _reminder!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 🔥 2시간 후 리마인더 알림 예약
  Future<void> _scheduleReminderNotification() async {
    if (_reminder == null) return;

    final reminderTime = DateTime.now().add(Duration(hours: 2));
    
    await NotificationHelper.scheduleNotification(
      id: _reminder!.id! + 10000, // 리마인더용 별도 ID
      title: '약 복용 확인',
      body: '${_reminder!.title} - 복용하셨나요?',
      scheduledTime: reminderTime,
      payload: _reminder!.id.toString(),
    );

    print('🔔 2시간 후 리마인더 예약: ${reminderTime.toString()}');
  }

  // 🔥 10초 후 테스트 알림 예약
  Future<void> _scheduleTestNotification() async {
    if (_reminder == null) return;

    final testTime = DateTime.now().add(Duration(seconds: 10));
    
    await NotificationHelper.scheduleNotification(
      id: _reminder!.id! + 20000, // 테스트용 별도 ID
      title: '테스트 알림',
      body: '${_reminder!.title} - 10초 후 테스트',
      scheduledTime: testTime,
      payload: _reminder!.id.toString(),
    );

    print('🔔 10초 후 테스트 알림 예약: ${testTime.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF1C2D5A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // 알림 데이터 없음
    if (_reminder == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1C2D5A),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.white70),
                SizedBox(height: 20),
                Text(
                  '알림 데이터를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF1C2D5A),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🔥 정상 화면
    return Scaffold(
      backgroundColor: Color(0xFF1C2D5A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    SizedBox(height: 24),

                    // 알림 아이콘
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 32),

                    // 제목
                    Text(
                      '약 먹을 시간이에요!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16),

                    // 약 이름
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _reminder!.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: 20),

                    // 시간
                    Text(
                      _getFormattedTime(),
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 20),

                    Spacer(),

                    // 버튼들
                    Column(
                      children: [
                        // 복용 완료 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () async {
                              // 🔥 복용 완료 처리
                              await NotificationHelper.markAsTaken(_reminder!.id!);
                              
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('복용 완료! 다음 스케줄에 알려드릴게요'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF1C2D5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  '복용 완료',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // 10분 후 & 내일 다시 버튼
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    // 🔥 10분 후 알림
                                    await NotificationHelper.snoozeNotification(
                                      _reminder!.id!,
                                      10,
                                    );
                                    
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('10분 후 다시 알려드릴게요'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        '10분 후',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 12),

                            // 내일 다시 알림 버튼
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    // 🔥 내일 같은 시간 알림
                                    await NotificationHelper.scheduleNextDayNotification(
                                      _reminder!.id!,
                                    );
                                    
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('내일 같은 시간에 알려드릴게요'),
                                          backgroundColor: Colors.blue,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.7),
                                        width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        '내일 다시',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // 🔥 테스트용 버튼들 (앱 배포 시 삭제)
                        Row(
                          children: [
                            // 10초 후 알림 테스트 버튼
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await _scheduleTestNotification();
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('테스트: 10초 후 알림 예약됨'),
                                          backgroundColor: Colors.purple,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                        color: Colors.white, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.timer, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        '10초 후 테스트',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: 12),

                            // 즉시 알림 테스트 버튼
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () {
                                    print('테스트: 즉시 알림');
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('테스트: 즉시 알림'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.7),
                                        width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.flash_on, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        '즉시 테스트',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // 닫기 버튼 (2시간 후 리마인더 예약)
                        TextButton(
                          onPressed: () async {
                            await _scheduleReminderNotification();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('2시간 후 다시 확인할게요'),
                                  backgroundColor: Colors.grey[700],
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text(
                            '닫기 (나중에 확인)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
