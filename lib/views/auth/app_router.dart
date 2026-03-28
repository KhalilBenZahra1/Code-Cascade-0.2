import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'login_page.dart';
import '../learner/learner_dashboard_page.dart';
import '../trainer/trainer_dashboard_page.dart';

class AppRouter extends StatelessWidget {
  AppRouter({super.key});

  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnapshot.data;

        if (firebaseUser == null) {
          return const LoginPage();
        }

        return FutureBuilder(
          future: _userService.getOrCreateUserProfile(firebaseUser),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Erreur lors du chargement du profil'),
                ),
              );
            }

            final appUser = profileSnapshot.data;

            if (appUser == null) {
              return const LoginPage();
            }

            if (appUser.role == 'Formateur') {
              return const TrainerDashboardPage();
            }

            return const LearnerDashboardPage();
          },
        );
      },
    );
  }
}