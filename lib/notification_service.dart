import 'dart:async';
import 'package:eclub_app/emergency_service.dart';
import 'package:eclub_app/scream_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final EmergencyService _emergencyService = EmergencyService();
  Timer? _confirmationTimer;

  final ScreamDetectionService _screamService = ScreamDetectionService();
  VoidCallback? _callPoliceCancelCallback;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse);
  }

  // --- Scream Detection Notification (60s) ---
  void showScreamConfirmationNotification() {
    _startConfirmationTimer(
      duration: 60,
      onConfirm: () {
        _emergencyService.triggerScreamEmergencyActions();
        _screamService.emergencyServicesActivated();
      },
      payload: 'scream_detected',
    );
  }

  // --- Call Police Notification (30s) ---
  void showCallPoliceConfirmationNotification({VoidCallback? onCancel}) {
    _callPoliceCancelCallback = onCancel;
    _startConfirmationTimer(
      duration: 30,
      onConfirm: () {
        _emergencyService.triggerCallPoliceAction();
        _callPoliceCancelCallback?.call();
      },
      payload: 'call_police',
    );
  }

  // Generic timer and notification logic
  void _startConfirmationTimer({
    required int duration,
    required VoidCallback onConfirm,
    required String payload,
  }) {
    _confirmationTimer?.cancel();

    int countdown = duration;
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _notificationsPlugin.cancel(1);
        debugPrint("Confirmation time expired for $payload. Activating action.");
        onConfirm();
      } else {
        _showProgressNotification(
          countdown,
          maxProgress: duration,
          payload: payload,
        );
      }
    });

    _showProgressNotification(countdown, maxProgress: duration, payload: payload);
  }

  Future<void> _showProgressNotification(int progress, {required int maxProgress, required String payload}) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'emergency_channel', 'Emergency Alerts',
      channelDescription: 'Notifications for emergency confirmations',
      importance: Importance.max, priority: Priority.high,
      showWhen: false, ongoing: true, autoCancel: false,
      timeoutAfter: (progress + 1) * 1000,
      showProgress: true, maxProgress: maxProgress, progress: progress,
      indeterminate: false, onlyAlertOnce: true, fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final title = payload == 'scream_detected' 
      ? 'Scream Detected! Tap to dismiss' 
      : 'Call Police initiated! Tap to cancel';
    
    final body = 'Activating in $progress seconds.';

    await _notificationsPlugin.show(
      1, title, body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint("Notification tapped by user. Cancelling action for payload: ${response.payload}");
    
    // In both cases, cancel the periodic alerts
    _emergencyService.cancelPeriodicAlerts();
    
    cancelConfirmation(); // This cancels the notification timer
    
    if (response.payload == 'scream_detected') {
      _screamService.handleConfirmationCancellation();
    } else if (response.payload == 'call_police') {
      _callPoliceCancelCallback?.call();
    }
  }

  void cancelConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _notificationsPlugin.cancel(1);
  }
}