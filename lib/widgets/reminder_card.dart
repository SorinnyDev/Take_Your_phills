
import 'package:flutter/material.dart';
import '../models/reminder.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final Function(RenderBox) onLongPress;
  final Function(bool) onToggle;

  const ReminderCard({
    Key? key,
    required this.reminder,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
  }) : super(key: key);

  @override
  ReminderCardState createState() => ReminderCardState(); // 🔥 public
}

// 🔥 언더스코어 제거 (public으로 만들기)
class ReminderCardState extends State<ReminderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLongPressed = false; // 🔥 롱프레스 상태 추적

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔥 롱프레스 해제 메서드 (외부에서 호출 가능)
  void resetLongPress() {
    if (_isLongPressed) {
      _controller.reverse();
      setState(() => _isLongPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isLongPressed) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (!_isLongPressed) {
          _controller.reverse();
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!_isLongPressed) {
          _controller.reverse();
        }
      },
      onLongPress: () {
        setState(() => _isLongPressed = true);
        _controller.forward(); // 🔥 확대 시작
        final RenderBox box = context.findRenderObject() as RenderBox;
        widget.onLongPress(box);
      },
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
                color: Colors.black.withOpacity(_isLongPressed ? 0.15 : 0.04),
                blurRadius: _isLongPressed ? 20 : 8,
                offset: Offset(0, _isLongPressed ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 제목 영역
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reminder.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: widget.reminder.isEnabled
                              ? Color(0xFF1C2D5A)
                              : Colors.grey[400],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      Spacer(),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${widget.reminder.amPm} ${widget.reminder.hour}:${widget.reminder.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
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

              // 하단: 정보 영역
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

                    GestureDetector(
                      onTap: () {},
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: widget.reminder.isEnabled,
                          onChanged: widget.onToggle,
                          activeColor: Color(0xFF1C2D5A),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
