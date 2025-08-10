// lib/scream_detection_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ScreamDetectionService {
  Interpreter? _interpreter;
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recordingDataSubscription;
  bool _isDetecting = false;
  int _screamCount = 0;

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
    _screamCount = 0;

    // This is the correct implementation for getting a raw audio stream.
    // The sink for the recorder expects Uint8List, so we create a controller of that type.
    final recordingDataController = StreamController<Uint8List>();

    _recordingDataSubscription = recordingDataController.stream.listen((buffer) {
      if (_isDetecting) {
        _runInference(buffer);
      }
    });

    // We pass our controller's sink to the startRecorder method.
    await _recorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000, // Must match your model's requirement
    );

    print("Scream detection started...");
  }

  void _runInference(Uint8List audioData) {
    if (_interpreter == null) return;
    
    // Convert the raw audio data (Uint8List of Int16) to the Float32List the model expects.
    var input = audioData.buffer.asInt16List().map((e) => e / 32767.0).toList();
    
    // Ensure the data matches the model's required input size by padding or truncating.
    const modelInputLength = 15600; 
    if (input.length < modelInputLength) {
        input.addAll(List.filled(modelInputLength - input.length, 0.0));
    } else if (input.length > modelInputLength) {
        input = input.sublist(0, modelInputLength);
    }
    
    var inputArray = [input];
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    try {
      _interpreter!.run(inputArray, output);
      // As per your labels: 0 is Background Noise, 1 is Scream
      double screamConfidence = output[0][1];
      
      if (screamConfidence > 0.9) { // Use a high threshold to avoid false positives
        _screamCount++;
         print('Consecutive screams detected: $_screamCount');
        if (_screamCount >= 3) {
          print('--- EMERGENCY TRIGGERED BY SCREAM ---');
          // In the future, you would call the alert/location tracking functions here.
          _screamCount = 0; // Reset after triggering
        }
      } else {
        _screamCount = 0; // Reset if the sound is not a scream
      }
    } catch (e) {
      print('Error running model inference: $e');
    }
  }

  Future<void> stop() async {
    if (!_isDetecting) return;
    if (_recorder!.isRecording) {
      await _recorder!.stopRecorder();
    }
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