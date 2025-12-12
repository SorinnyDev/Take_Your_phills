
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/medication_record.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';

class ManualRecordScreen extends StatefulWidget {
  @override
  State<ManualRecordScreen> createState() => _ManualRecordScreenState();
}

class _ManualRecordScreenState extends State<ManualRecordScreen> {
  List<Reminder> _reminders = [];
  Reminder? _selectedReminder;
  DateTime? _selectedScheduleTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final data = await DatabaseHelper.getAllReminders();
    setState(() {
      _reminders = data;
      _isLoading = false;
    });
  }

  // 🔥 선택된 약의 오늘 스케줄 가져오기
  Future<List<Map<String, dynamic>>> _getTodaySchedules() async {
    if (_selectedReminder == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final schedules = <Map<String, dynamic>>[];
    DateTime currentTime = DateTime(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
      _selectedReminder!.hour,
      _selectedReminder!.minute,
    );

    if (currentTime.isBefore(startOfDay)) {
      currentTime = currentTime.add(Duration(days: 1));
    }

    while (currentTime.isBefore(endOfDay)) {
      // 🔥 복용 기록 확인
      final existingRecord = await DatabaseHelper.getMedicationRecordBySchedule(
        reminderId: _selectedReminder!.id!,
        scheduledTime: currentTime,
      );

      schedules.add({
        'time': currentTime,
        'isPast': currentTime.isBefore(now),
        'isTaken': existingRecord != null,
      });

      if (_selectedReminder!.repeatHour > 0 || _selectedReminder!.repeatMinute > 0) {
        currentTime = currentTime.add(Duration(
          hours: _selectedReminder!.repeatHour,
          minutes: _selectedReminder!.repeatMinute,
        ));
      } else {
        break;
      }
    }

    return schedules;
  }

  Future<void> _saveRecord() async {
    if (_selectedReminder == null || _selectedScheduleTime == null) return;

    // 🔥 중복 체크
    final existingRecord = await DatabaseHelper.getMedicationRecordBySchedule(
      reminderId: _selectedReminder!.id!,
      scheduledTime: _selectedScheduleTime!,
    );

    if (existingRecord != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Text('중복 기록'),
              ],
            ),
            content: Text(
              '이미 이 시간대에 복용 기록이 있습니다.\n그래도 저장하시겠습니까?',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performSave();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1C2D5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('저장'),
              ),
            ],
          ),
        );
      }
      return;
    }

    await _performSave();
  }

  Future<void> _performSave() async {
    if (_selectedReminder == null || _selectedScheduleTime == null) return;

    await DatabaseHelper.insertMedicationRecord(
      reminderId: _selectedReminder!.id!,
      scheduledTime: _selectedScheduleTime!,
      takenAt: DateTime.now(),
      status: 'taken',
      note: 'Manual record',
    );

    await NotificationHelper.scheduleNextNotification(_selectedReminder!.id!);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedReminder!.title} 복용 기록 완료!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$period $hour:$minute';
  }

  String _getTimeDifference(DateTime scheduledTime) {
    final now = DateTime.now();
    final diff = now.difference(scheduledTime); // 🔥 순서 변경: 현재 - 스케줄

    if (diff.isNegative) {
      // 🔥 현재 시간이 스케줄보다 이전 = 일찍 복용
      final absDiff = diff.abs();
      if (absDiff.inHours > 0) {
        return '${absDiff.inHours}시간 ${absDiff.inMinutes % 60}분 일찍 복용';
      } else {
        return '${absDiff.inMinutes}분 일찍 복용';
      }
    } else {
      // 🔥 현재 시간이 스케줄보다 이후 = 늦게 복용
      if (diff.inHours > 0) {
        return '${diff.inHours}시간 ${diff.inMinutes % 60}분 늦게 복용';
      } else {
        return '${diff.inMinutes}분 늦게 복용';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '복용 기록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1C2D5A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            '등록된 알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '먼저 알림을 추가해주세요',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 1. 복용 시간 카드
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1C2D5A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '복용 시간',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(DateTime.now()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔥 2. 약 선택 섹션
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '어떤 약을 드셨나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),

        SizedBox(height: 16),

        // 🔥 3. 약 목록 (라디오 버튼 스타일)
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            final isSelected = _selectedReminder?.id == reminder.id;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF1C2D5A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Color(0xFF1C2D5A) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedReminder = reminder;
                    _selectedScheduleTime = null;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(0xFF1C2D5A)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check,
                          color: isSelected ? Colors.white : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 32),

        // 🔥 4. 스케줄 선택 섹션 (선택된 약이 있을 때만 표시)
        if (_selectedReminder != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '복용 시간 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getTodaySchedules(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('오류 발생: ${snapshot.error}');
                    }

                    final schedules = snapshot.data ?? [];

                    if (schedules.isEmpty) {
                      return Text('스케줄이 없습니다.');
                    }

                    return Column(
                      children: schedules.map((schedule) {
                        final time = schedule['time'] as DateTime;
                        final isPast = schedule['isPast'] as bool;
                        final isTaken = schedule['isTaken'] as bool;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isTaken
                                ? Colors.green[100]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTaken
                                  ? Colors.green
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedScheduleTime = time;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _selectedScheduleTime == time
                                          ? Color(0xFF1C2D5A)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: _selectedScheduleTime == time
                                          ? Colors.white
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatTime(time),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedScheduleTime == time
                                                ? Color(0xFF1C2D5A)
                                                : Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _getTimeDifference(time),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isPast
                                                ? Colors.red
                                                : Colors.green,
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
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

        SizedBox(height: 32),

        // 🔥 5. 저장 버튼
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedReminder != null && _selectedScheduleTime != null
                  ? _saveRecord
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1C2D5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                '복용 기록하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
