import 'package:flutter/material.dart';
import '../models/medication_record.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';

class HistoryTab extends StatefulWidget {
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<MedicationRecord> _records = [];
  Map<int, Reminder> _reminders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, now.day);

      final records = await DatabaseHelper.getMedicationRecords(
        startDate: startDate,
        endDate: now,
      );

      final allReminders = await DatabaseHelper.getAllReminders();
      final reminderMap = <int, Reminder>{};
      for (var reminder in allReminders) {
        reminderMap[reminder.id!] = reminder;
      }

      setState(() {
        _records = records;
        _reminders = reminderMap;
        _isLoading = false;
      });

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📜 히스토리 데이터 로드 완료');
      print('   - 총 기록: ${records.length}개');
      print('   - 리마인더: ${allReminders.length}개');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1C2D5A)),
            SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              '아직 복용 기록이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '약을 복용하면 여기에 기록이 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    // 날짜별로 그룹화
    final groupedRecords = <String, List<MedicationRecord>>{};
    for (var record in _records) {
      final dateKey =
          '${record.scheduledTime.year}-${record.scheduledTime.month}-${record.scheduledTime.day}';
      if (!groupedRecords.containsKey(dateKey)) {
        groupedRecords[dateKey] = [];
      }
      groupedRecords[dateKey]!.add(record);
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: Color(0xFF1C2D5A),
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final records = groupedRecords[dateKey]!;

          return _buildDateGroup(dateKey, records, index);
        },
      ),
    );
  }

  Widget _buildDateGroup(
      String dateKey, List<MedicationRecord> records, int index) {
    final parts = dateKey.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = '오늘';
    } else if (date == yesterday) {
      dateLabel = '어제';
    } else {
      dateLabel = '${date.month}월 ${date.day}일';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 날짜 라벨 (기존 스타일)
        Padding(
          padding:
              EdgeInsets.only(left: 4, bottom: 12, top: index == 0 ? 0 : 24),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2D5A),
            ),
          ),
        ),
        ...records.map((record) => _buildHistoryItem(record)).toList(),
      ],
    );
  }

  Widget _buildHistoryItem(MedicationRecord record) {
    final reminder = _reminders[record.reminderId];
    final medicationName = reminder?.title ?? '알 수 없음';

    // 상태별 색상 및 아이콘
    Color bgColor;
    Color iconColor;
    IconData icon;
    String statusText;

    switch (record.status) {
      case 'taken':
        bgColor = Colors.green[100]!;
        iconColor = Colors.green[700]!;
        icon = Icons.check_circle;
        statusText = '복용 완료';
        break;
      case 'skipped':
        bgColor = Colors.orange[100]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.skip_next;
        statusText = '건너뜀';
        break;
      case 'missed':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.cancel;
        statusText = '놓침';
        break;
      default:
        bgColor = Colors.grey[100]!;
        iconColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        statusText = record.status;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 상태 아이콘
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          SizedBox(width: 16),

          // 약 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicationName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      '${record.scheduledTime.hour.toString().padLeft(2, '0')}:${record.scheduledTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 복용 시간 (복용 완료인 경우만)
          if (record.status == 'taken' && record.takenAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '복용',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  '${record.takenAt!.hour.toString().padLeft(2, '0')}:${record.takenAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
