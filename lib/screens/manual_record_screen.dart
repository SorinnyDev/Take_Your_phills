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
  bool _isLoading = true;

  // 🔥 현재 시간으로 고정
  final DateTime _takenTime = DateTime.now();

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

  // 🔥 가까운 스케줄 찾기
  List<Map<String, dynamic>> _getNearbySchedules() {
    if (_selectedReminder == null) return [];

    final schedules = _selectedReminder!.calculateDailySchedules(_takenTime);
    final results = <Map<String, dynamic>>[];

    DateTime? before;
    DateTime? after;

    for (var schedule in schedules) {
      if (schedule.isBefore(_takenTime)) {
        before = schedule;
      } else if (schedule.isAfter(_takenTime) && after == null) {
        after = schedule;
        break;
      }
    }

    if (before != null) {
      final diff = _takenTime.difference(before).inMinutes;
      results.add({
        'time': before,
        'label': '${_formatTime(before)} 알림',
        'sublabel': '$diff분 늦게 복용',
        'type': 'before',
      });
    }

    if (after != null) {
      final diff = after.difference(_takenTime).inMinutes;
      results.add({
        'time': after,
        'label': '${_formatTime(after)} 알림',
        'sublabel': '$diff분 일찍 복용',
        'type': 'after',
      });
    }

    return results;
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? '오후' : '오전';
    return '$amPm $hour:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRecord(String scheduleType) async {
    if (_selectedReminder == null) return;

    // 🔥 MedicationRecord 생성 시 scheduledTime 추가!
    await DatabaseHelper.insertMedicationRecord(
      reminderId: _selectedReminder!.id!,
      scheduledTime: _takenTime, // 🔥 추가!
      takenAt: _takenTime,
      status: 'taken',
      note: 'Manual record - Type: $scheduleType',
    );

    // 🔥 다음 알림 예약
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 현재 시간 표시
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C2D5A), Color(0xFF2A3F6F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1C2D5A).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.access_time, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '복용 시간',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTime(_takenTime),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // 약 선택
          Text(
            '어떤 약을 드셨나요?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),

          // 🔥 약 목록 (카드 형태)
          ...(_reminders.map((reminder) {
            final isSelected = _selectedReminder?.id == reminder.id;
            final nearbySchedules = isSelected ? _getNearbySchedules() : [];

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReminder = isSelected ? null : reminder;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF1C2D5A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? Color(0xFF1C2D5A) : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF1C2D5A).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication,
                            color:
                                isSelected ? Colors.white : Color(0xFF1C2D5A),
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${reminder.amPm} ${reminder.hour}:${reminder.minute.toString().padLeft(2, '0')} 시작',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.white : Colors.grey[400],
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔥 선택된 경우 스케줄 옵션 표시
                if (isSelected && nearbySchedules.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              '어떤 알림의 약인가요?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ...nearbySchedules.map((schedule) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _saveRecord(schedule['type']),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        color: Colors.blue[700], size: 18),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            schedule['label'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                          Text(
                                            schedule['sublabel'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
              ],
            );
          }).toList()),
        ],
      ),
    );
  }
}
