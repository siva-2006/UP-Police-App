// lib/main.dart
import 'package:eclub_app/login_screen.dart';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/theme_notifier.dart';
import 'package:eclub_app/language_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eclub_app/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:eclub_app/background_tasks.dart';

ThemeNotifier themeNotifier = ThemeNotifier();
LanguageNotifier languageNotifier = LanguageNotifier();

final NotificationService notificationService = NotificationService();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeNotifier.loadThemeMode();
  await notificationService.initialize();
  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('emergency_contacts'); // Open a box for contacts
  await Hive.openBox('user_profile');
  
  // Initialize workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getString('user_phone') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeNotifier, languageNotifier]),
      builder: (context, child) {
        return MaterialApp(
          title: 'Jagriti Suraksha',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.getThemeMode(),
          home: isLoggedIn ? const WelcomeHomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}