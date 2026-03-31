import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/course_service.dart';
import 'quiz_page.dart';
import 'module_list_page.dart';

class LearnerCourseHomePage extends StatefulWidget {
  final String courseId;
  final bool moveToProgressOnOpen;

  const LearnerCourseHomePage({
    super.key,
    required this.courseId,
    this.moveToProgressOnOpen = false,
  });

  @override
  State<LearnerCourseHomePage> createState() => _LearnerCourseHomePageState();
}

class _LearnerCourseHomePageState extends State<LearnerCourseHomePage> {
  final CourseService _courseService = CourseService();
  bool _hasStartedTransition = false;

  @override
  void initState() {
    super.initState();

    if (widget.moveToProgressOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_hasStartedTransition) return;
        _hasStartedTransition = true;

        try {
          await _courseService.startCourse(widget.courseId);
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du passage en progression : $e'),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Démarrer le cours',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _courseService.getCourseById(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
          final List quiz = List.from(data['quiz'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
                        data['description'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choisissez ce que vous voulez faire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChoiceCard(
                  context: context,
                  title: 'Voir le cours',
                  subtitle:
                      '${files.length} fichier(s) disponible(s) pour apprendre',
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFF84CC16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModuleListPage(
                          courseId: widget.courseId,
                          courseTitle: data['title'] ?? 'Cours',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildChoiceCard(
                  context: context,
                  title: 'Passer le quiz',
                  subtitle: '${quiz.length} question(s) disponible(s)',
                  icon: Icons.quiz_outlined,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          courseId: widget.courseId,
                          courseTitle: data['title'] ?? 'Cours',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
