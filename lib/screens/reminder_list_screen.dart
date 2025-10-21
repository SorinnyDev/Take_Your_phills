
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';
import '../widgets/reminder_card.dart';
import 'reminder_detail_screen.dart';
import 'manual_record_screen.dart';
import 'notification_screen.dart';

class ReminderListScreen extends StatefulWidget {
  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
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

  void _goToDetail(BuildContext context, {Reminder? reminder}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminder),
      ),
    );
    _loadReminders();
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

  // 🔥 1분 후 실제 알림 예약
  Future<void> _scheduleOneMinuteNotification() async {
    if (reminders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('먼저 알림을 추가해주세요!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final firstReminder = reminders.first;
    
    // 🔥 1분 후 알림 예약 (reminderId 전달)
    await NotificationHelper.scheduleOneMinuteNotification(firstReminder.id!);
    
    // 사용자에게 피드백
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '1분 후 알림이 울립니다! 🔔',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    
    // 예약된 알림 목록 출력 (디버깅용)
    final pending = await NotificationHelper.getPendingNotifications();
    print('📋 예약된 알림 개수: ${pending.length}');
    for (var notification in pending) {
      print('  - ID: ${notification.id}, 제목: ${notification.title}');
    }
  }

  // 🔥 즉시 알림 테스트 - 바로 화면 이동
  Future<void> _showImmediateTestNotification() async {
    if (reminders.isNotEmpty) {
      final firstReminder = reminders.first;
      
      // 알림 화면으로 바로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
            reminderId: firstReminder.id!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '먼저 알림을 추가해주세요!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: '추가하기',
            textColor: Colors.white,
            onPressed: () => _goToDetail(context),
          ),
        ),
      );
    }
  }

  void _goToManualRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualRecordScreen(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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

          SliverToBoxAdapter(
            child: _buildActionButtons(),
          ),

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
      // 🔥 플로팅 버튼을 2개로 변경
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 즉시 알림 버튼
          FloatingActionButton.extended(
            onPressed: _showImmediateTestNotification,
            backgroundColor: Colors.blue,
            heroTag: 'immediate',
            icon: Icon(Icons.notifications_active, color: Colors.white),
            label: Text(
              '즉시',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // 1분 후 알림 버튼
          FloatingActionButton.extended(
            onPressed: _scheduleOneMinuteNotification,
            backgroundColor: Colors.orange,
            heroTag: '1min',
            icon: Icon(Icons.alarm_add, color: Colors.white),
            label: Text(
              '1분 후',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
