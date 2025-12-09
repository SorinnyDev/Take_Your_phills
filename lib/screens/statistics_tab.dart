import 'package:flutter/material.dart';
import '../models/medication_record.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';

class StatisticsTab extends StatefulWidget {
  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
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
      print('📊 통계 데이터 로드 완료');
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

    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: Color(0xFF1C2D5A),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTodayCompletionCard(_records),
            SizedBox(height: 20),
            _buildWeeklyTrendCard(),
            SizedBox(height: 20),
            _buildMonthlyAchievementCard(),
            SizedBox(height: 20),
            _buildStreakCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCompletionCard(List<MedicationRecord> records) {
    final today = DateTime.now();
    final todayRecords = records.where((r) {
      final recordDate = r.scheduledTime;
      return recordDate.year == today.year &&
          recordDate.month == today.month &&
          recordDate.day == today.day;
    }).toList();

    final takenCount = todayRecords.where((r) => r.status == 'taken').length;
    final skippedCount =
        todayRecords.where((r) => r.status == 'skipped').length;
    final missedCount = todayRecords.where((r) => r.status == 'missed').length;
    final totalCount = todayRecords.length;
    final percentage =
        totalCount > 0 ? (takenCount / totalCount * 100).toInt() : 0;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C2D5A), Color(0xFF2A4A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1C2D5A).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '오늘의 복용률',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: totalCount > 0 ? takenCount / totalCount : 0,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$takenCount / $totalCount',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('복용', takenCount, Colors.green),
              _buildStatItem('건너뜀', skippedCount, Colors.orange),
              _buildStatItem('놓침', missedCount, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendCard() {
    return _buildComingSoonCard(
      '주간 트렌드',
      Icons.show_chart,
      '지난 7일간의 복용 패턴을 확인하세요',
    );
  }

  Widget _buildMonthlyAchievementCard() {
    return _buildComingSoonCard(
      '월간 달성률',
      Icons.emoji_events,
      '이번 달 목표 달성률을 확인하세요',
    );
  }

  Widget _buildStreakCard() {
    return _buildComingSoonCard(
      '연속 복용 기록',
      Icons.local_fire_department,
      '연속으로 복용한 날짜를 확인하세요',
    );
  }

  Widget _buildComingSoonCard(String title, IconData icon, String description) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
