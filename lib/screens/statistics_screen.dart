
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/medication_record.dart';
import '../models/reminder.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MedicationRecord> _records = [];
  Map<int, Reminder> _reminders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, now.day);
    
    final records = await DatabaseHelper.getMedicationRecords(
      startDate: startDate,
      endDate: now,
    );
    
    final allReminders = await DatabaseHelper.getAllReminders();
    final reminderMap = <int, Reminder>{};
    for (var reminder in allReminders) {
      if (reminder.id != null) {
        reminderMap[reminder.id!] = reminder;
      }
    }
    
    setState(() {
      _records = records;
      _reminders = reminderMap;
      _isLoading = false;
    });
  }

  // 🔥 임시 데이터 생성 (테스트용)
  List<MedicationRecord> _generateDummyData() {
    final now = DateTime.now();
    final dummyRecords = <MedicationRecord>[];
    
    final medicationNames = ['타이레놀', '비타민C', '오메가3', '유산균', '종합비타민'];
    
    for (int day = 0; day < 7; day++) {
      final date = now.subtract(Duration(days: day));
      
      final recordCount = 3 + (day % 3);
      for (int i = 0; i < recordCount; i++) {
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          8 + (i * 4),
          0,
        );
        
        String status;
        final random = (day * 10 + i) % 10;
        if (random < 7) {
          status = 'taken';
        } else if (random < 9) {
          status = 'skipped';
        } else {
          status = 'missed';
        }
        
        dummyRecords.add(
          MedicationRecord(
            reminderId: i + 1,
            scheduledTime: scheduledTime,
            takenAt: status == 'taken' 
                ? scheduledTime.add(Duration(minutes: 5 + (i * 2)))
                : null,
            status: status,
            note: status == 'taken' ? '복용 완료' : null,
          ),
        );
      }
    }
    
    // 🔥 수정: createdAt 파라미터 추가
    for (int i = 1; i <= 5; i++) {
      _reminders[i] = Reminder(
        id: i,
        title: medicationNames[i - 1],
        amPm: 'AM',
        hour: 8 + (i * 2),
        minute: 0,
        repeatHour: 0,
        repeatMinute: 0,
        isEnabled: true,
        createdAt: now.subtract(Duration(days: 7)), // 🔥 필수 파라미터
      );
    }
    
    return dummyRecords;
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Color(0xFF1C2D5A),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 20),
                      SizedBox(width: 8),
                      Text('통계'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 20),
                      SizedBox(width: 8),
                      Text('히스토리'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ========== 통계 탭 ==========
  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSkeletonCompletionCard(),
            SizedBox(height: 20),
            _buildSkeletonTrendCard(),
            SizedBox(height: 20),
            _buildSkeletonAchievementCard(),
          ],
        ),
      );
    }

    final displayRecords = _records.isEmpty ? _generateDummyData() : _records;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_records.isEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '아직 복용 기록이 없어 샘플 데이터를 보여드립니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          _buildTodayCompletionCard(displayRecords),
          SizedBox(height: 20),
          _buildWeeklyTrendCard(),
          SizedBox(height: 20),
          _buildMonthlyAchievementCard(),
          SizedBox(height: 20),
          _buildStreakCard(),
        ],
      ),
    );
  }

  Widget _buildTodayCompletionCard(List<MedicationRecord> records) {
    final today = DateTime.now();
    final todayRecords = records.where((r) {
      return r.scheduledTime.year == today.year &&
             r.scheduledTime.month == today.month &&
             r.scheduledTime.day == today.day;
    }).toList();

    final takenCount = todayRecords.where((r) => r.status == 'taken').length;
    final totalCount = todayRecords.length;
    final percentage = totalCount > 0 ? (takenCount / totalCount * 100).toInt() : 0;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C2D5A),
            Color(0xFF2A3F6F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1C2D5A).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘 복용률',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.today, color: Colors.white70, size: 24),
            ],
          ),
          
          SizedBox(height: 24),
          
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percentage / 100,
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
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$takenCount/$totalCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('복용', takenCount, Colors.white),
              _buildStatItem(
                '건너뜀',
                todayRecords.where((r) => r.status == 'skipped').length,
                Colors.white70,
              ),
              _buildStatItem(
                '놓침',
                todayRecords.where((r) => r.status == 'missed').length,
                Colors.white60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Icon(Icons.check_circle, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendCard() {
    return _buildComingSoonCard(
      '주간 복용 추이',
      Icons.show_chart,
      '최근 7일간의 복용 패턴을 그래프로 보여드릴 예정입니다',
    );
  }

  Widget _buildMonthlyAchievementCard() {
    return _buildComingSoonCard(
      '월간 달성률',
      Icons.calendar_month,
      '이번 달 복용 현황을 캘린더 형태로 보여드릴 예정입니다',
    );
  }

  Widget _buildStreakCard() {
    return _buildComingSoonCard(
      '연속 복용 일수',
      Icons.local_fire_department,
      '연속으로 약을 복용한 날을 기록해드릴 예정입니다',
    );
  }

  Widget _buildComingSoonCard(String title, IconData icon, String description) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF1C2D5A), size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction, size: 16, color: Colors.orange),
                SizedBox(width: 6),
                Text(
                  '개발 중',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 히스토리 탭 ==========
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFF1C2D5A)),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '기록된 복용 내역이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 🔥 날짜별로 그룹화
    final groupedRecords = <String, List<MedicationRecord>>{};
    for (var record in _records) {
      final dateKey = '${record.scheduledTime.year}-${record.scheduledTime.month.toString().padLeft(2, '0')}-${record.scheduledTime.day.toString().padLeft(2, '0')}';
      groupedRecords.putIfAbsent(dateKey, () => []).add(record);
    }

    // 날짜 내림차순 정렬
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final records = groupedRecords[dateKey]!;
        
        return _buildDateGroup(dateKey, records, index); // 🔥 index 파라미터 추가
      },
    );
  }

  Widget _buildDateGroup(String dateKey, List<MedicationRecord> records, int index) {
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
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12, top: index == 0 ? 0 : 20),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 18,
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
    
    // 🔥 상태별 색상 및 아이콘
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

  // 스켈레톤 카드들
  Widget _buildSkeletonCompletionCard() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSkeletonTrendCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSkeletonAchievementCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
