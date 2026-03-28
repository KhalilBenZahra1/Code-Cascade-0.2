import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  String get email => _user?.email ?? '';
  String get role => _user?.role ?? '';
  List<String> get expertises => _user?.expertises ?? [];
  bool get isTrainer => _user?.isTrainer ?? false;

  AppUser? _user;
  bool _isLoading = true;
  File? _profileImage;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  File? get profileImage => _profileImage;
  bool get hasUser => _user != null;
  String? get error => _error;

  String get displayName => _user?.fullName ?? 'Utilisateur';
  String get displayEmail => _user?.email ?? 'email@exemple.com';
  String get roleLabel =>
      _user?.isTrainer ?? false ? 'Formateur Pro' : 'Apprenant';

  Color get accentColor => _user?.isTrainer ?? false
      ? const Color(0xFF84CC16)
      : const Color(0xFF3B82F6);

  List<String> get tags => _user?.isTrainer ?? false
      ? (_user?.expertises ?? [])
      : (_user?.interests ?? []);

  String get tagsTitle =>
      _user?.isTrainer ?? false ? 'Expertise' : 'Centres d\'intérêt';

  ProfileProvider() {
    _loadUserInternal();
  }

  Future<void> loadUser() async {
    await _loadUserInternal();
  }

  Future<void> refresh() async {
    await _loadUserInternal();
  }

  Future<void> updateProfile({String? fullName, String? email}) async {
    if (_user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (fullName != null && fullName != _user!.fullName) {
        await _userService.updateProfile(uid: _user!.uid, fullName: fullName);
      }

      if (email != null && email != _user!.email) {
        await _authService.updateEmail(email);
      }

      await _loadUserInternal();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePhoto(File image) async {
    _profileImage = image;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _profileImage = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getInitials() {
    final name = _user?.fullName ?? '';
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _loadUserInternal() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        _user = null;
        return;
      }

      final appUser = await _userService.getUserProfile(firebaseUser.uid);

      if (appUser == null) {
        _user = null;
        _error = 'Profil utilisateur introuvable';
        return;
      }

      // Synchroniser Firestore avec Firebase Auth si l'email a changé
      if ((firebaseUser.email ?? '').trim().isNotEmpty &&
          appUser.email.trim() != (firebaseUser.email ?? '').trim()) {
        await _userService.updateProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email!.trim(),
        );

        _user = appUser.copyWith(email: firebaseUser.email!.trim());
      } else {
        _user = appUser;
      }
    } catch (e) {
      _user = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String newValue) async {
    await updateProfile(fullName: newValue);
  }

  Future<void> updateEmailOnly(String newValue) async {
    await updateProfile(email: newValue);
  }

  Future<void> updateExpertises(List<String> newExpertises) async {
    if (_user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateProfile(
        uid: _user!.uid,
        expertises: newExpertises,
      );

      await _loadUserInternal();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
