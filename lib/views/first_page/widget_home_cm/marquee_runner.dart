import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeRunner extends StatefulWidget {
  final Widget child;
  final int millisecondsPerPixel;
  final Duration pauseDuration;

  const MarqueeRunner({
    Key? key,
    required this.child,
    this.millisecondsPerPixel = 20,
    this.pauseDuration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  _MarqueeRunnerState createState() => _MarqueeRunnerState();
}

class _MarqueeRunnerState extends State<MarqueeRunner> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!mounted || _scrollController.position.maxScrollExtent == 0.0) {
      return; // No overflow, no need to scroll.
    }
    _scheduleScroll();
  }

  void _scheduleScroll() {
    _timer = Timer(widget.pauseDuration, () async {
      if (!mounted) return;
      
      final scrollDuration = Duration(
        milliseconds: (_scrollController.position.maxScrollExtent * widget.millisecondsPerPixel).toInt(),
      );

      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: scrollDuration,
        curve: Curves.linear,
      );

      if (mounted) {
        // When scroll is complete, wait for pause duration then jump back and schedule next scroll
        await Future.delayed(widget.pauseDuration);
        if (mounted) {
           _scrollController.jumpTo(0);
           _scheduleScroll();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        // Use a Row to add a spacer that allows the child to scroll completely off-screen
        child: Row(
          children: [
            widget.child,
            SizedBox(width: constraints.maxWidth),
          ],
        ),
      );
    });
  }
} 