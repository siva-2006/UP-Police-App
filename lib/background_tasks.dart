// lib/background_tasks.dart
import 'package:workmanager/workmanager.dart';
import 'package:eclub_app/scream_detection_service.dart';
import 'package:eclub_app/emergency_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "scream_detection":
        final screamService = ScreamDetectionService();
        await screamService.start();
        break;
      case "send_emergency_alert":
        final emergencyService = EmergencyService();
        final triggerReason = inputData?['triggerReason'] as String?;
        await emergencyService.triggerScreamEmergencyActions();
        break;
    }
    return Future.value(true);
  });
}