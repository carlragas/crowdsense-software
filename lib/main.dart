import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/screens/analytics_screen.dart';
import 'features/dashboard/screens/devices_screen.dart';

import 'features/splash/screens/splash_screen.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/user_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Catch the firebase_auth Windows threading bug at the zone level
  // so it doesn't hard-crash the "Lost connection to device"
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('firebase_auth_plugin') ||
        error.toString().contains('non-platform thread')) {
      return true; // silently handle the plugin's false-alarm bug
    }
    return false; // let all other real errors crash normally
  };

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(500, 950),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const CrowdSenseApp(),
    ),
  );
}

class CrowdSenseApp extends StatelessWidget {
  const CrowdSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CrowdSense',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }
}
