
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';

class NotificationScreenBlue extends StatefulWidget {
  final int reminderId;

  const NotificationScreenBlue({
    Key? key,
    required this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreenBlue> createState() => _NotificationScreenBlueState();
}

class _NotificationScreenBlueState extends State<NotificationScreenBlue> {
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
        backgroundColor: Color(0xFF1C2D5A), // 🔥 기존 색상
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_reminder == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1C2D5A), // 🔥 기존 색상
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
                    foregroundColor: Color(0xFF1C2D5A), // 🔥 기존 색상
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
      backgroundColor: Color(0xFF1C2D5A), // 🔥 기존 색상
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Container(
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
                ),
              ),
              SizedBox(height: 20),
              Text(
                _getFormattedTime(),
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    await NotificationHelper.markAsTaken(widget.reminderId);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('복용 완료!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF1C2D5A), // 🔥 기존 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '복용 완료',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    await NotificationHelper.scheduleSnooze(widget.reminderId);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('10분 후 다시 알려드릴게요'),
                          backgroundColor: Colors.orange,
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
                  child: Text(
                    '10분 후',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await NotificationHelper.scheduleNextNotification(widget.reminderId);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  '닫기',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
