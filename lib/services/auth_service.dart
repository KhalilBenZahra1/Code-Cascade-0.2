import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../models/auth_result.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required List<String> expertises,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final user = credential.user;
      if (user == null) {
        throw Exception("Impossible de créer l'utilisateur.");
      }

      await user.updateDisplayName(fullName.trim());

      final appUser = AppUser(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: role,
        expertises: role == 'Formateur' ? expertises : [],
        createdAt: DateTime.now(),
      );

      await _userService.createUserProfile(appUser);

      return AuthResult(appUser: appUser, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Erreur lors de l'inscription : $e");
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Connexion impossible.");
      }

      return await _handlePostLogin(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Erreur lors de la connexion : $e");
    }
  }

  Future<AuthResult> signInWithGoogle({required String selectedRole}) async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Connexion Google annulée.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Connexion Google impossible.");
      }

      return await _handlePostLogin(user, selectedRole: selectedRole);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception("Erreur lors de la connexion Google : $e");
    }
  }

  Future<AuthResult> _handlePostLogin(
    User firebaseUser, {
    String selectedRole = 'Apprenant',
  }) async {
    final existingProfile = await _userService.getUserProfile(firebaseUser.uid);

    if (existingProfile != null) {
      return AuthResult(appUser: existingProfile, isNewUser: false);
    }

    final createdProfile = await _userService.getOrCreateUserProfile(
      firebaseUser,
      defaultRole: selectedRole,
    );

    return AuthResult(appUser: createdProfile, isNewUser: true);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception(
        'Erreur lors de l’envoi de l’email de réinitialisation : $e',
      );
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé pour cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec un autre mode de connexion.';
      case 'network-request-failed':
        return 'Problème réseau. Vérifiez votre connexion.';
      default:
        return e.message ?? 'Une erreur d\'authentification est survenue.';
    }
  }
}
