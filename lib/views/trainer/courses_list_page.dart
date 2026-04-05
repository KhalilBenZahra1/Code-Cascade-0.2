import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/course_service.dart';
import 'course_builder_page.dart';
import 'learners_list_page.dart';

class CoursesListPage extends StatelessWidget {
  final bool showLearnersOnCourseTap;

  const CoursesListPage({super.key, this.showLearnersOnCourseTap = false});

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
        title: const Text(
          'Mes cours',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: courseService.getTrainerCourses(),
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun cours trouvé',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final learnerCount = {
                ...List<String>.from(data['enrolledLearnerIds'] ?? []),
                ...List<String>.from(data['inProgressLearnerIds'] ?? []),
                ...List<String>.from(data['completedLearnerIds'] ?? []),
              }.length;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: showLearnersOnCourseTap
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearnersListPage(
                              courseId: doc.id,
                              courseTitle: data['title'] ?? 'Cours',
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF84CC16,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: Color(0xFF84CC16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Sans titre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['category'] ?? ''} • ${data['level'] ?? ''}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$learnerCount apprenant(s)',
                              style: const TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showLearnersOnCourseTap)
                        const Icon(Icons.chevron_right, color: Colors.white70)
                      else ...[
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseBuilderPage(
                                  courseId: doc.id,
                                  initialData: {
                                    'title': data['title'] ?? '',
                                    'category': data['category'] ?? '',
                                    'level': data['level'] ?? 'Débutant',
                                    'description': data['description'] ?? '',
                                    'files': List<Map<String, dynamic>>.from(
                                      data['files'] ?? [],
                                    ),
                                    'quiz': List<Map<String, dynamic>>.from(
                                      data['quiz'] ?? [],
                                    ),
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF84CC16),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  title: const Text(
                                    'Supprimer le cours',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Voulez-vous vraiment supprimer ce cours ?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              try {
                                await CourseService().deleteCourse(doc.id);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cours supprimé avec succès'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erreur lors de la suppression : $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
