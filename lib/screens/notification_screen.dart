
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';

class NotificationScreen extends StatefulWidget {
  final int? reminderId;

  const NotificationScreen({
    Key? key,
    this.reminderId,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Reminder? _reminder;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _playCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    _startAlertSound();
  }

  // 🔥 알림 소리 + 진동 시작
  Future<void> _startAlertSound() async {
    try {
      _isPlaying = true;
      _playCount = 0;

      // 1. 진동 시작 (계속 반복)
      _startVibration();

      // 2. 소리 재생 완료 리스너 등록
      _audioPlayer.onPlayerComplete.listen((event) {
        _playCount++;
        print('🔔 재생 완료: $_playCount회');

        if (_playCount < 3 && _isPlaying) {
          // 🔥 3회 미만이면 다시 재생
          _audioPlayer.play(AssetSource('sounds/alarm01.mp3'));
        } else {
          // 🔥 3회 완료 → 소리만 중지, 진동은 계속
          print('🔕 소리 재생 종료 (진동은 유지)');
        }
      });

      // 3. 첫 재생 시작
      await _audioPlayer.play(AssetSource('sounds/alarm01.mp3'));
      
      print('🔔 알림 소리 + 진동 시작 (3회 반복)');
    } catch (e) {
      print('❌ 알림 소리 재생 실패: $e');
    }
  }

  // 🔥 진동 시작 (화면이 열려있는 동안 계속)
  void _startVibration() {
    if (!mounted || !_isPlaying) return;
    
    HapticFeedback.mediumImpact();
    Future.delayed(Duration(seconds: 2), _startVibration);
  }

  // 🔥 소리 + 진동 완전 중지
  Future<void> _stopAlertSound() async {
    _isPlaying = false;
    await _audioPlayer.stop();
    print('🔕 알림 소리 + 진동 완전 중지');
  }

  @override
  void dispose() {
    _stopAlertSound();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 🔥 알림 데이터 로드
  Future<void> _loadReminder() async {
    if (widget.reminderId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final reminder = await DatabaseHelper.getReminderById(widget.reminderId!);
      setState(() {
        _reminder = reminder;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 알림 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 2시간 후 리마인더 노티 예약
  void _scheduleReminderNotification() {
    // TODO: 실제 구현 필요
    print('⏰ 2시간 후 리마인더 예약');
  }

  // 🔥 시간 포맷팅
  String _getFormattedTime() {
    if (_reminder == null) return '--:--';
    
    final hour = _reminder!.hour.toString().padLeft(2, '0');
    final minute = _reminder!.minute.toString().padLeft(2, '0');
    return '${_reminder!.amPm} $hour:$minute';
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

    // 🔥 정상 화면 (GestureDetector로 전체 화면 터치 감지)
    return GestureDetector(
      onTap: () {
        // 🔥 화면 터치 시 소리/진동 멈춤
        if (_isPlaying) {
          _stopAlertSound();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.volume_off, color: Colors.white),
                  SizedBox(width: 12),
                  Text('알림이 중지되었습니다'),
                ],
              ),
              backgroundColor: Colors.grey[700],
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

                      // 🔥 알림 상태 표시 (울리는 중 / 중지됨)
                      if (_isPlaying)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                '화면을 터치하면 알림이 멈춰요',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_off, color: Colors.white70, size: 16),
                              SizedBox(width: 8),
                              Text(
                                '알림이 중지되었습니다',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('복용 완료! 다음 스케줄에 알려드릴게요'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                // TODO: 복용 기록 저장 + 다음 스케줄 예약
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

                          // 10분 후 알림 & 내일 다시 알림 버튼
                          Row(
                            children: [
                              // 10분 후 알림 버튼
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('10분 후 다시 알려드릴게요'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      // TODO: 10분 후 알림 예약
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
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('내일 같은 시간에 알려드릴게요'),
                                          backgroundColor: Colors.blue,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      // TODO: 내일 알림 예약
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withOpacity(0.7), width: 2),
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
                              _scheduleReminderNotification();
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
