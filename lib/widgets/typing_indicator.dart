import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final String senderName;
  final Color? backgroundColor;
  final Color? dotColor;

  const TypingIndicator({
    Key? key,
    required this.senderName,
    this.backgroundColor,
    this.dotColor,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // สร้าง animation สำหรับแต่ละจุด
    _animations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2, // เริ่มต้นที่ 0.0, 0.2, 0.4
            (index * 0.2) + 0.6, // จบที่ 0.6, 0.8, 1.0
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.senderName} กำลังพิมพ์',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: _animations[index].value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.dotColor ?? Colors.grey[500],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
