import 'package:flutter/material.dart';
import 'steps/step1_course_info.dart';
import 'steps/step2_quiz_creation.dart';
import '../../../services/course_service.dart';

class CourseCreationWizardPage extends StatefulWidget {
  final String? courseId;
  final Map<String, dynamic>? initialData;

  const CourseCreationWizardPage({super.key, this.courseId, this.initialData});

  @override
  State<CourseCreationWizardPage> createState() =>
      _CourseCreationWizardPageState();
}

class _CourseCreationWizardPageState extends State<CourseCreationWizardPage> {
  int _currentStep = 0;

  late Map<String, dynamic> _courseData;

  final List<String> _stepTitles = [
    'Informations du cours',
    'Création du quiz',
  ];

  final CourseService _courseService = CourseService();
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();

    _courseData = {
      'title': '',
      'category': '',
      'level': 'Débutant',
      'description': '',
      'files': [],
      'quiz': [],
    };

    if (widget.initialData != null) {
      _courseData = {
        'title': widget.initialData!['title'] ?? '',
        'category': widget.initialData!['category'] ?? '',
        'level': widget.initialData!['level'] ?? 'Débutant',
        'description': widget.initialData!['description'] ?? '',
        'files': List<Map<String, dynamic>>.from(
          widget.initialData!['files'] ?? [],
        ),
        'quiz': List<Map<String, dynamic>>.from(
          widget.initialData!['quiz'] ?? [],
        ),
      };
    }
  }

  void _updateCourseData(String key, dynamic value) {
    setState(() {
      _courseData[key] = value;
    });
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canGoNext() {
    if (_currentStep == 0) {
      return (_courseData['title'] as String).trim().isNotEmpty &&
          (_courseData['category'] as String).trim().isNotEmpty &&
          (_courseData['description'] as String).trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _publishCourse() async {
    if ((_courseData['title'] as String).trim().isEmpty ||
        (_courseData['category'] as String).trim().isEmpty ||
        (_courseData['description'] as String).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les informations du cours.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isPublishing = true;
      });

      if (widget.courseId == null) {
        await _courseService.createCourse(
          title: _courseData['title'],
          category: _courseData['category'],
          level: _courseData['level'],
          description: _courseData['description'],
          files: List<Map<String, dynamic>>.from(_courseData['files']),
          quiz: List<Map<String, dynamic>>.from(_courseData['quiz']),
        );
      } else {
        await _courseService.updateCourse(
          courseId: widget.courseId!,
          title: _courseData['title'],
          category: _courseData['category'],
          level: _courseData['level'],
          description: _courseData['description'],
          files: List<Map<String, dynamic>>.from(_courseData['files']),
          quiz: List<Map<String, dynamic>>.from(_courseData['quiz']),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.courseId == null
                ? 'Cours créé avec succès'
                : 'Cours modifié avec succès',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.courseId == null
                ? 'Erreur lors de la création du cours : $e'
                : 'Erreur lors de la modification du cours : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1CourseInfo(data: _courseData, onUpdate: _updateCourseData);
      case 1:
        return Step2QuizCreation(
          data: _courseData,
          onUpdate: _updateCourseData,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(2, (index) {
          final bool isActive = index == _currentStep;
          final bool isDone = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isActive
                        ? const Color(0xFF84CC16)
                        : const Color(0xFF1E293B),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.black, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: index < _currentStep
                          ? const Color(0xFF84CC16)
                          : const Color(0xFF1E293B),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.courseId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          children: [
            Text(
              isEditMode ? 'Modifier le cours' : 'Créer un cours',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _stepTitles[_currentStep],
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Retour',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPublishing
                      ? null
                      : _currentStep == 1
                      ? _publishCourse
                      : (_canGoNext() ? _nextStep : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 1
                              ? (isEditMode ? 'Enregistrer' : 'Publier')
                              : 'Continuer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
