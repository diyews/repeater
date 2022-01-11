import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repeater',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Repeater'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int currentPosition = 0;
  int recordDuration = 0;
  String recordDurationStr = '';
  double _currentSliderValue = 0;
  static const platform = MethodChannel('ws.diye/repeater');

  @override
  void initState() {
    super.initState();

    Permission.microphone.request();

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
        // todo performance
        setState(() {
          _currentSliderValue = currentPosition / recordDuration * 100;
        });
      }
    }).whenComplete(() => Timer(
        const Duration(milliseconds: 100), () => getCurrentPositionPool()));
  }

  String _printDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String threeDigitMilliSeconds =
        threeDigits(duration.inMilliseconds.remainder(1000));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                platform.invokeMethod("replay");
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  recordDurationStr,
                  style: Theme.of(context).textTheme.headline4,
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
                    platform.invokeMethod("seek", {'position': value});
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 36),
            alignment: Alignment.bottomCenter,
            child: const _PlayStop(
              platform: platform,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayStop extends StatefulWidget {
  final MethodChannel platform;
  const _PlayStop({Key? key, required this.platform}) : super(key: key);

  @override
  _PlayStopState createState() => _PlayStopState();
}

class _PlayStopState extends State<_PlayStop> {
  bool recording = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: ElevatedButton(
        onPressed: () {
          if (recording) {
            widget.platform.invokeMethod("stopRecord");
          } else {
            widget.platform.invokeMethod("startRecord");
          }
          setState(() {
            recording = !recording;
          });
        },
        child: recording
            ? const Icon(
                Icons.stop,
                size: 50,
              )
            : const Icon(
                Icons.mic_none,
                size: 50,
              ),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
