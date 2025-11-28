import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';

class NotificationScreenWhite extends StatefulWidget {
  final int reminderId;

  const NotificationScreenWhite({
    Key? key,
    required this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreenWhite> createState() => _NotificationScreenWhiteState();
}

class _NotificationScreenWhiteState extends State<NotificationScreenWhite> {
  Reminder? _reminder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    NotificationHelper.cancelNotification(widget.reminderId);
  }

  Future<void> _loadReminder() async {
    try {
      final reminder = await DatabaseHelper.getReminderById(widget.reminderId);
      if (mounted) {
        setState(() {
          _reminder = reminder;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Reminder 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFormattedTime() {
    if (_reminder == null) return '';
    return '${_reminder!.amPm} ${_reminder!.hour}:${_reminder!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1C2D5A)),
        ),
      );
    }

    if (_reminder == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  '알림 데이터를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1C2D5A),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 아이콘 컨테이너 - 그라데이션 추가
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1C2D5A).withOpacity(0.2),
                      Color(0xFF1C2D5A).withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication,
                  size: 80,
                  color: Color(0xFF1C2D5A),
                ),
              ),
              SizedBox(height: 32),
              Text(
                '약 먹을 시간이에요!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2D5A),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF1C2D5A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _reminder!.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C2D5A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 20),
              Text(
                _getFormattedTime(),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              Spacer(),
              Column(
                children: [
                  // 복용 완료 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_reminder?.id != null) {
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
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1C2D5A),
                        foregroundColor: Colors.white,
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

                  // 10분 후 알림 & 내일 다시 알림 버튼
                  Row(
                    children: [
                      // 10분 후 알림 버튼
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () async {
                              await NotificationHelper.scheduleTenMinutesLater(_reminder!.id!);
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
                              foregroundColor: Color(0xFF1C2D5A),
                              side: BorderSide(
                                  color: Color(0xFF1C2D5A), width: 2),
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
                              if (_reminder?.id != null) {
                                await NotificationHelper.markAsSkipped(_reminder!.id!);
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
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF1C2D5A),
                              side: BorderSide(
                                  color: Colors.grey.withOpacity(0.7),
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

                  // 닫기 버튼 (2시간 후 리마인더 예약)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('2시간 후 다시 확인할게요'),
                          backgroundColor: Colors.grey[700],
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      '닫기 (나중에 확인)',
                      style: TextStyle(
                        color: Colors.grey[600],
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
    );
  }
}
