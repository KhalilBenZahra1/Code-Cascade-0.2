import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/course_service.dart';
import 'quiz_page.dart';

class ModuleListPage extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const ModuleListPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  Future<void> _openFileUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir ce fichier')),
      );
    }
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'presentation':
        return Icons.slideshow;
      case 'video':
        return Icons.video_file;
      case 'excel':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'presentation':
        return Colors.orange;
      case 'video':
        return Colors.blue;
      case 'excel':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFileTypeLabel(String type) {
    switch (type) {
      case 'pdf':
        return 'Document PDF';
      case 'presentation':
        return 'Présentation';
      case 'video':
        return 'Vidéo';
      case 'excel':
        return 'Fichier Excel';
      default:
        return 'Fichier';
    }
  }

  @override
  Widget build(BuildContext context) {
    final CourseService courseService = CourseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          courseTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: courseService.getCourseById(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF84CC16)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur : ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Cours introuvable',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final List files = List.from(data['files'] ?? []);
          final String description = data['description'] ?? '';
            final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
            final Map<String, dynamic> learnerChecks =
              Map<String, dynamic>.from(data['learnerFileChecks'] ?? {});
            final Map<String, dynamic> userChecks =
              userId.isNotEmpty && learnerChecks[userId] is Map
              ? Map<String, dynamic>.from(learnerChecks[userId] as Map)
              : <String, dynamic>{};

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? courseTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data['category'] ?? ''} • ${data['level'] ?? ''}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Contenu du cours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (files.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Aucun fichier disponible pour ce cours',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ...files.asMap().entries.map<Widget>((entry) {
                        final int fileIndex = entry.key;
                        final file = entry.value;
                        final Map<String, dynamic> item =
                            Map<String, dynamic>.from(file);
                        final String fileType = item['type'] ?? 'unknown';
                        final String fileName = item['name'] ?? 'fichier';
                        final int fileSize = item['size'] ?? 0;
                        final String fileUrl = item['url'] ?? '';
                        final String fileKey = 'f$fileIndex';
                        final Map<String, dynamic> fileChecks =
                            userChecks[fileKey] is Map
                            ? Map<String, dynamic>.from(userChecks[fileKey])
                            : <String, dynamic>{};

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getFileColor(
                                    fileType,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getFileIcon(fileType),
                                  color: _getFileColor(fileType),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB • ${_getFileTypeLabel(fileType)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: fileUrl.isEmpty
                                    ? null
                                    : () => _openFileUrl(context, fileUrl),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF84CC16),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Ouvrir'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(3, (partIndex) {
                              final String partKey = 'p$partIndex';
                              final bool isChecked =
                                  fileChecks[partKey] == true;

                              return Padding(
                                padding: EdgeInsets.only(
                                  right: partIndex < 2 ? 8 : 0,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: userId.isEmpty
                                      ? null
                                      : () async {
                                          try {
                                            await courseService
                                                .setFilePartChecked(
                                                  courseId: courseId,
                                                  fileKey: fileKey,
                                                  partIndex: partIndex,
                                                  checked: !isChecked,
                                                );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erreur: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isChecked
                                          ? const Color(0xFF84CC16)
                                          : Colors.grey.shade700,
                                    ),
                                    backgroundColor: isChecked
                                        ? const Color(
                                            0xFF84CC16,
                                          ).withOpacity(0.15)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(
                                    isChecked
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: isChecked
                                        ? const Color(0xFF84CC16)
                                        : Colors.white70,
                                  ),
                                  label: Text(
                                    'Partie ${partIndex + 1}',
                                    style: TextStyle(
                                      color: isChecked
                                          ? const Color(0xFF84CC16)
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await courseService.completeCourse(courseId);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cours marqué comme terminé'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Terminer',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizPage(
                                  courseId: courseId,
                                  courseTitle: courseTitle,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF84CC16),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Passer le quiz',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
