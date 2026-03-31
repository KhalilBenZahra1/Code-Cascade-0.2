import 'package:flutter/material.dart';
import 'course_creation/course_creation_wizard_page.dart';

class CourseBuilderPage extends StatelessWidget {
  final String? courseId;
  final Map<String, dynamic>? initialData;

  const CourseBuilderPage({super.key, this.courseId, this.initialData});

  @override
  Widget build(BuildContext context) {
    return CourseCreationWizardPage(
      courseId: courseId,
      initialData: initialData,
    );
  }
}
