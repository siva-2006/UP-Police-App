// lib/scream_detection_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:eclub_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

class ScreamDetectionService {
  // --- SINGLETON PATTERN SETUP ---
  static final ScreamDetectionService _instance = ScreamDetectionService._internal();
  factory ScreamDetectionService() {
    return _instance;
  }
  ScreamDetectionService._internal() {
    _loadModel();
  }
  // --- END SINGLETON PATTERN ---


  static const platform = MethodChannel('com.eclub_app/audio_processing');

  Interpreter? _interpreter;
  AudioRecorder? _recorder;
  bool _isDetecting = false;

  final List<int> _inputShape = [1, 128, 130, 1];

  DateTime? _lastAlertTime;
  final Duration _alertCooldown = const Duration(seconds: 60);

  final ValueNotifier<String> statusNotifier = ValueNotifier('');

  Timer? _cooldownTimer;

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      debugPrint('Scream detection model loaded successfully.');
    } catch (e) {
      debugPrint('Failed to load scream detection model: $e');
    }
  }

  void handleConfirmationCancellation() async {
    statusNotifier.value = "Accidental Alert Cancelled";
    await Future.delayed(const Duration(seconds: 2));
    if (_isDetecting) {
      _startCooldownTimer();
    }
  }

  // NEW: A new method for when the alert is confirmed
  void emergencyServicesActivated() async {
    statusNotifier.value = "Emergency Services Activated";
    await Future.delayed(const Duration(seconds: 2));
     if (_isDetecting) {
      _startCooldownTimer();
    }
  }


  Future<void> start() async {
    if (_interpreter == null || _isDetecting) return;
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Microphone permission denied");
      return;
    }

    _isDetecting = true;
    debugPrint("Scream detection started...");

    // Register a periodic task for scream detection
    await Workmanager().registerPeriodicTask(
      "scream_detection_task",
      "scream_detection",
      frequency: const Duration(minutes: 15), // Minimum frequency for periodic tasks
    );
  }

  Future<void> _handleScreamDetected() async {
    final now = DateTime.now();
    if (_lastAlertTime == null || now.difference(_lastAlertTime!) > _alertCooldown) {
      statusNotifier.value = "Scream Detected!";
      await Future.delayed(const Duration(seconds: 2));

      if (!_isDetecting) return;

      debugPrint("Scream detected. Starting confirmation notification.");
      statusNotifier.value = "Confirming...";
      _lastAlertTime = now;
      notificationService.showScreamConfirmationNotification();
    } else {
      debugPrint("Scream detected, but in cooldown period. Ignoring.");
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (_lastAlertTime == null) {
        timer.cancel();
        return;
      }

      final difference = now.difference(_lastAlertTime!);

      if (difference >= _alertCooldown) {
        statusNotifier.value = "Listening...";
        timer.cancel();
      } else {
        final remaining = _alertCooldown - difference;
        statusNotifier.value = "Cooldown (${remaining.inSeconds}s)";
      }
    });
  }

  Future<void> stop() async {
    if (!_isDetecting) return;
    _isDetecting = false;
    statusNotifier.value = "";
    _cooldownTimer?.cancel();
    notificationService.cancelConfirmation();
    
    // Cancel the background task
    await Workmanager().cancelByUniqueName("scream_detection_task");

    debugPrint("Scream detection stopped.");
  }

  void dispose() {
    stop();
    _interpreter?.close();
    statusNotifier.dispose();
  }
}

extension Reshape on Float32List {
  List<dynamic> reshape(List<int> shape) {
    if (shape.reduce((a, b) => a * b) != length) {
      throw ArgumentError('New shape does not match the list size');
    }
    if (shape.length == 4 && shape[0] == 1 && shape[3] == 1) {
      final height = shape[1];
      final width = shape[2];
      final list = List.generate(
        1,
        (_) => List.generate(
          height,
          (i) => List.generate(
            width,
            (j) => [this[i * width + j]],
          ),
        ),
      );
      return list;
    }
    throw UnimplementedError('Reshape for shape $shape not implemented');
  }
}