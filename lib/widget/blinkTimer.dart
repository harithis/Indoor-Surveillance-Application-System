import 'dart:async';
import 'package:flutter/material.dart';

class BlinkingTimer extends StatefulWidget {
  const BlinkingTimer({super.key});

  @override
  _BlinkingTimerState createState() => _BlinkingTimerState();
}

class _BlinkingTimerState extends State<BlinkingTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  DateTime currentTime = DateTime.now();
  String timeString = "00:00";
  Timer? timer;

   void getTimer() {
    final DateTime now = DateTime.now();
    Duration d = now.difference(currentTime);

    setState(() {
      timeString =
          "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
    });
  }

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    animationController.repeat();

    timeString = "00:00";
    currentTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => getTimer());
  }

  @override
  void dispose() {
    animationController.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 30,
      decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.all(Radius.circular(5.0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FadeTransition(
            opacity: animationController,
            child: Container(
              width: 20,
              height: 20,
              decoration:
                  const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Text(timeString)
        ],
      ),
    );
  }
}