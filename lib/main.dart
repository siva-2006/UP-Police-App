// lib/main.dart
import 'package:eclub_app/login_screen.dart';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/theme_notifier.dart';
import 'package:eclub_app/language_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeNotifier themeNotifier = ThemeNotifier();
LanguageNotifier languageNotifier = LanguageNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeNotifier.loadThemeMode();
  
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
          title: 'Astra App',
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