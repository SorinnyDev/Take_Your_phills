
import 'dart:ui'; // 🔥 블러 효과
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart';
import '../widgets/reminder_card.dart';
import 'reminder_detail_screen.dart';
import 'manual_record_screen.dart';
import 'notification_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReminderListScreen extends StatefulWidget {
  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  List<Reminder> reminders = [];
  bool isLoading = true;
  int? _longPressedReminderId; // 🔥 롱프레스된 카드 ID 추적
  final Map<int, GlobalKey<ReminderCardState>> _cardKeys = {}; // 🔥 카드 키 관리

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
      _cardKeys.clear();
      for (var reminder in reminders) {
        _cardKeys[reminder.id!] = GlobalKey<ReminderCardState>();
      }
    });
  }

  void _goToDetail(BuildContext context, {Reminder? reminder}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminder),
      ),
    );
    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await DatabaseHelper.deleteReminder(reminder.id!);
    _loadReminders();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              '${reminder.title} 알림이 삭제되었습니다',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _scheduleTenSecondNotification() async {
    if (reminders.isEmpty) {
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
        ),
      );
      return;
    }

    final firstReminder = reminders.first;
    await NotificationHelper.scheduleTenSecondsNotification(firstReminder.id!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '10초 후 알림이 울립니다! 🔔',
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
  }

  Future<void> _showImmediateTestNotification() async {
    if (reminders.isNotEmpty) {
      final firstReminder = reminders.first;
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

  // 🔥 롱프레스 시 해당 카드 ID 저장
  void _showReminderPopupMenu(BuildContext context, Reminder reminder, RenderBox cardBox) {
    setState(() => _longPressedReminderId = reminder.id); // 🔥 롱프레스된 카드 ID 저장
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final cardPosition = cardBox.localToGlobal(Offset.zero);
    final cardSize = cardBox.size;
    
    final menuPosition = Offset(
      cardPosition.dx + cardSize.width + 8,
      cardPosition.dy + cardSize.height / 2,
    );
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        menuPosition & Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: 120,
        maxWidth: 120,
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          height: 48,
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text(
                '삭제하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      // 🔥 메뉴 닫힐 때 롱프레스 상태 해제
      setState(() => _longPressedReminderId = null);
      _cardKeys[reminder.id]?.currentState?.resetLongPress();
      
      if (value == 'delete') {
        _confirmDelete(context, reminder);
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text('알림 삭제'),
          ],
        ),
        content: Text(
          '${reminder.title} 알림을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(height: 1.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteReminder(reminder);
    }
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF1C2D5A),
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Color(0xFF1C2D5A), width: 2),
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
                    final isLongPressed = _longPressedReminderId == reminder.id;
                    
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
                        child: Opacity(
                          opacity: isLongPressed ? 1.0 : (_longPressedReminderId != null ? 0.3 : 1.0),
                          child: ReminderCard(
                            key: _cardKeys[reminder.id],
                            reminder: reminder,
                            onTap: () => _goToDetail(context, reminder: reminder),
                            onLongPress: (cardBox) {
                              _showReminderPopupMenu(context, reminder, cardBox);
                            },
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
          
          FloatingActionButton.extended(
            onPressed: _scheduleTenSecondNotification,
            backgroundColor: Colors.orange,
            heroTag: '10sec',
            icon: Icon(Icons.alarm_add, color: Colors.white),
            label: Text(
              '10초 후',
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
