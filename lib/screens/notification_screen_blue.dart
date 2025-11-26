import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:take_your_pills/helpers/database_helper.dart';
import 'package:take_your_pills/helpers/notification_helper.dart';
import 'package:take_your_pills/models/reminder.dart';
import 'package:vibration/vibration.dart';

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
  bool _isLoading = true;
  Reminder? _reminder;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _playCount = 0;
  Timer? _vibrationTimer;
  bool _isActionTaken = false;
  Timer? _autoSnoozeTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadReminder();
    if (_reminder != null) {
      _startAlertSound();
      // 1분 후 자동 스누즈 타이머
      _autoSnoozeTimer = Timer(const Duration(minutes: 1), _handleAutoSnooze);
    }
  }

  @override
  void dispose() {
    _stopAlertSound();
    _audioPlayer.dispose();
    _vibrationTimer?.cancel();
    _autoSnoozeTimer?.cancel();
    super.dispose();
  }

  void _handleAutoSnooze() async {
    if (mounted && !_isActionTaken) {
      _isActionTaken = true;
      _stopAlertSound();
      if (_reminder != null) {
        await NotificationHelper.scheduleSnooze(widget.reminderId);
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
    _startVibration();

    _audioPlayer.onPlayerComplete.listen((event) {
      _playCount++;
      if (_isPlaying && _playCount < 100) {
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
  }

  void _onTakePressed() {
    _stopAlertSound();
    if (!_isActionTaken) {
      _isActionTaken = true;
      NotificationHelper.markAsTaken(widget.reminderId);
      Navigator.of(context).pop();
    }
  }

  void _onSnoozePressed() {
    _stopAlertSound();
    if (!_isActionTaken) {
      _isActionTaken = true;
      NotificationHelper.snoozeNotification(widget.reminderId, 10); // 10분 후
      Navigator.of(context).pop();
    }
  }

  // 🔥 [추가] 건너뛰기 처리
  void _onSkipPressed() {
    _stopAlertSound();
    if (!_isActionTaken) {
      _isActionTaken = true;
      NotificationHelper.skipToNextDay(widget.reminderId); // 내일로 건너뛰기
      Navigator.of(context).pop();
    }
  }

  // 🔥 [추가] 닫기 처리 (스누즈와 동일)
  void _onClosePressed() {
    _stopAlertSound();
    if (!_isActionTaken) {
      _isActionTaken = true;
      NotificationHelper.snoozeNotification(widget.reminderId, 120); // 2시간 후
      Navigator.of(context).pop();
    }
  }

  String _getFormattedTime() {
    if (_reminder == null) return '';
    final time = TimeOfDay(hour: _reminder!.hour, minute: _reminder!.minute);
    return time.format(context);
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

    // 정상 화면
    return WillPopScope(
      onWillPop: () async {
        _stopAlertSound();
        if (!_isActionTaken) {
          _handleAutoSnooze();
        }
        return false;
      },
      child: Scaffold(
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              onPressed: _onTakePressed,
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

                          // 10분 후 알림 & 내일 다시 알림 버튼
                          Row(
                            children: [
                              // 10분 후 알림 버튼
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _onSnoozePressed,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    onPressed: _onSkipPressed, // 🔥 수정
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                            onPressed: _onClosePressed, // 🔥 수정
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
      ),
    );
  }
}
