import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUser.fromMap(doc.data()!);
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? email,
    String? photoUrl,
    List<String>? expertises,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) updates['fullName'] = fullName;
    if (email != null) updates['email'] = email;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (expertises != null) updates['expertises'] = expertises;

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }
  }

  Stream<AppUser?> streamUserProfile(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? AppUser.fromMap(doc.data()!)
              : null,
        );
  }

  Future<AppUser> getOrCreateUserProfile(
    User firebaseUser, {
    String defaultRole = 'Apprenant',
  }) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);

    return await _firestore.runTransaction<AppUser>((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists && snapshot.data() != null) {
        final existingUser = AppUser.fromMap(snapshot.data()!);

        final needsSync =
            existingUser.fullName.trim().isEmpty ||
            existingUser.email.trim().isEmpty;

        if (needsSync) {
          final updatedUser = existingUser.copyWith(
            fullName: existingUser.fullName.trim().isEmpty
                ? (firebaseUser.displayName ?? '')
                : existingUser.fullName,
            email: existingUser.email.trim().isEmpty
                ? (firebaseUser.email ?? '')
                : existingUser.email,
          );

          transaction.update(docRef, {
            'fullName': updatedUser.fullName,
            'email': updatedUser.email,
          });

          return updatedUser;
        }

        return existingUser;
      }

      final newUser = AppUser(
        uid: firebaseUser.uid,
        fullName: (firebaseUser.displayName ?? '').trim(),
        email: (firebaseUser.email ?? '').trim(),
        role: defaultRole,
        expertises: [],
        createdAt: DateTime.now(),
      );

      transaction.set(docRef, newUser.toMap());
      return newUser;
    });
  }
}
