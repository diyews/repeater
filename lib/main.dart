import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repeater/platform.dart';
import 'package:repeater/record_wave.dart';

import 'duration_with_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

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
  int currentPosition = 0;
  int recordDuration = 0;
  String recordDurationStr = '';
  static const platform = MethodChannel('ws.diye/repeater');

  @override
  void initState() {
    super.initState();

    Permission.microphone.request();

    setupPlatformMethodChannel();
  }

  showRecordEncoderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const _RecordEncoderDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              showRecordEncoderDialog();
            },
            icon: const Icon(Icons.science_outlined),
          ),
          IconButton(
            onPressed: () {
              platform.invokeMethod("replay");
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Center(child: RecordWave()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                DurationWithSlider(),
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
        onPressed: () async {
          if (recording) {
            await widget.platform.invokeMethod("stopRecord");
          } else {
            await widget.platform.invokeMethod("startRecord");
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

class _RecordEncoderDialog extends StatefulWidget {
  const _RecordEncoderDialog({Key? key}) : super(key: key);

  @override
  _RecordEncoderDialogState createState() => _RecordEncoderDialogState();
}

class _RecordEncoderDialogState extends State<_RecordEncoderDialog> {
  static const platform = MethodChannel('ws.diye/repeater');

  int encoder = 0;
  late Future<int> encoderFuture;

  @override
  void initState() {
    super.initState();

    encoderFuture =
        platform.invokeMethod<int>('getRecordEncoder').then((value) {
      encoder = value!;
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Encoder'),
      contentPadding: const EdgeInsets.all(12),
      content: FutureBuilder(
          future: encoderFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('AAC'),
                    leading: Radio<int>(
                      value: 3,
                      groupValue: encoder,
                      onChanged: (int? value) {
                        setState(() {
                          encoder = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('AMR_NB'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: encoder,
                      onChanged: (int? value) {
                        setState(() {
                          encoder = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Container();
            }
          }),
      actions: [
        ElevatedButton(
          onPressed: () {
            platform.invokeMethod(
                'setRecordEncoder', {'encoder': encoder}).then((value) {
              exit(0);
            });
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
