import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String? photoUrl;
  final List<String> expertises;
  final List<String>? interests;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.expertises = const [],
    this.interests,
    required this.createdAt,
  });

  // Getters helpers
  bool get isTrainer => role == 'Formateur';
  bool get isLearner => role == 'Apprenant';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];

    DateTime parsedCreatedAt;
    if (createdAtValue is Timestamp) {
      parsedCreatedAt = createdAtValue.toDate();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Apprenant',
      photoUrl: map['photoUrl'],
      expertises: List<String>.from(map['expertises'] ?? []),
      interests: map['interests'] != null
          ? List<String>.from(map['interests'])
          : null,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'expertises': expertises,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    String? photoUrl,
    List<String>? expertises,
    List<String>? interests,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      expertises: expertises ?? this.expertises,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
