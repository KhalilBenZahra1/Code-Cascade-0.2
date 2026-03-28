import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';

import 'views/auth/app_router.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/splash/splash_screen.dart';
import 'views/profile/profile_page.dart';
import 'views/learner/learner_dashboard_page.dart';
import 'views/trainer/trainer_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CodeCascadeApp());
}

class CodeCascadeApp extends StatelessWidget {
  const CodeCascadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CodeCascade',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
        ),

        home: const SplashScreen(),

        routes: {
          '/app-router': (context) => AppRouter(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/profile': (context) => const ProfilePage(),
          '/learner/dashboard': (context) => const LearnerDashboardPage(),
          '/trainer/dashboard': (context) => const TrainerDashboardPage(),
        },
      ),
    );
  }
}
