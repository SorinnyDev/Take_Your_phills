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

class _NotificationScreenBlueState extends State<NotificationScreenBlue>
    with SingleTickerProviderStateMixin {
  // 🔥 애니메이션 믹스인 추가

  Reminder? _reminder;
  bool _isLoading = true;

  // 🔥 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 🔥 애니메이션 초기화
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _loadReminder();
  }

  @override
  void dispose() {
    _fadeController.dispose(); // 🔥 컨트롤러 해제
    super.dispose();
  }

  Future<void> _loadReminder() async {
    try {
      final reminder = await DatabaseHelper.getReminderById(widget.reminderId);
      setState(() {
        _reminder = reminder;
        _isLoading = false;
      });

      // 🔥 데이터 로딩 완료 후 애니메이션 시작
      if (reminder != null) {
        _fadeController.forward();
      }
    } catch (e) {
      print('❌ 알림 데이터 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getFormattedTime() {
    if (_reminder == null) return '';
    return '${_reminder!.amPm} ${_reminder!.hour}:${_reminder!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _scheduleTestNotification() async {
    await NotificationHelper.scheduleTestNotification(
      _reminder!.id!,
      _reminder!.title,
      10,
    );
  }

  Future<void> _scheduleReminderNotification() async {
    await NotificationHelper.scheduleReminderNotification(
      _reminder!.id!,
      _reminder!.title,
      120,
    );
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

    // 🔥 정상 화면 (애니메이션 적용)
    return Scaffold(
      backgroundColor: Color(0xFF1C2D5A),
      body: SafeArea(
        child: FadeTransition(
          // 🔥 페이드 애니메이션
          opacity: _fadeAnimation,
          child: SlideTransition(
            // 🔥 슬라이드 애니메이션
            position: _slideAnimation,
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

                        // 🔥 알림 아이콘 (스케일 애니메이션 추가)
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve:
                                  Interval(0.0, 0.5, curve: Curves.elasticOut),
                            ),
                          ),
                          child: Container(
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
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
                                  await NotificationHelper.markAsTaken(
                                      _reminder!.id!);

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
                                        await NotificationHelper
                                            .snoozeNotification(
                                          _reminder!.id!,
                                          10,
                                        );

                                        if (mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
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
                                        side: BorderSide(
                                            color: Colors.white, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await NotificationHelper
                                            .scheduleNextNotification(
                                          _reminder!.id!,
                                        );

                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                            color: Colors.white, width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                              fontSize: 16,
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

                            // 닫기 버튼
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
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
                      ],
                    ),
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
