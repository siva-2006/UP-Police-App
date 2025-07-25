// lib/main.dart
import 'package:eclub_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/theme_notifier.dart';
import 'package:eclub_app/language_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

ThemeNotifier themeNotifier = ThemeNotifier();
LanguageNotifier languageNotifier = LanguageNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  await themeNotifier.loadThemeMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const LoginScreen(),
        );
      },
    );
  }
}