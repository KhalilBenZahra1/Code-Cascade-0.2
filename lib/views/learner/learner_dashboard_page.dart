import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../services/course_service.dart';
import 'enrolled_courses_page.dart';
import 'explore_courses_page.dart';
import 'module_list_page.dart';
import 'progress_page.dart';
import 'completed_courses_page.dart';

class LearnerDashboardPage extends StatefulWidget {
  const LearnerDashboardPage({super.key});

  @override
  State<LearnerDashboardPage> createState() => _LearnerDashboardPageState();
}

class _LearnerDashboardPageState extends State<LearnerDashboardPage> {
  final CourseService _courseService = CourseService();
  Future<void> _refreshDashboard() async {
    // Recharge explicitement les données du profil
    await context.read<ProfileProvider>().loadUser();

    // Force un rebuild du dashboard pour remettre à jour
    // les StreamBuilder des cartes et tout le contenu affiché
    if (mounted) {
      setState(() {});
    }

    // Petit délai léger pour rendre le refresh visuel plus propre
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF84CC16),
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildActivityChart(),
                const SizedBox(height: 24),
                _buildPopularCourses(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExploreCoursesPage()),
          );
        },
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.search),
        label: const Text('Explorer'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bienvenue, ${provider.isLoading ? '...' : provider.displayName.split(' ').first}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF84CC16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        provider.isLoading ? '?' : provider.getInitials(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        StreamBuilder<int>(
          stream: _courseService.getEnrolledCoursesCount(),
          builder: (context, snapshot) {
            final int enrolledCount = snapshot.data ?? 0;

            return _buildStatCard(
              icon: Icons.menu_book_outlined,
              iconColor: const Color(0xFF84CC16),
              value: enrolledCount.toString(),
              label: 'Cours suivis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EnrolledCoursesPage(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 12),
        StreamBuilder<int>(
          stream: _courseService.getCompletedCoursesCount(),
          builder: (context, snapshot) {
            final int completedCount = snapshot.data ?? 0;

            return _buildStatCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.blue,
              value: completedCount.toString(),
              label: 'Terminés',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompletedCoursesPage(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 12),
        StreamBuilder<int>(
          stream: _courseService.getInProgressCoursesCount(),
          builder: (context, snapshot) {
            final int inProgressCount = snapshot.data ?? 0;

            return _buildStatCard(
              icon: Icons.trending_up,
              iconColor: Colors.orange,
              value: inProgressCount.toString(),
              label: 'Progression',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressPage()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activité 7 jours',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progression des 7 jours',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF84CC16).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFF84CC16), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Color(0xFF84CC16),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade800, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Lun',
                          'Mar',
                          'Mer',
                          'Jeu',
                          'Ven',
                          'Sam',
                          'Dim',
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 40),
                      FlSpot(1, 50),
                      FlSpot(2, 35),
                      FlSpot(3, 65),
                      FlSpot(4, 55),
                      FlSpot(5, 75),
                      FlSpot(6, 45),
                    ],
                    isCurved: true,
                    color: const Color(0xFF84CC16),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF84CC16),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF84CC16).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCourses() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes cours',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: _courseService.getPublishedCourses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF84CC16),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Erreur de chargement des cours',
                style: TextStyle(color: Colors.red.shade300),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final myActiveCourses = docs.where((doc) {
              final data = doc.data();
              final List enrolled = List.from(data['enrolledLearnerIds'] ?? []);
              final List inProgress = List.from(
                data['inProgressLearnerIds'] ?? [],
              );
              return enrolled.contains(userId) || inProgress.contains(userId);
            }).toList();

            if (myActiveCourses.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aucun cours actif pour le moment',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return Column(
              children: myActiveCourses.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final data = doc.data();

                final String title = data['title'] ?? 'Sans titre';
                final List files = List.from(data['files'] ?? []);
                final int totalParts = files.length * 3;

                final Map<String, dynamic> learnerChecks =
                    Map<String, dynamic>.from(data['learnerFileChecks'] ?? {});
                final Map<String, dynamic> userChecks =
                    learnerChecks[userId] is Map
                    ? Map<String, dynamic>.from(learnerChecks[userId] as Map)
                    : <String, dynamic>{};

                int completedParts = 0;
                for (int fileIndex = 0; fileIndex < files.length; fileIndex++) {
                  final String fileKey = 'f$fileIndex';
                  final Map<String, dynamic> fileChecks =
                      userChecks[fileKey] is Map
                      ? Map<String, dynamic>.from(userChecks[fileKey] as Map)
                      : <String, dynamic>{};

                  for (int partIndex = 0; partIndex < 3; partIndex++) {
                    if (fileChecks['p$partIndex'] == true) {
                      completedParts++;
                    }
                  }
                }

                final double progress = totalParts == 0
                    ? 0
                    : completedParts / totalParts;
                final int percentage = (progress * 100).round();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == myActiveCourses.length - 1 ? 0 : 12,
                  ),
                  child: _buildCourseItem(
                    title: title,
                    subtitle: '$completedParts/$totalParts parties cochées',
                    progress: progress.clamp(0, 1),
                    percentage: percentage.toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModuleListPage(
                            courseId: doc.id,
                            courseTitle: title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseItem({
    required String title,
    required String subtitle,
    required double progress,
    required String percentage,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$percentage %',
                  style: const TextStyle(
                    color: Color(0xFF84CC16),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF84CC16),
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
