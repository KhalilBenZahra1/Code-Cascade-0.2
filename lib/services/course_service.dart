import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== MÉTHODES EXISTANTES ====================

  /// Récupère les cours du formateur en temps réel (Stream)
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

  /// Compte le nombre de cours du formateur (Stream)
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

  /// Crée un NOUVEAU cours (avec upload de fichiers)
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

    // Génère un nouvel ID de cours
    final courseRef = _firestore.collection('courses').doc();
    final String courseId = courseRef.id;

    final List<Map<String, dynamic>> uploadedFiles = [];

    // Upload des fichiers
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

    // Crée le document avec set()
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

      // Learners qui ont ajouté le cours à leur liste "Cours suivis"
      'enrolledLearnerIds': <String>[],

      // Learners qui ont commencé le cours
      'inProgressLearnerIds': <String>[],

      // Learners qui ont terminé le cours
      'completedLearnerIds': <String>[],

      // Learners qui ont deja termine ce cours au moins une fois
      'everCompletedLearnerIds': <String>[],
    });
  }

  // ==================== NOUVELLE MÉTHODE ====================

  /// Met à jour un cours EXISTANT (avec gestion des fichiers existants/nouveaux)
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

    // Référence au document existant (pas de nouvel ID ici !)
    final courseRef = _firestore.collection('courses').doc(courseId);

    final List<Map<String, dynamic>> updatedFiles = [];

    for (final file in files) {
      final String? existingUrl = file['url'];
      final String? path = file['path'];

      // Fichier déjà existant dans Storage (pas besoin de re-uploader)
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

      // Nouveau fichier local à uploader
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

    // Met à jour avec update() (pas set() !)
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

  /// Récupère tous les cours publiés par les formateurs
  Stream<QuerySnapshot<Map<String, dynamic>>> getPublishedCourses() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Récupère un seul cours par son ID
  Stream<DocumentSnapshot<Map<String, dynamic>>> getCourseById(
    String courseId,
  ) {
    return _firestore.collection('courses').doc(courseId).snapshots();
  }

  /// Récupère les cours suivis par l'apprenant connecté
  /// Ici : cours ajoutés mais pas encore commencés
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

  /// Récupère les cours en progression pour l'apprenant connecté
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

  /// Récupère les cours terminés pour l'apprenant connecté
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

  /// Compte le nombre de cours suivis par l'apprenant connecté
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

  /// Compte le nombre de cours en progression
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

  /// Compte le nombre de cours terminés
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

  /// KPI learner: nombre de cours termines (visible en termines OU deja termines une fois)
  Stream<int> getCompletedKpiCount() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return _firestore.collection('courses').snapshots().map((snapshot) {
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final List completed = List.from(data['completedLearnerIds'] ?? []);
        final List everCompleted = List.from(
          data['everCompletedLearnerIds'] ?? [],
        );
        final Map<String, dynamic> scores = Map<String, dynamic>.from(
          data['learnerScores'] ?? {},
        );

        final bool isVisibleInCompleted = completed.contains(user.uid);
        final bool hasEverCompletedFlag = everCompleted.contains(user.uid);
        final bool hasLearnerScore = scores[user.uid] != null;

        if (isVisibleInCompleted || hasEverCompletedFlag || hasLearnerScore) {
          count++;
        }
      }

      return count;
    });
  }

  /// Ajoute le learner à la liste "Cours suivis"
  /// arrayUnion évite les doublons automatiquement
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

  /// Quand le learner clique sur "Commencer"
  /// Le cours quitte "Cours suivis" et va dans "Progression"
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

  /// Supprime rapidement un cours de la liste "Cours suivis"
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

  /// Quand le learner termine le cours
  /// Le cours quitte "Progression" et va dans "Terminés"
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

    // Sauvegarder le score si fourni (format map par userId)
    if (score != null) {
      updateData['learnerScores.${user.uid}.score'] = score;
      updateData['learnerScores.${user.uid}.completedAt'] =
          FieldValue.serverTimestamp();
    }

    await _firestore.collection('courses').doc(courseId).update(updateData);
  }

  /// Quand le learner veut revoir un cours terminé
  /// Le cours quitte "Terminés" et retourne dans "Cours suivis"
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

  /// Vérifie si le learner existe déjà dans au moins une des listes du cours
  bool isLearnerLinkedToCourse(Map<String, dynamic> courseData, String userId) {
    final List enrolled = List.from(courseData['enrolledLearnerIds'] ?? []);
    final List inProgress = List.from(courseData['inProgressLearnerIds'] ?? []);
    final List completed = List.from(courseData['completedLearnerIds'] ?? []);

    return enrolled.contains(userId) ||
        inProgress.contains(userId) ||
        completed.contains(userId);
  }

  /// Vérifie si le learner suit déjà ce cours
  bool isCourseEnrolled(Map<String, dynamic> courseData, String userId) {
    final List enrolled = List.from(courseData['enrolledLearnerIds'] ?? []);
    return enrolled.contains(userId);
  }

  /// Vérifie si le learner est déjà en progression sur ce cours
  bool isCourseInProgress(Map<String, dynamic> courseData, String userId) {
    final List inProgress = List.from(courseData['inProgressLearnerIds'] ?? []);
    return inProgress.contains(userId);
  }

  /// Vérifie si le learner a déjà terminé ce cours
  bool isCourseCompleted(Map<String, dynamic> courseData, String userId) {
    final List completed = List.from(courseData['completedLearnerIds'] ?? []);
    return completed.contains(userId);
  }
}
