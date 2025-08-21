import 'dart:async';
import 'package:eclub_app/emergency_service.dart';
import 'package:eclub_app/scream_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final EmergencyService _emergencyService = EmergencyService();
  
  // Timers for each notification type
  Timer? _screamConfirmationTimer;
  Timer? _callPoliceConfirmationTimer;

  final ScreamDetectionService _screamService = ScreamDetectionService();
  VoidCallback? _callPoliceCancelCallback;

  // Notification IDs
  static const int SCREAM_NOTIFICATION_ID = 0;
  static const int CALL_POLICE_NOTIFICATION_ID = 1;

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
      notificationId: SCREAM_NOTIFICATION_ID,
      timerToUpdate: _screamConfirmationTimer,
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
      notificationId: CALL_POLICE_NOTIFICATION_ID,
      timerToUpdate: _callPoliceConfirmationTimer,
    );
  }

  // Generic timer and notification logic
  void _startConfirmationTimer({
    required int duration,
    required VoidCallback onConfirm,
    required String payload,
    required int notificationId,
    required Timer? timerToUpdate,
  }) {
    timerToUpdate?.cancel();

    int countdown = duration;
    timerToUpdate = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _notificationsPlugin.cancel(notificationId);
        debugPrint("Confirmation time expired for $payload. Activating action.");
        onConfirm();
      } else {
        _showProgressNotification(
          countdown,
          maxProgress: duration,
          payload: payload,
          notificationId: notificationId,
        );
      }
    });

    _showProgressNotification(countdown, maxProgress: duration, payload: payload, notificationId: notificationId);

    // Assign the timer to the correct variable
    if (notificationId == SCREAM_NOTIFICATION_ID) {
      _screamConfirmationTimer = timerToUpdate;
    } else {
      _callPoliceConfirmationTimer = timerToUpdate;
    }
  }

  Future<void> _showProgressNotification(int progress, {required int maxProgress, required String payload, required int notificationId}) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'emergency_channel', 'Emergency Alerts',
      channelDescription: 'Notifications for emergency confirmations',
      importance: Importance.max, priority: Priority.high,
      showWhen: false, ongoing: true, autoCancel: false,
      timeoutAfter: (progress + 2) * 1000,
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
      notificationId, title, body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint("Notification tapped by user. Cancelling action for payload: ${response.payload}");
    
    if (response.payload == 'scream_detected') {
      _screamConfirmationTimer?.cancel();
      _notificationsPlugin.cancel(SCREAM_NOTIFICATION_ID);
      _screamService.handleConfirmationCancellation();
    } else if (response.payload == 'call_police') {
      _callPoliceConfirmationTimer?.cancel();
      _notificationsPlugin.cancel(CALL_POLICE_NOTIFICATION_ID);
      _callPoliceCancelCallback?.call();
    }
  }

  // A general cancel for when the service is stopped
  void cancelAllConfirmations() {
    _screamConfirmationTimer?.cancel();
    _callPoliceConfirmationTimer?.cancel();
    _notificationsPlugin.cancelAll();
  }
}