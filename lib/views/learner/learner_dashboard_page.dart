import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../services/course_service.dart';
import 'completed_courses_page.dart';
import 'enrolled_courses_page.dart';
import 'explore_courses_page.dart';
import 'progress_page.dart';

class LearnerDashboardPage extends StatefulWidget {
  const LearnerDashboardPage({super.key});

  @override
  State<LearnerDashboardPage> createState() => _LearnerDashboardPageState();
}

class _LearnerDashboardPageState extends State<LearnerDashboardPage> {
  final CourseService _courseService = CourseService();
  static const int _kpiWindowMinutes = 15;
  StreamSubscription<int>? _kpiSubscription;
  Timer? _minuteTimer;
  int _currentCompletedKpi = 0;
  final List<int> _last7MinutesKpi = List<int>.filled(_kpiWindowMinutes, 0);

  Future<void> _refreshDashboard() async {
    await context.read<ProfileProvider>().loadUser();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void initState() {
    super.initState();
    _startKpiTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUser();
    });
  }

  @override
  void dispose() {
    _kpiSubscription?.cancel();
    _minuteTimer?.cancel();
    super.dispose();
  }

  void _startKpiTracking() {
    _kpiSubscription = _courseService.getCompletedKpiCount().listen((value) {
      if (!mounted) return;
      setState(() {
        _currentCompletedKpi = value;
        _last7MinutesKpi[_last7MinutesKpi.length - 1] = value;
      });
    });

    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _last7MinutesKpi.removeAt(0);
        _last7MinutesKpi.add(_currentCompletedKpi);
      });
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
            padding: const EdgeInsets.all(20),
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
    final int maxValue = _last7MinutesKpi.isEmpty
        ? 0
        : _last7MinutesKpi.reduce(math.max);
    final double maxY = math.max(4, maxValue + 1).toDouble();
    final double interval = maxY <= 8 ? 1 : (maxY / 4).ceilToDouble();
    final int maxX = _kpiWindowMinutes - 1;

    final List<FlSpot> spots = _last7MinutesKpi
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activité 15 minutes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KPI des cours terminés (15 dernières minutes)',
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF84CC16),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_currentCompletedKpi',
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
                      interval: interval,
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
                        final int minuteIndex = value.toInt();
                        if (minuteIndex < 0 || minuteIndex > maxX) {
                          return const SizedBox.shrink();
                        }

                        if (minuteIndex != maxX && minuteIndex % 3 != 0) {
                          return const SizedBox.shrink();
                        }

                        final String label = minuteIndex == maxX
                            ? 'Now'
                            : '-${maxX - minuteIndex}m';

                        return Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxX.toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
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
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _courseService.getEnrolledCourses(),
          builder: (context, enrolledSnapshot) {
            if (enrolledSnapshot.connectionState == ConnectionState.waiting &&
                !enrolledSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF84CC16)),
                ),
              );
            }

            if (enrolledSnapshot.hasError) {
              return Text(
                'Erreur de chargement des cours suivis',
                style: TextStyle(color: Colors.red.shade300),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _courseService.getInProgressCourses(),
              builder: (context, inProgressSnapshot) {
                if (inProgressSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !inProgressSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF84CC16),
                      ),
                    ),
                  );
                }

                if (inProgressSnapshot.hasError) {
                  return Text(
                    'Erreur de chargement des cours en progression',
                    style: TextStyle(color: Colors.red.shade300),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _courseService.getCompletedCourses(),
                  builder: (context, completedSnapshot) {
                    if (completedSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !completedSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF84CC16),
                          ),
                        ),
                      );
                    }

                    if (completedSnapshot.hasError) {
                      return Text(
                        'Erreur de chargement des cours terminés',
                        style: TextStyle(color: Colors.red.shade300),
                      );
                    }

                    final List<Map<String, String>> items = [];

                    for (final doc in enrolledSnapshot.data?.docs ?? []) {
                      final data = doc.data();
                      items.add({
                        'title': data['title'] ?? 'Sans titre',
                        'status': 'Cours suivis',
                      });
                    }

                    for (final doc in inProgressSnapshot.data?.docs ?? []) {
                      final data = doc.data();
                      items.add({
                        'title': data['title'] ?? 'Sans titre',
                        'status': 'Progression',
                      });
                    }

                    for (final doc in completedSnapshot.data?.docs ?? []) {
                      final data = doc.data();
                      items.add({
                        'title': data['title'] ?? 'Sans titre',
                        'status': 'Terminés',
                      });
                    }

                    if (items.isEmpty) {
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

                    return Column(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 12,
                          ),
                          child: _buildCourseItem(
                            title: item['title']!,
                            subtitle: item['status']!,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseItem({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
