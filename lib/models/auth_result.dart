import 'app_user.dart';

class AuthResult {
  final AppUser appUser;
  final bool isNewUser;

  AuthResult({required this.appUser, required this.isNewUser});

  String get targetRoute {
    return appUser.role == 'Formateur'
        ? '/trainer/dashboard'
        : '/learner/dashboard';
  }
}
