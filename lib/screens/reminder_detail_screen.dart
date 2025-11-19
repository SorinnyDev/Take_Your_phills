import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../helpers/database_helper.dart';
import '../helpers/notification_helper.dart'; // 🔥 알림 관련 헬퍼 추가

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

  // 🔥 드롭다운 상태 관리
  bool _isIntervalExpanded = false;

  // 🔥 스크롤 컨트롤러 & 드롭다운 키
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _dropdownKey = GlobalKey();

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
      repeatHour = 24; // 🔥 기본값: 하루에 한 번
      repeatMinute = 0;
      isEnabled = true;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥 드롭다운 위치로 자동 스크롤
  void _scrollToDropdown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final dropdownTop = position.dy;
        final screenHeight = MediaQuery.of(context).size.height;

        // 🔥 드롭다운이 화면 하단에 가려지면 스크롤
        if (dropdownTop + 400 > screenHeight) {
          _scrollController.animateTo(
            _scrollController.offset + 200,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _saveReminder() async {
    if (titleController.text.trim().isEmpty) {
      _showToast('약 이름을 입력해주세요');
      return;
    }

    // 🔥 수정 모드인지 확인!
    final isEditMode = widget.reminder != null;

    if (isEditMode) {
      // 🔥 수정 모드: updateReminder 호출
      final updatedReminder = Reminder(
        id: widget.reminder!.id, // 🔥 기존 ID 유지!
        title: titleController.text.trim(),
        amPm: amPm,
        hour: hour,
        minute: minute,
        repeatHour: repeatHour,
        repeatMinute: repeatMinute,
        isEnabled: isEnabled,
        createdAt: widget.reminder!.createdAt, // 🔥 기존 생성 시간 유지!
      );

      await DatabaseHelper.updateReminder(updatedReminder);

      // 🔥 알림 재예약
      if (isEnabled) {
        await NotificationHelper.scheduleNotification(updatedReminder);
      } else {
        await NotificationHelper.cancelNotification(updatedReminder.id!);
      }

      _showToast('알림이 수정되었습니다');
    } else {
      // 🔥 생성 모드: insertReminder 호출
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

      final id = await DatabaseHelper.insertReminder(newReminder);

      // 🔥 알림 예약
      if (isEnabled) {
        final insertedReminder = await DatabaseHelper.getReminderById(id);
        if (insertedReminder != null) {
          await NotificationHelper.scheduleNotification(insertedReminder);
        }
      }

      _showToast('알림이 추가되었습니다');
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
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

  // 🔥 삭제 확인 다이얼로그
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('알림 삭제'),
        content: Text('${widget.reminder!.title} 알림을 삭제하시겠습니까?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteReminder(widget.reminder!.id!);
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context, true); // 상세 화면 닫기 + 목록 새로고침
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('알림이 삭제되었습니다'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
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

  // 🔥 반복 간격 옵션 데이터 (현재 있는 옵션 그대로)
  List<Map<String, dynamic>> get _intervalOptions => [
        {
          'hours': 0,
          'minutes': 0,
          'label': '반복 없음',
          'description': '하루에 한 번만 알림'
        },
        {'hours': 0, 'minutes': 30, 'label': '30분마다', 'description': ''},
        {'hours': 1, 'minutes': 0, 'label': '1시간마다', 'description': ''},
        {'hours': 2, 'minutes': 0, 'label': '2시간마다', 'description': ''},
        {'hours': 3, 'minutes': 0, 'label': '3시간마다', 'description': ''},
        {
          'hours': 4,
          'minutes': 0,
          'label': '4시간마다',
          'description': '타이레놀 등 일반 진통제'
        },
        {
          'hours': 6,
          'minutes': 0,
          'label': '6시간마다',
          'description': '많은 항생제, 소염진통제'
        },
        {
          'hours': 12,
          'minutes': 0,
          'label': '12시간마다',
          'description': '항생제, 항히스타민제'
        },
        {
          'hours': 24,
          'minutes': 0,
          'label': '하루에 한 번',
          'description': '식사 후 복약, 혈압 측정'
        },
        {
          'hours': 48,
          'minutes': 0,
          'label': '2일에 한 번',
          'description': '혈액 검사, 주사'
        },
        {
          'hours': 168,
          'minutes': 0,
          'label': '주에 한 번',
          'description': '정기 검진, 예방접종'
        },
      ];

  // 🔥 현재 선택된 옵션 찾기
  Map<String, dynamic> get _selectedInterval {
    return _intervalOptions.firstWhere(
      (option) =>
          option['hours'] == repeatHour && option['minutes'] == repeatMinute,
      orElse: () => _intervalOptions[8], // 기본값: 하루에 한 번
    );
  }

  // 🔥 인라인 확장형 드롭다운 (구분선 + 자동 스크롤 + 내부 스크롤바 + 외부 클릭 닫기)
  Widget _buildIntervalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 헤더 (항상 표시)
        GestureDetector(
          key: _dropdownKey, // 🔥 위치 추적용 키
          onTap: () {
            setState(() {
              _isIntervalExpanded = !_isIntervalExpanded;
              if (_isIntervalExpanded) {
                _scrollToDropdown(); // 🔥 열릴 때 자동 스크롤
              }
            });
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isIntervalExpanded ? Color(0xFF1C2D5A) : Colors.grey[300]!,
                width: _isIntervalExpanded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedInterval['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (_selectedInterval['description'].isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          _selectedInterval['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 🔥 회전 애니메이션 화살표
                AnimatedRotation(
                  turns: _isIntervalExpanded ? 0.5 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF1C2D5A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔥 확장 영역 (옵션 리스트 + 스크롤바)
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isIntervalExpanded ? 300 : 0,
          child: _isIntervalExpanded
              ? Container(
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true, // 🔥 스크롤바 항상 표시
                    thickness: 6, // 🔥 스크롤바 두께
                    radius: Radius.circular(10), // 🔥 스크롤바 둥글게
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _intervalOptions.length,
                      itemBuilder: (context, index) {
                        final option = _intervalOptions[index];
                        final isSelected = option['hours'] == repeatHour &&
                            option['minutes'] == repeatMinute;

                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                option['label'],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Color(0xFF1C2D5A)
                                      : Colors.grey[800],
                                ),
                              ),
                              subtitle: option['description'].isNotEmpty
                                  ? Text(
                                      option['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                              selected: isSelected,
                              selectedTileColor: Color(0xFF1C2D5A)
                                  .withOpacity(0.05), // 🔥 선택된 항목 배경색
                              onTap: () {
                                setState(() {
                                  repeatHour = option['hours'];
                                  repeatMinute = option['minutes'];
                                  _isIntervalExpanded = false; // 🔥 선택 후 닫기
                                });
                              },
                            ),
                            if (index <
                                _intervalOptions.length -
                                    1) // 🔥 마지막 항목이 아니면 구분선 추가
                              Container(
                                height: 1,
                                color: Colors.grey[200],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.reminder != null;

    return GestureDetector(
      // 🔥 외부 클릭 시 드롭다운 닫기
      onTap: () {
        if (_isIntervalExpanded) {
          setState(() => _isIntervalExpanded = false);
        }
      },
      child: Scaffold(
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
        body: Column(
          children: [
            // 🔥 스크롤 가능한 컨텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 🔥 스크롤 컨트롤러 연결
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
                          borderSide:
                              BorderSide(color: Color(0xFF1C2D5A), width: 2),
                        ),
                        prefixIcon:
                            Icon(Icons.medication, color: Color(0xFF1C2D5A)),
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
                            onChanged: (value) =>
                                setState(() => hour = int.parse(value!)),
                          ),
                          _buildTimePicker(
                            label: '분',
                            value: minute.toString().padLeft(2, '0'),
                            items: List.generate(
                                60, (i) => i.toString().padLeft(2, '0')),
                            onChanged: (value) =>
                                setState(() => minute = int.parse(value!)),
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
                    _buildIntervalDropdown(),

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
                              Icon(Icons.notifications_active,
                                  color: Color(0xFF1C2D5A)),
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
                            onChanged: (value) =>
                                setState(() => isEnabled = value),
                            activeColor: Color(0xFF1C2D5A),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20), // 🔥 하단 버튼 공간 확보
                  ],
                ),
              ),
            ),

            // 🔥 하단 고정 버튼 영역
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: isEditMode
                    ? Row(
                        children: [
                          // 🔥 수정 완료 버튼 (70%)
                          Expanded(
                            flex: 7,
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _saveReminder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1C2D5A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '수정 완료',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          // 🔥 삭제 버튼 (30%)
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _confirmDelete,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
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
                            elevation: 0,
                          ),
                          child: Text(
                            '알림 생성',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
