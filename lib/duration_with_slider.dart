import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationWithSlider extends StatefulWidget {
  const DurationWithSlider({Key? key, required}) : super(key: key);

  @override
  _DurationWithSliderState createState() => _DurationWithSliderState();
}

class _DurationWithSliderState extends State<DurationWithSlider> {
  static const platform = MethodChannel('ws.diye/repeater');

  SendPort? sendPort;
  final ReceivePort receivePort = ReceivePort();
  int currentPosition = 0;
  int recordDuration = 0;
  double _currentSliderValue = 0;
  String currentPositionStr = '00:00';
  String recordDurationStr = '00:00';

  @override
  void initState() {
    super.initState();

    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'updateDuration':
          final int v = call.arguments;
          recordDuration = v;
          setState(() {
            recordDurationStr = _printDuration(v);
          });
          break;
        default:
      }
    });

    getCurrentPositionPool();
  }

  getCurrentPositionPool() {
    /* take about 4ms */
    platform.invokeMethod('getCurrentPosition').then((value) {
      currentPosition = value;
      if (recordDuration != 0) {
        setState(() {
          currentPositionStr = _printDuration(value);
          _currentSliderValue = currentPosition / recordDuration * 100;
        });
      }
    }).whenComplete(() => Timer(
        const Duration(milliseconds: 100), () => getCurrentPositionPool()));
  }

  String _printDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    // String threeDigits(int n) => n.toString().padLeft(3, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    // String threeDigitMilliSeconds =
    //     threeDigits(duration.inMilliseconds.remainder(1000));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    super.dispose();

    sendPort?.send('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$currentPosition'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currentPositionStr/$recordDurationStr',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
        Slider(
          value: _currentSliderValue,
          max: 100,
          onChanged: (double value) {
            setState(() {
              _currentSliderValue = value;
            });
          },
          onChangeEnd: (value) {
            platform.invokeMethod(
                "seek", {'position': (value / 100 * recordDuration).floor()});
          },
        ),
      ],
    );
  }
}
