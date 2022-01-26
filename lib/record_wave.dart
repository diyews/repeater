import 'dart:typed_data';

import 'package:audio_wave/audio_wave.dart';
import 'package:flutter/material.dart';
import 'package:repeater/platform.dart';

class RecordWave extends StatefulWidget {
  const RecordWave({Key? key}) : super(key: key);

  @override
  _RecordWaveState createState() => _RecordWaveState();
}

class _RecordWaveState extends State<RecordWave> {
  List<int> waveList = [];

  @override
  void initState() {
    super.initState();

    registerPlatformListener((call) async {
      switch (call.method) {
        case 'updateAmplitude':
          processAmplitude(call.arguments);
          break;
        default:
      }
    });
  }

  processAmplitude(Int32List list) {
    const sampleMs = 50;
    final length = list.length;
    if (length == 0) {
      return;
    }
    final waveCount = (list[length - 2] / sampleMs).ceil();
    waveList = List.filled(waveCount, 1);

    for (var i = 0; i < length; i += 2) {
      final position = list[i];
      final v = list[i + 1];
      final waveIndex = (position / sampleMs).floor();

      if (v > waveList[waveIndex]) {
        waveList[waveIndex] = v;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return waveList.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: AudioWave(
                height: 100,
                width: constraints.maxWidth - 36,
                spacing: 0,
                animationLoop: 1,
                animation: false,
                bars: [
                  for (var i in waveList)
                    AudioWaveBar(
                        height: i / 500, color: Colors.blue, radius: 0.8),
                ],
              ),
            )
          : Container();
    });
  }
}
