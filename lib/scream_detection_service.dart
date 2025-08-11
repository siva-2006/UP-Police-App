// lib/scream_detection_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

class ScreamDetectionService {
  Interpreter? _interpreter;
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recordingDataSubscription;
  bool _isDetecting = false;
  List<double> _audioBuffer = [];
  final int _modelInputLength = 44032;

  // Confirmation logic
  final int _confirmationRequiredCount = 3; // detections needed
  final double _confirmationWindowSec = 2.0; // in seconds
  List<DateTime> _positiveDetections = [];

  ScreamDetectionService() {
    _recorder = FlutterSoundRecorder();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      print('Scream detection model loaded successfully.');
    } catch (e) {
      print('Failed to load scream detection model: $e');
    }
  }

  Future<void> start() async {
    if (_interpreter == null || _isDetecting) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print("Microphone permission denied");
      return;
    }

    await _recorder!.openRecorder();
    _isDetecting = true;

    final recordingDataController = StreamController<Uint8List>();

    _recordingDataSubscription = recordingDataController.stream.listen((buffer) {
      _runInference(buffer);
    });

    await _recorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
      bufferSize: 16000, // bytes => 0.5 sec at 16kHz mono PCM16
    );

    print("Scream detection started...");
  }

  void _runInference(Uint8List audioData) {
    if (_interpreter == null) return;

    List<double> chunk = audioData.buffer
        .asInt16List()
        .map((e) => e / 32768.0)
        .map((e) => e.isFinite ? e : 0.0)
        .toList();

    _audioBuffer.addAll(chunk);

    if (_audioBuffer.length >= _modelInputLength) {
      List<double> input = _audioBuffer.sublist(
        _audioBuffer.length - _modelInputLength,
      );

      var inputArray = [input];
      var output = List.filled(2, 0.0).reshape([1, 2]);

      try {
        _interpreter!.run(inputArray, output);

        final exp0 = exp(output[0][0]);
        final exp1 = exp(output[0][1]);
        final sum = exp0 + exp1;
        double screamConfidence = exp1 / sum;

        if (screamConfidence > 0.6) {
          _positiveDetections.add(DateTime.now());
          _removeOldDetections();

          if (_positiveDetections.length >= _confirmationRequiredCount) {
            print(
                '🔊 SCREAM CONFIRMED! (${_positiveDetections.length} detections in last $_confirmationWindowSec s, confidence: ${screamConfidence.toStringAsFixed(2)})');
            _positiveDetections.clear(); // reset after confirmation
          } else {
            print(
                '⚠️ Possible scream (${_positiveDetections.length}/$_confirmationRequiredCount in window, confidence: ${screamConfidence.toStringAsFixed(2)})');
          }
        } else {
          _removeOldDetections();
          // print('😐 No scream. Confidence: ${screamConfidence.toStringAsFixed(2)})');
        }
      } catch (e) {
        print('❌ Error running model inference: $e');
      }
    }
  }

  void _removeOldDetections() {
    final now = DateTime.now();
    _positiveDetections.removeWhere(
        (t) => now.difference(t).inMilliseconds > _confirmationWindowSec * 1000);
  }

  Future<void> stop() async {
    if (!_isDetecting) return;
    await _recorder?.stopRecorder();
    await _recordingDataSubscription?.cancel();
    _recordingDataSubscription = null;
    _isDetecting = false;
    print("Scream detection stopped.");
  }

  Future<void> dispose() async {
    await stop();
    await _recorder?.closeRecorder();
    _recorder = null;
    _interpreter?.close();
  }
}
