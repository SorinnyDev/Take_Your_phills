
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';

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
      // 수정 모드
      titleController = TextEditingController(text: widget.reminder!.title);
      amPm = widget.reminder!.amPm;
      hour = widget.reminder!.hour;
      minute = widget.reminder!.minute;
      repeatHour = widget.reminder!.repeatHour;
      repeatMinute = widget.reminder!.repeatMinute;
      isEnabled = widget.reminder!.isEnabled;
    } else {
      // 생성 모드
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알림 제목을 입력해주세요'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.reminder == null) {
      _createReminder();
    } else {
      _updateReminder();
    }
  }

  void _createReminder() async {
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
    Navigator.pop(context);
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Color(0xFF1C2D5A),
      textColor: Colors.white,
      fontSize: 16.0,
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
            // 제목 입력
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
            _buildSectionTitle('알림 시간'),
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
                  // AM/PM 선택
                  _buildTimePicker(
                    label: 'AM/PM',
                    value: amPm,
                    items: ['AM', 'PM'],
                    onChanged: (value) => setState(() => amPm = value!),
                  ),

                  // 시간 선택
                  _buildTimePicker(
                    label: '시',
                    value: hour.toString(),
                    items: List.generate(12, (i) => (i + 1).toString()),
                    onChanged: (value) => setState(() => hour = int.parse(value!)),
                  ),

                  // 분 선택
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

            // 반복 간격 설정
            _buildSectionTitle('반복 간격'),
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
                  // 시간 간격
                  _buildTimePicker(
                    label: '시간',
                    value: repeatHour.toString(),
                    items: List.generate(24, (i) => i.toString()),
                    onChanged: (value) => setState(() => repeatHour = int.parse(value!)),
                  ),

                  // 분 간격
                  _buildTimePicker(
                    label: '분',
                    value: repeatMinute.toString(),
                    items: List.generate(60, (i) => i.toString()),
                    onChanged: (value) => setState(() => repeatMinute = int.parse(value!)),
                  ),
                ],
              ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1C2D5A),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              dropdownColor: Colors.white,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
