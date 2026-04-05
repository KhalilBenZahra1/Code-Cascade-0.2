import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';
  static const String _activityEventsCollection = 'activityEvents';

  // ==================== MÉTHODES EXISTANTES ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getTrainerCourses() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('trainerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<int> getTrainerCoursesCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('trainerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTrainerLearnersCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('trainerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          int totalLearners = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final courseLearners = <String>{
              ...List<String>.from(data['enrolledLearnerIds'] ?? []),
              ...List<String>.from(data['inProgressLearnerIds'] ?? []),
              ...List<String>.from(data['completedLearnerIds'] ?? []),
            };

            totalLearners += courseLearners.length;
          }

          return totalLearners;
        });
  }

  Future<void> createCourse({
    required String title,
    required String category,
    required String level,
    required String description,
    required List<Map<String, dynamic>> files,
    required List<Map<String, dynamic>> quiz,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    if (quiz.length > 5) {
      throw Exception("Le quiz ne peut pas dépasser 5 questions.");
    }

    final courseRef = _firestore.collection('courses').doc();
    final String courseId = courseRef.id;

    final List<Map<String, dynamic>> uploadedFiles = [];

    for (final file in files) {
      final String? path = file['path'];

      if (path == null || path.isEmpty) {
        debugPrint('Fichier ignoré : path null ou vide');
        continue;
      }

      final File localFile = File(path);

      if (!localFile.existsSync()) {
        debugPrint('Fichier introuvable : $path');
        continue;
      }

      final String fileName = file['name'] ?? 'fichier';
      final String fileType = file['type'] ?? 'unknown';
      final int fileSize = file['size'] ?? 0;

      debugPrint('START UPLOAD: $fileName');
      debugPrint('PATH: $path');
      debugPrint('SIZE: $fileSize');

      final Reference storageRef = _storage.ref().child(
        'courses/${user.uid}/$courseId/$fileName',
      );

      final uploadTask = storageRef.putFile(localFile);

      uploadTask.snapshotEvents.listen((snapshot) {
        debugPrint(
          'PROGRESS $fileName : ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
        );
      });

      await uploadTask;
      debugPrint('UPLOAD DONE: $fileName');

      final String downloadUrl = await storageRef.getDownloadURL();
      debugPrint('DOWNLOAD URL: $downloadUrl');

      uploadedFiles.add({
        'name': fileName,
        'type': fileType,
        'size': fileSize,
        'url': downloadUrl,
      });
    }

    final sanitizedQuiz = quiz.map((question) {
      return {
        'text': question['text'] ?? '',
        'type': question['type'] ?? 'qcm',
        'options': (question['options'] as List? ?? []).map((option) {
          return {
            'id': option['id'] ?? '',
            'text': option['text'] ?? '',
            'isCorrect': option['isCorrect'] ?? false,
          };
        }).toList(),
        'explanation': question['explanation'] ?? '',
      };
    }).toList();

    await courseRef.set({
      'title': title.trim(),
      'category': category.trim(),
      'level': level.trim(),
      'description': description.trim(),
      'trainerId': user.uid,
      'trainerEmail': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'files': uploadedFiles,
      'quiz': sanitizedQuiz,
      'enrolledLearnerIds': <String>[],
      'inProgressLearnerIds': <String>[],
      'completedLearnerIds': <String>[],
      'everCompletedLearnerIds': <String>[],
    });
  }

  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String category,
    required String level,
    required String description,
    required List<Map<String, dynamic>> files,
    required List<Map<String, dynamic>> quiz,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    if (quiz.length > 5) {
      throw Exception("Le quiz ne peut pas dépasser 5 questions.");
    }

    final courseRef = _firestore.collection('courses').doc(courseId);

    final List<Map<String, dynamic>> updatedFiles = [];

    for (final file in files) {
      final String? existingUrl = file['url'];
      final String? path = file['path'];

      if (existingUrl != null &&
          existingUrl.isNotEmpty &&
          (path == null || path.isEmpty)) {
        updatedFiles.add({
          'name': file['name'] ?? 'fichier',
          'type': file['type'] ?? 'unknown',
          'size': file['size'] ?? 0,
          'url': existingUrl,
        });
        continue;
      }

      if (path == null || path.isEmpty) {
        continue;
      }

      final File localFile = File(path);

      if (!localFile.existsSync()) {
        continue;
      }

      final String fileName = file['name'] ?? 'fichier';
      final String fileType = file['type'] ?? 'unknown';
      final int fileSize = file['size'] ?? 0;

      final Reference storageRef = _storage.ref().child(
        'courses/${user.uid}/$courseId/$fileName',
      );

      await storageRef.putFile(localFile);
      final String downloadUrl = await storageRef.getDownloadURL();

      updatedFiles.add({
        'name': fileName,
        'type': fileType,
        'size': fileSize,
        'url': downloadUrl,
      });
    }

    final sanitizedQuiz = quiz.map((question) {
      return {
        'text': question['text'] ?? '',
        'type': question['type'] ?? 'qcm',
        'options': (question['options'] as List? ?? []).map((option) {
          return {
            'id': option['id'] ?? '',
            'text': option['text'] ?? '',
            'isCorrect': option['isCorrect'] ?? false,
          };
        }).toList(),
        'explanation': question['explanation'] ?? '',
      };
    }).toList();

    await courseRef.update({
      'title': title.trim(),
      'category': category.trim(),
      'level': level.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'files': updatedFiles,
      'quiz': sanitizedQuiz,
    });
  }

  Future<void> deleteCourse(String courseId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _firestore.collection('courses').doc(courseId).delete();
  }

  // ==================== MÉTHODES LEARNER ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getPublishedCourses() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCourseById(
    String courseId,
  ) {
    return _firestore.collection('courses').doc(courseId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getEnrolledCourses() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('enrolledLearnerIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getInProgressCourses() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('inProgressLearnerIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompletedCourses() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('completedLearnerIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<int> getEnrolledCoursesCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('enrolledLearnerIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getInProgressCoursesCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('inProgressLearnerIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getCompletedCoursesCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection('courses')
        .where('completedLearnerIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Total historique des événements "cours terminé" pour le learner connecté.
  /// Ici on compte les événements, pas les cours.
  Stream<int> getCompletedActivityTotalCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_activityEventsCollection)
        .where('type', isEqualTo: 'course_completed')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Récupère les événements "course_completed" des X dernières minutes.
  Stream<QuerySnapshot<Map<String, dynamic>>> getRecentCompletedActivityEvents({
    int windowMinutes = 15,
  }) {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(minutes: windowMinutes));

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_activityEventsCollection)
        .where('type', isEqualTo: 'course_completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> enrollInCourse(String courseId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _firestore.collection('courses').doc(courseId).update({
      'enrolledLearnerIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startCourse(String courseId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _firestore
        .collection('courses')
        .doc(courseId)
        .update({
          'enrolledLearnerIds': FieldValue.arrayRemove([user.uid]),
          'inProgressLearnerIds': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw Exception(
              "Le serveur met trop de temps à répondre. Vérifiez votre connexion puis réessayez.",
            );
          },
        );
  }

  Future<void> removeFromEnrolled(String courseId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _firestore
        .collection('courses')
        .doc(courseId)
        .update({
          'enrolledLearnerIds': FieldValue.arrayRemove([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            throw Exception(
              "Suppression trop lente. Vérifiez la connexion puis réessayez.",
            );
          },
        );
  }

  Future<void> completeCourse(String courseId, {int? score}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    final Map<String, dynamic> updateData = {
      'inProgressLearnerIds': FieldValue.arrayRemove([user.uid]),
      'completedLearnerIds': FieldValue.arrayUnion([user.uid]),
      'everCompletedLearnerIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (score != null) {
      updateData['learnerScores.${user.uid}.score'] = score;
      updateData['learnerScores.${user.uid}.completedAt'] =
          FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('courses')
        .doc(courseId)
        .update(updateData)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw Exception(
              "Le serveur met trop de temps à répondre. Vérifiez votre connexion puis réessayez.",
            );
          },
        );

    unawaited(
      _logCourseCompletedActivityEvent(courseId: courseId, score: score),
    );
  }

  Future<void> _logCourseCompletedActivityEvent({
    required String courseId,
    int? score,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final activityRef = _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_activityEventsCollection)
          .doc();

      await activityRef.set({
        'type': 'course_completed',
        'courseId': courseId,
        'score': score,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ne bloque jamais l'UX learner si le log d'activite echoue.
    }
  }

  Future<void> restartCourse(String courseId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    await _firestore.collection('courses').doc(courseId).update({
      'completedLearnerIds': FieldValue.arrayRemove([user.uid]),
      'enrolledLearnerIds': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool isLearnerLinkedToCourse(Map<String, dynamic> courseData, String userId) {
    final List enrolled = List.from(courseData['enrolledLearnerIds'] ?? []);
    final List inProgress = List.from(courseData['inProgressLearnerIds'] ?? []);
    final List completed = List.from(courseData['completedLearnerIds'] ?? []);

    return enrolled.contains(userId) ||
        inProgress.contains(userId) ||
        completed.contains(userId);
  }

  bool isCourseEnrolled(Map<String, dynamic> courseData, String userId) {
    final List enrolled = List.from(courseData['enrolledLearnerIds'] ?? []);
    return enrolled.contains(userId);
  }

  bool isCourseInProgress(Map<String, dynamic> courseData, String userId) {
    final List inProgress = List.from(courseData['inProgressLearnerIds'] ?? []);
    return inProgress.contains(userId);
  }

  bool isCourseCompleted(Map<String, dynamic> courseData, String userId) {
    final List completed = List.from(courseData['completedLearnerIds'] ?? []);
    return completed.contains(userId);
  }
}
