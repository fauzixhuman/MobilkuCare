import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/dashboard_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline cache for faster loading
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MobilkuApp(),
    ),
  );
}

class MobilkuApp extends StatelessWidget {
  const MobilkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobilku Care',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1B23),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8CE0FA), // Light Blue
          surface: Color(0xFF1E2B34),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

/// Routes to LoginScreen or MainScreen based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show loading while checking auth state
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1B23),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8CE0FA)),
              SizedBox(height: 16),
              Text('Memuat...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (auth.isLoggedIn) {
      // Set userId in DashboardProvider when logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dashProvider = context.read<DashboardProvider>();
        dashProvider.setUserId(auth.userId);
      });
      return const MainScreen();
    }

    return const LoginScreen();
  }
}
