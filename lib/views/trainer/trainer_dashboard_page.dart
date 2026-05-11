import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/course_service.dart';
import 'course_builder_page.dart';
import 'courses_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class TrainerDashboardPage extends StatefulWidget {
  const TrainerDashboardPage({super.key});

  @override
  State<TrainerDashboardPage> createState() => _TrainerDashboardPageState();
}

class _TrainerDashboardPageState extends State<TrainerDashboardPage> {
  final CourseService _courseService = CourseService();
  static const int _chartWindowDays = 30;

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
        child: SingleChildScrollView(
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseBuilderPage()),
          );
        },
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: CourseService().getTrainerLearnersCount(),
            builder: (context, snapshot) {
              final int learnersCount = snapshot.data ?? 0;

              return _buildStatCard(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                value: learnersCount.toString(),
                label: 'Apprenants',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CoursesListPage(showLearnersOnCourseTap: true),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<int>(
            stream: CourseService().getTrainerCoursesCount(),
            builder: (context, snapshot) {
              final int courseCount = snapshot.data ?? 0;

              return _buildStatCard(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF84CC16),
                value: courseCount.toString(),
                label: 'Cours',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoursesListPage(),
                    ),
                  );
                },
              );
            },
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _courseService.getTrainerCourses(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? [];

      final List<int> dayBuckets = List<int>.filled(_chartWindowDays, 0);
      final DateTime today = DateTime.now();
      final DateTime startDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: _chartWindowDays - 1));

      for (final doc in docs) {
        final Timestamp? timestamp = doc.data()['createdAt'] as Timestamp?;

        if (timestamp == null) continue;

        final DateTime createdAt = timestamp.toDate();

        if (createdAt.isBefore(startDate)) continue;

        final DateTime courseDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );

        final int index = courseDate.difference(startDate).inDays;

        if (index >= 0 && index < _chartWindowDays) {
          dayBuckets[index]++;
        }
      }

      final int totalCourses = dayBuckets.fold(0, (sum, value) => sum + value);
      final int maxValue = dayBuckets.isEmpty ? 0 : dayBuckets.reduce(math.max);

      final double maxY = math.max(4, maxValue + 1).toDouble();
      final double interval = maxY <= 8 ? 1 : (maxY / 4).ceilToDouble();

      final List<FlSpot> spots = dayBuckets
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
          .toList();

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activité 30 jours',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cours créés pendant les 30 derniers jours',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84CC16).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_chart,
                        color: Color(0xFF84CC16),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalCourses',
                        style: const TextStyle(
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
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade800,
                        strokeWidth: 1,
                      );
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
                        interval: interval,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final int dayIndex = value.toInt();

                          if (dayIndex < 0 || dayIndex >= _chartWindowDays) {
                            return const SizedBox.shrink();
                          }

                          if (dayIndex % 5 != 0 && dayIndex != _chartWindowDays - 1) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            'J${dayIndex + 1}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (_chartWindowDays - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF84CC16),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
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
    },
  );
}

  Widget _buildPopularCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cours populaires',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _courseService.getTrainerPopularCourses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF84CC16)),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Erreur de chargement des cours populaires',
                style: TextStyle(color: Colors.red.shade300),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aucun cours pour le moment',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final courses = docs.map((doc) {
              final data = doc.data();

              final learners = <String>{
                ...List<String>.from(data['enrolledLearnerIds'] ?? []),
                ...List<String>.from(data['inProgressLearnerIds'] ?? []),
                ...List<String>.from(data['completedLearnerIds'] ?? []),
              };

              final completed = List<String>.from(
                data['completedLearnerIds'] ?? [],
              );

              final int learnersCount = learners.length;
              final int completedCount = completed.length;

              final double progress = learnersCount == 0
                  ? 0
                  : completedCount / learnersCount;

              return {
                'title': data['title'] ?? 'Sans titre',
                'students': learnersCount,
                'progress': progress,
                'percentage': (progress * 100).round().toString(),
              };
            }).toList();

            courses.sort(
              (a, b) => (b['students'] as int).compareTo(a['students'] as int),
            );

            final popularCourses = courses.take(3).toList();

            return Column(
              children: popularCourses.asMap().entries.map((entry) {
                final index = entry.key;
                final course = entry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == popularCourses.length - 1 ? 0 : 12,
                  ),
                  child: _buildCourseItem(
                    title: course['title'] as String,
                    students: course['students'] as int,
                    progress: course['progress'] as double,
                    percentage: course['percentage'] as String,
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
    required int students,
    required double progress,
    required String percentage,
  }) {
    return Container(
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
            '$students apprenants',
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
    );
  }
}
