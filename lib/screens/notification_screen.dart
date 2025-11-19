
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helpers/notification_helper.dart';
import '../helpers/database_helper.dart';
import '../models/reminder.dart';

class NotificationScreen extends StatefulWidget {
  final int reminderId;

  const NotificationScreen({
    Key? key,
    required this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _playCount = 0;
  Timer? _vibrationTimer;
  Timer? _autoSnoozeTimer;
  Reminder? _reminder;
  bool _isLoading = true;
  bool _isActionTaken = false; // 🔥 사용자가 버튼을 눌렀는지 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminder();
    _startAlertSound();
    _startAutoSnoozeTimer();
  }

  @override
  void dispose() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🗑️  NotificationScreen dispose 호출');
    
    // 🔥 사용자가 아무 버튼도 안 눌렀으면 자동 스누즈
    if (!_isActionTaken) {
      print('   ⚠️  사용자 액션 없음 → 자동 스누즈 예약');
      NotificationHelper.scheduleSnooze(widget.reminderId);
      
      // 🔥 Toast는 비동기로 표시 (dispose 후에도 작동)
      Future.delayed(Duration.zero, () {
        Fluttertoast.showToast(
          msg: '⏰ 자동 스누즈 (10분 후 다시 알림)',
          toastLength: Toast.LENGTH_LONG,
        );
      });
    } else {
      print('   ✅ 사용자가 액션을 취했음 (복용/스누즈/건너뛰기)');
    }

    _autoSnoozeTimer?.cancel();
    _stopAlertSound();
    WidgetsBinding.instance.removeObserver(this);
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    super.dispose();
  }

  // 🔥 5분 후 자동 스누즈 (백업용)
  void _startAutoSnoozeTimer() {
    _autoSnoozeTimer = Timer(Duration(minutes: 5), () async {
      if (!_isActionTaken && mounted) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('⏰ 5분 타이머 발동 → 자동 스누즈');
        
        _isActionTaken = true; // 🔥 중복 방지
        await NotificationHelper.scheduleSnooze(widget.reminderId);
        
        if (mounted) {
          Navigator.of(context).pop();
          Fluttertoast.showToast(
            msg: '⏰ 자동 스누즈 (10분 후 다시 알림)',
            toastLength: Toast.LENGTH_LONG,
          );
        }
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⏸️  알림 화면 백그라운드 진입');
      print('   → 자동 스누즈 타이머 계속 실행 중...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else if (state == AppLifecycleState.resumed) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('▶️  알림 화면 포그라운드 복귀');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  Future<void> _loadReminder() async {
    final reminder = await DatabaseHelper.getReminderById(widget.reminderId);
    setState(() {
      _reminder = reminder;
      _isLoading = false;
    });
  }

  Future<void> _startVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [0, 500, 200, 500],
        repeat: 0,
      );
    }
  }

  void _stopVibration() {
    Vibration.cancel();
  }

  Future<void> _startAlertSound() async {
    try {
      _isPlaying = true;
      _playCount = 0;

      await _startVibration();

      _vibrationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        if (_playCount < 10 && _isPlaying) {
          await _startVibration();
          _playCount++;
        } else {
          timer.cancel();
          _stopVibration();
        }
      });

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      print('🔔 알림 소리 + 진동 시작');
    } catch (e) {
      print('❌ 알림 소리 재생 실패: $e');
    }
  }

  void _stopAlertSound() {
    _isPlaying = false;
    _audioPlayer.stop();
    _stopVibration();
    _vibrationTimer?.cancel();
    print('🔕 알림 소리 + 진동 중지');
  }

  Future<void> _onTakePressed() async {
    _isActionTaken = true; // 🔥 액션 플래그 설정
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.markAsTaken(widget.reminderId);

    if (mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: '✅ 복용 완료!',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _onSnoozePressed() async {
    if (_reminder == null) return;

    final currentCount = _reminder!.currentSnoozeCount;

    if (currentCount >= 2) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('⚠️ 마지막 스누즈'),
          content: Text(
            '이미 2번 스누즈했습니다.\n'
            '한 번 더 스누즈하면 자동으로 건너뛰기 처리됩니다.\n\n'
            '그래도 스누즈하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('스누즈', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    _isActionTaken = true; // 🔥 액션 플래그 설정
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.scheduleSnooze(widget.reminderId);

    if (mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: '⏰ 10분 후 다시 알림',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _onSkipPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ 건너뛰기'),
        content: Text('이번 복용을 건너뛰시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('건너뛰기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isActionTaken = true; // 🔥 액션 플래그 설정
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.markAsSkipped(widget.reminderId);

    if (mounted) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: '⏭️ 건너뛰기 완료',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_reminder == null) {
      return Scaffold(
        body: Center(
          child: Text('알림을 찾을 수 없습니다'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _stopAlertSound();
        // 🔥 뒤로가기 버튼도 자동 스누즈 처리
        if (!_isActionTaken) {
          _isActionTaken = true;
          await NotificationHelper.scheduleSnooze(widget.reminderId);
          Fluttertoast.showToast(
            msg: '⏰ 자동 스누즈 (10분 후 다시 알림)',
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 상단 닫기 버튼
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, size: 32),
                  onPressed: () {
                    _stopAlertSound();
                    if (!_isActionTaken) {
                      _isActionTaken = true;
                      NotificationHelper.scheduleSnooze(widget.reminderId);
                      Fluttertoast.showToast(
                        msg: '⏰ 자동 스누즈 (10분 후 다시 알림)',
                        toastLength: Toast.LENGTH_LONG,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),

              Spacer(),

              // 알림 아이콘
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication,
                  size: 60,
                  color: Colors.blue,
                ),
              ),

              SizedBox(height: 32),

              // 제목
              Text(
                '💊 약 먹을 시간이에요!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // 약 이름
              Text(
                _reminder!.title,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),

              SizedBox(height: 8),

              // 스누즈 카운트 표시
              if (_reminder!.currentSnoozeCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⏰ 스누즈 ${_reminder!.currentSnoozeCount}/3',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Spacer(),

              // 버튼들
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 복용 완료 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onTakePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '복용 완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // 10분 후 다시 알림 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onSnoozePressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '10분 후 다시 알림',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // 건너뛰기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onSkipPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '건너뛰기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
