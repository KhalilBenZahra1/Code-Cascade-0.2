import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/course_service.dart';

class LearnersListPage extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const LearnersListPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  List<String> _extractUniqueLearnerIds(Map<String, dynamic> data) {
    final rawIds = [
      ...List<dynamic>.from(data['enrolledLearnerIds'] ?? const []),
      ...List<dynamic>.from(data['inProgressLearnerIds'] ?? const []),
      ...List<dynamic>.from(data['completedLearnerIds'] ?? const []),
    ];

    // Normalize IDs to prevent duplicates caused by unexpected whitespace.
    return rawIds
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apprenants du cour',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              courseTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(
              child: Text(
                'Cours introuvable',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final learnerIds = _extractUniqueLearnerIds(data);

          if (learnerIds.isEmpty) {
            return const Center(
              child: Text(
                'Aucun apprenant dans ce cours',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: learnerIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final learnerId = learnerIds[index];

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(learnerId)
                    .get(),
                builder: (context, learnerSnapshot) {
                  final learnerData = learnerSnapshot.data?.data();
                  final fullName = learnerData?['fullName'] ?? 'Apprenant';
                  final email = learnerData?['email'] ?? 'Email indisponible';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
