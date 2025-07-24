// lib/main.dart
import 'package:eclub_app/login_screen.dart';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/home_dashboard_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:eclub_app/language_notifier.dart'; // <--- REMOVED THIS IMPORT

ThemeNotifier themeNotifier = ThemeNotifier();
// LanguageNotifier languageNotifier = LanguageNotifier(); // <--- REMOVED THIS INSTANCE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await themeNotifier.loadThemeMode();
  // await languageNotifier.loadLanguagePreference(); // <--- REMOVED THIS CALL
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, themeChild) {
        // Removed the nested ListenableBuilder for language
        return MaterialApp(
          title: 'Astra App',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.getThemeMode(),
          // Removed language-related properties
          // locale: languageNotifier.getAppLocale(),
          // supportedLocales: const [
          //   Locale('en', 'US'),
          //   Locale('hi', 'IN'),
          // ],
          // localizationsDelegates: const [
          //   DefaultMaterialLocalizations.delegate,
          //   DefaultWidgetsLocalizations.delegate,
          // ],
          home: const LoginScreen(),
        );
      },
    );
  }
}
