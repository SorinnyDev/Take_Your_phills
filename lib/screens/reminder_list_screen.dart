
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../widgets/reminder_card.dart';
import 'reminder_detail_screen.dart';
import 'notification_screen.dart';
import 'manual_record_screen.dart';

class ReminderListScreen extends StatefulWidget {
  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> with TickerProviderStateMixin {
  List<Reminder> reminders = [];
  bool isLoading = true;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
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
        backgroundColor: Colors.red,
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

  void _openTestNotification() {
    if (reminders.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(),
        ),
      );
    } else {
      final testReminder = reminders.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
            title: testReminder.title,
            time: '${testReminder.amPm} ${testReminder.hour}:${testReminder.minute.toString().padLeft(2, '0')}',
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
                      '+ 버튼을 눌러 첫 알림을 추가하세요',
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 알림 추가 버튼
          ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fabController,
                curve: Curves.elasticOut,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () => _goToDetail(context),
              backgroundColor: Color(0xFF1C2D5A),
              child: Icon(Icons.add, color: Colors.white),
              elevation: 4,
              heroTag: 'add_button',
            ),
          ),
          SizedBox(height: 16),
          // 테스트 알림 버튼
          FloatingActionButton(
            onPressed: _openTestNotification,
            backgroundColor: Colors.orange,
            child: Icon(Icons.notifications_active, color: Colors.white),
            elevation: 4,
            heroTag: 'test_button',
          ),
          SizedBox(height: 16),
          // 수동 기록 버튼
          FloatingActionButton(
            onPressed: _goToManualRecord,
            backgroundColor: Colors.blue,
            child: Icon(Icons.edit_note, color: Colors.white),
            elevation: 4,
            heroTag: 'manual_button',
          ),
        ],
      ),
    );
  }
}
