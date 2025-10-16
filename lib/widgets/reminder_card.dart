
import 'package:flutter/material.dart';
import '../models/reminder.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const ReminderCard({
    Key? key,
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRepeatText() {
    if (widget.reminder.repeatHour > 0 && widget.reminder.repeatMinute > 0) {
      return '${widget.reminder.repeatHour}시간 ${widget.reminder.repeatMinute}분';
    } else if (widget.reminder.repeatHour > 0) {
      return '${widget.reminder.repeatHour}시간';
    } else if (widget.reminder.repeatMinute > 0) {
      return '${widget.reminder.repeatMinute}분';
    } else {
      return '한 번만';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 제목 영역 (흰색 배경)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 (굵기 증가)
                      Text(
                        widget.reminder.title,
                        style: TextStyle(
                          fontSize: 22, // 17 → 22 (시간과 교체)
                          fontWeight: FontWeight.bold, // w600 → bold (시간과 교체)
                          color: widget.reminder.isEnabled
                              ? Color(0xFF1C2D5A)
                              : Colors.grey[400],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      Spacer(),
                      
                      // 시간 (오른쪽 정렬, 굵기 감소)
                      Align(
                        alignment: Alignment.centerRight, // 오른쪽 정렬
                        child: Text(
                          '${widget.reminder.amPm} ${widget.reminder.hour}:${widget.reminder.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 17, // 22 → 17 (제목과 교체)
                            fontWeight: FontWeight.w600, // bold → w600 (제목과 교체)
                            color: widget.reminder.isEnabled
                                ? Color(0xFF1C2D5A)
                                : Colors.grey[300],
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단: 정보 영역 (파스텔 배경)
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: widget.reminder.isEnabled
                      ? Color(0xFF1C2D5A).withOpacity(0.04)
                      : Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(19),
                    bottomRight: Radius.circular(19),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 반복 아이콘만 표시
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.reminder.isEnabled
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.reminder.isEnabled
                              ? Color(0xFF1C2D5A).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: widget.reminder.isEnabled
                            ? Color(0xFF1C2D5A)
                            : Colors.grey[400],
                      ),
                    ),

                    // 스위치
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: widget.reminder.isEnabled,
                        onChanged: widget.onToggle,
                        activeColor: Color(0xFF1C2D5A),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
