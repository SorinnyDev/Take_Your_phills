import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:take_your_pills/helpers/database_helper.dart';
import 'package:take_your_pills/helpers/notification_helper.dart';
import 'package:take_your_pills/models/reminder.dart';
import 'package:vibration/vibration.dart';

class NotificationScreenWhite extends StatefulWidget {
  final int reminderId;

  const NotificationScreenWhite({
    Key? key,
    required this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreenWhite> createState() =>
      _NotificationScreenWhiteState();
}

class _NotificationScreenWhiteState extends State<NotificationScreenWhite>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _playCount = 0;
  Timer? _vibrationTimer;
  Timer? _autoSnoozeTimer;
  Reminder? _reminder;
  bool _isLoading = true;
  bool _isActionTaken = false;

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
    print('🗑️  NotificationScreenWhite dispose 호출');

    if (!_isActionTaken) {
      print('   ⚠️  사용자 액션 없이 화면 종료 -> 자동 스누즈 처리');
      NotificationHelper.scheduleSnooze(widget.reminderId);
    }

    _autoSnoozeTimer?.cancel();
    _stopAlertSound();
    WidgetsBinding.instance.removeObserver(this);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    super.dispose();
  }

  void _startAutoSnoozeTimer() {
    _autoSnoozeTimer = Timer(const Duration(minutes: 5), () async {
      if (!_isActionTaken && mounted) {
        print('⏰ 5분 자동 스누즈 타이머 발동');
        await _onSnoozePressed();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      if (!_isActionTaken) {
        print('   ⚠️  앱이 백그라운드로 전환됨 -> 자동 스누즈 처리');
        NotificationHelper.scheduleSnooze(widget.reminderId);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _loadReminder() async {
    final reminder = await DatabaseHelper.getReminderById(widget.reminderId);
    if (mounted) {
      setState(() {
        _reminder = reminder;
        _isLoading = false;
      });
    }
  }

  Future<void> _startVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isPlaying) {
          Vibration.vibrate(duration: 500);
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _stopVibration() {
    Vibration.cancel();
    _vibrationTimer?.cancel();
  }

  Future<void> _startAlertSound() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _playCount = 0;
    print('🔔 알림 소리 + 진동 시작');
    _startVibration();

    _audioPlayer.onPlayerComplete.listen((event) {
      _playCount++;
      if (_isPlaying && _playCount < 100) {
        // 최대 100번 반복
        _audioPlayer.play(AssetSource('sounds/alarm_1.mp3'));
      } else {
        _stopAlertSound();
      }
    });
    await _audioPlayer.play(AssetSource('sounds/alarm_1.mp3'));
  }

  void _stopAlertSound() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _audioPlayer.stop();
    _stopVibration();
    print('🔕 알림 소리 + 진동 중지');
  }

  Future<void> _onTakePressed() async {
    if (_isActionTaken) return;
    _isActionTaken = true;
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.markAsTaken(widget.reminderId);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('복용 완료! 다음 스케줄에 알려드릴게요.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _onSnoozePressed() async {
    if (_isActionTaken) return;
    if (_reminder == null) return;

    final currentCount = _reminder!.currentSnoozeCount;

    if (currentCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스누즈는 최대 2번까지만 가능해요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _isActionTaken = true;
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.scheduleSnooze(widget.reminderId);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('5분 뒤에 다시 알려드릴게요.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  Future<void> _onSkipPressed() async {
    if (_isActionTaken) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복용 건너뛰기'),
        content: const Text('이번 약 복용을 건너뛰시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isActionTaken = true;
    _autoSnoozeTimer?.cancel();
    _stopAlertSound();

    await NotificationHelper.markAsSkipped(widget.reminderId);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이번 복용은 건너뛰었어요.'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.grey[800]),
        ),
      );
    }

    if (_reminder == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            '알림을 찾을 수 없습니다',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _stopAlertSound();
        if (!_isActionTaken) {
          _isActionTaken = true;
          await NotificationHelper.scheduleSnooze(widget.reminderId);
        }
        return true;
      },
      child: Scaffold(
        // ⚪ 하얀색 배경
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 상단 닫기 버튼
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, size: 32, color: Colors.grey[800]),
                  onPressed: () {
                    _stopAlertSound();
                    if (!_isActionTaken) {
                      _isActionTaken = true;
                      NotificationHelper.scheduleSnooze(widget.reminderId);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(height: 40),

              // 알림 내용
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 💊 아이콘 추가
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFF1C2D5A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_pharmacy,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),

                    // 약 이름
                    Text(
                      _reminder!.title,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Text(
                      '${_reminder!.hour.toString().padLeft(2, '0')}:${_reminder!.minute.toString().padLeft(2, '0')}에 알림',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 40),

                    // 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ✅ 복용 완료 버튼
                        ElevatedButton.icon(
                          onPressed: _onTakePressed,
                          icon: Icon(Icons.check, size: 30),
                          label: Text(
                            '복용 완료',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        // ⏰ 스누즈 버튼
                        ElevatedButton.icon(
                          onPressed: _onSnoozePressed,
                          icon: Icon(Icons.snooze, size: 30),
                          label: Text(
                            '스누즈',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        // ⏭️ 건너뛰기 버튼
                        ElevatedButton.icon(
                          onPressed: _onSkipPressed,
                          icon: Icon(Icons.skip_next, size: 30),
                          label: Text(
                            '건너뛰기',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF9E9E9E),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
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
