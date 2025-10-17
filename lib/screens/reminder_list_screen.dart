
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../widgets/reminder_card.dart';
import 'reminder_detail_screen.dart';
import 'notification_screen.dart';
import 'manual_record_screen.dart';

class ReminderListScreen extends StatefulWidget {
  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> with TickerProviderStateMixin {
  List<Reminder> reminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.getAllReminders();
    setState(() {
      reminders = data;
      isLoading = false;
    });
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await DatabaseHelper.deleteReminder(reminder.id!);
    _loadReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reminder.title} 알림이 삭제되었습니다'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _goToDetail(BuildContext context, {Reminder? reminder}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminder),
      ),
    );
    _loadReminders();
  }

  // 🔥 테스트 알림 열기 (무조건 첫 번째 알림 사용)
  void _openTestNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          reminderId: null, // null이면 자동으로 첫 번째 알림 사용
        ),
      ),
    );
  }

  void _goToManualRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualRecordScreen(),
      ),
    );
  }

  // 🔥 액션 버튼 2개 (알림 추가 + 수동 기록)
  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 알림 추가 버튼 (70%)
          Expanded(
            flex: 7,
            child: ElevatedButton.icon(
              onPressed: () => _goToDetail(context),
              icon: Icon(Icons.add, size: 22),
              label: Text(
                '알림 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1C2D5A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // 수동 기록 버튼 (30%)
          Expanded(
            flex: 3,
            child: OutlinedButton.icon(
              onPressed: _goToManualRecord,
              icon: Icon(Icons.edit_note, size: 22),
              label: Text(
                '수동',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF1C2D5A),
                side: BorderSide(color: Color(0xFF1C2D5A), width: 2),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 앱바 (깔끔하게 제목만)
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF1C2D5A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1C2D5A),
                      Color(0xFF2A3F6F),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              '약 챙겨 먹었니',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.medication, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '총 ${reminders.length}개의 알림',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
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

          // 🔥 액션 버튼 영역 (고정)
          SliverToBoxAdapter(
            child: _buildActionButtons(),
          ),

          // 로딩 중
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1C2D5A)),
                    SizedBox(height: 16),
                    Text('알림을 불러오는 중...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          
          // 알림 없음
          else if (reminders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      '등록된 알림이 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '위의 "알림 추가" 버튼을 눌러\n첫 알림을 추가하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          
          // 알림 리스트
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reminder = reminders[index];
                    return Dismissible(
                      key: Key(reminder.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('알림 삭제'),
                            content: Text('${reminder.title} 알림을 삭제하시겠습니까?'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) => _deleteReminder(reminder),
                      child: Hero(
                        tag: 'reminder_${reminder.id}',
                        child: ReminderCard(
                          reminder: reminder,
                          onTap: () => _goToDetail(context, reminder: reminder),
                          onToggle: (value) async {
                            final updated = Reminder(
                              id: reminder.id,
                              title: reminder.title,
                              amPm: reminder.amPm,
                              hour: reminder.hour,
                              minute: reminder.minute,
                              repeatHour: reminder.repeatHour,
                              repeatMinute: reminder.repeatMinute,
                              isEnabled: value,
                              createdAt: reminder.createdAt,
                            );
                            await DatabaseHelper.updateReminder(updated);
                            _loadReminders();
                          },
                        ),
                      ),
                    );
                  },
                  childCount: reminders.length,
                ),
              ),
            ),
        ],
      ),
      // 🔥 테스트 버튼만 플로팅으로 (개발용)
      floatingActionButton: FloatingActionButton(
        onPressed: _openTestNotification,
        backgroundColor: Colors.orange,
        child: Icon(Icons.notifications_active, color: Colors.white),
        elevation: 4,
      ),
    );
  }
}
