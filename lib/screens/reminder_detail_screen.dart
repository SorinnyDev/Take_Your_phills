
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart'; // 🔥 utils -> helpers로 수정!

class ReminderDetailScreen extends StatefulWidget {
  final Reminder? reminder;

  const ReminderDetailScreen({Key? key, this.reminder}) : super(key: key);

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  late TextEditingController titleController;
  late String amPm;
  late int hour;
  late int minute;
  late int repeatHour;
  late int repeatMinute;
  late bool isEnabled;

  @override
  void initState() {
    super.initState();
    
    if (widget.reminder != null) {
      titleController = TextEditingController(text: widget.reminder!.title);
      amPm = widget.reminder!.amPm;
      hour = widget.reminder!.hour;
      minute = widget.reminder!.minute;
      repeatHour = widget.reminder!.repeatHour;
      repeatMinute = widget.reminder!.repeatMinute;
      isEnabled = widget.reminder!.isEnabled;
    } else {
      titleController = TextEditingController();
      amPm = 'AM';
      hour = 9;
      minute = 0;
      repeatHour = 0;
      repeatMinute = 0;
      isEnabled = true;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void _saveReminder() async {
    if (titleController.text.trim().isEmpty) {
      _showToast('알림 제목을 입력해주세요');
      return;
    }

    if (widget.reminder == null) {
      final newReminder = Reminder(
        title: titleController.text.trim(),
        amPm: amPm,
        hour: hour,
        minute: minute,
        repeatHour: repeatHour,
        repeatMinute: repeatMinute,
        isEnabled: isEnabled,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.insertReminder(newReminder);
      _showToast('알림이 생성되었습니다');
    } else {
      _updateReminder();
    }

    Navigator.pop(context);
  }

  void _updateReminder() async {
    if (widget.reminder == null) return;

    final updatedReminder = Reminder(
      id: widget.reminder!.id,
      title: titleController.text.trim(),
      amPm: amPm,
      hour: hour,
      minute: minute,
      repeatHour: repeatHour,
      repeatMinute: repeatMinute,
      isEnabled: isEnabled,
      createdAt: widget.reminder!.createdAt,
    );

    await DatabaseHelper.updateReminder(updatedReminder);
    _showToast('알림이 수정되었습니다');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            underline: SizedBox(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // 🔥 간격 선택 버튼
  Widget _buildIntervalButton(String label, String description, int hours, int minutes) {
    final isSelected = repeatHour == hours && repeatMinute == minutes;
    
    return InkWell(
      onTap: () {
        setState(() {
          repeatHour = hours;
          repeatMinute = minutes;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1C2D5A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF1C2D5A) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time,
                color: isSelected ? Colors.white : Color(0xFF1C2D5A),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.reminder != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditMode ? '알림 수정' : '알림 생성',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1C2D5A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('알림 제목'),
            SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '예: 아침 약',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF1C2D5A), width: 2),
                ),
                prefixIcon: Icon(Icons.medication, color: Color(0xFF1C2D5A)),
              ),
            ),

            SizedBox(height: 32),

            // 시간 설정
            _buildSectionTitle('시작 시간'),
            SizedBox(height: 8),
            Text(
              '매일 이 시간부터 알림이 시작됩니다',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimePicker(
                    label: 'AM/PM',
                    value: amPm,
                    items: ['AM', 'PM'],
                    onChanged: (value) => setState(() => amPm = value!),
                  ),
                  _buildTimePicker(
                    label: '시',
                    value: hour.toString(),
                    items: List.generate(12, (i) => (i + 1).toString()),
                    onChanged: (value) => setState(() => hour = int.parse(value!)),
                  ),
                  _buildTimePicker(
                    label: '분',
                    value: minute.toString().padLeft(2, '0'),
                    items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                    onChanged: (value) => setState(() => minute = int.parse(value!)),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // 🔥 반복 간격 설정
            _buildSectionTitle('반복 간격'),
            SizedBox(height: 8),
            Text(
              '알림이 반복되는 간격을 선택해주세요',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Column(
              children: [
                _buildIntervalButton('반복 없음', '하루에 한 번만 알림', 0, 0),
                _buildIntervalButton('30분마다', '', 0, 30),
                _buildIntervalButton('1시간마다', '', 1, 0),
                _buildIntervalButton('2시간마다', '', 2, 0),
                _buildIntervalButton('3시간마다', '', 3, 0),
                _buildIntervalButton('4시간마다', '타이레놀 등 일반 진통제', 4, 0),
                _buildIntervalButton('6시간마다', '많은 항생제, 소염진통제', 6, 0),
                _buildIntervalButton('12시간마다', '항생제, 항히스타민제', 12, 0),
                _buildIntervalButton('하루에 한 번', '식사 후 복약, 혈압 측정', 24, 0),
                _buildIntervalButton('2일에 한 번', '혈액 검사, 주사', 48, 0),
                _buildIntervalButton('주에 한 번', '정기 검진, 예방접종', 168, 0),
              ],
            ),

            SizedBox(height: 32),

            // 알림 활성화 스위치
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF1C2D5A)),
                      SizedBox(width: 12),
                      Text(
                        '알림 활성화',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (value) => setState(() => isEnabled = value),
                    activeColor: Color(0xFF1C2D5A),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1C2D5A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEditMode ? '수정 완료' : '알림 생성',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
