import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        print('Fichier ignoré : path null ou vide');
        continue;
      }

      final File localFile = File(path);

      if (!localFile.existsSync()) {
        print('Fichier introuvable : $path');
        continue;
      }

      final String fileName = file['name'] ?? 'fichier';
      final String fileType = file['type'] ?? 'unknown';
      final int fileSize = file['size'] ?? 0;

      print('START UPLOAD: $fileName');
      print('PATH: $path');
      print('SIZE: $fileSize');

      final Reference storageRef = _storage.ref().child(
        'courses/${user.uid}/$courseId/$fileName',
      );

      final uploadTask = storageRef.putFile(localFile);

      uploadTask.snapshotEvents.listen((snapshot) {
        print(
          'PROGRESS $fileName : ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
        );
      });

      await uploadTask;
      print('UPLOAD DONE: $fileName');

      final String downloadUrl = await storageRef.getDownloadURL();
      print('DOWNLOAD URL: $downloadUrl');

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
}
