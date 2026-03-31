import 'package:flutter/material.dart';

class Step2QuizCreation extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onUpdate;

  const Step2QuizCreation({
    super.key,
    required this.data,
    required this.onUpdate,
  });

  @override
  State<Step2QuizCreation> createState() => _Step2QuizCreationState();
}

class _Step2QuizCreationState extends State<Step2QuizCreation> {
  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    // Charger les questions existantes si elles existent
    if (widget.data['quiz'] != null && widget.data['quiz'].isNotEmpty) {
      _questions.addAll(List<Map<String, dynamic>>.from(widget.data['quiz']));
    }
  }

  void _addQuestion() {
    if (_questions.length >= 5) return;

    setState(() {
      _questions.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'qcm',
        'text': '',
        'options': [
          {'text': '', 'isCorrect': false, 'id': 'A'},
          {'text': '', 'isCorrect': false, 'id': 'B'},
        ],
        'explanation': '',
      });
    });
    _saveQuestions();
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
    _saveQuestions();
  }

  void _addOption(int questionIndex) {
    final currentOptions = _questions[questionIndex]['options'] as List;
    if (currentOptions.length >= 4) return; // Max 4 options

    setState(() {
      _questions[questionIndex]['options'].add({
        'text': '',
        'isCorrect': false,
        'id': String.fromCharCode(65 + currentOptions.length), // C, D...
      });
    });
    _saveQuestions();
  }

  void _removeOption(int qIndex, int oIndex) {
    final options = _questions[qIndex]['options'] as List;
    if (options.length <= 2) return; // Min 2 options

    setState(() {
      options.removeAt(oIndex);
      // Recalculer les IDs
      for (var i = 0; i < options.length; i++) {
        options[i]['id'] = String.fromCharCode(65 + i);
      }
    });
    _saveQuestions();
  }

  void _setCorrectAnswer(int qIndex, int oIndex) {
    setState(() {
      final options = _questions[qIndex]['options'] as List;
      for (var i = 0; i < options.length; i++) {
        options[i]['isCorrect'] = i == oIndex;
      }
    });
    _saveQuestions();
  }

  void _updateQuestionText(int index, String text) {
    _questions[index]['text'] = text;
    _saveQuestions();
  }

  void _updateOptionText(int qIndex, int oIndex, String text) {
    (_questions[qIndex]['options'] as List)[oIndex]['text'] = text;
    _saveQuestions();
  }

  void _updateExplanation(int index, String text) {
    _questions[index]['explanation'] = text;
    _saveQuestions();
  }

  void _saveQuestions() {
    widget.onUpdate('quiz', _questions);
  }

  bool _hasCorrectAnswer(int qIndex) {
    final options = _questions[qIndex]['options'] as List;
    return options.any((o) => o['isCorrect'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz: ${widget.data['title'] ?? 'Nouveau cours'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_questions.length} question(s) créée(s)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF84CC16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.quiz, color: Colors.black, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Message si pas de questions
          if (_questions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Commencez par ajouter une question',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

          // Liste des questions
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(index, question);
          }),

          // Bouton ajouter question
          const SizedBox(height: 16),
          if (_questions.length < 5)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add, color: Color(0xFF84CC16)),
                label: const Text(
                  'Ajouter une question',
                  style: TextStyle(
                    color: Color(0xFF84CC16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF84CC16), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final hasCorrect = _hasCorrectAnswer(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCorrect
              ? Colors.grey.shade800
              : Colors.orange.withOpacity(0.5),
          width: hasCorrect ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header question
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF84CC16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Q${index + 1}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!hasCorrect)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Réponse requise',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(index),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Énoncé
                Text(
                  'Énoncé de la question',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: question['text'],
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputDecoration('Saisissez votre question...'),
                  onChanged: (v) => _updateQuestionText(index, v),
                ),

                const SizedBox(height: 20),

                // Options de réponse
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Options de réponse',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Sélectionnez la bonne réponse',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...((question['options'] as List).asMap().entries.map((entry) {
                  final optIndex = entry.key;
                  final option = entry.value as Map<String, dynamic>;
                  return _buildOptionRow(index, optIndex, option);
                })),

                // Ajouter option
                if ((question['options'] as List).length < 4)
                  TextButton.icon(
                    onPressed: () => _addOption(index),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Ajouter une option'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF84CC16),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),

                const SizedBox(height: 16),

                // Explication
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: Colors.grey,
                  iconColor: const Color(0xFF84CC16),
                  title: Text(
                    'Explication (optionnel)',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    TextFormField(
                      initialValue: question['explanation'],
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Expliquez pourquoi c\'est la bonne réponse...',
                      ),
                      onChanged: (v) => _updateExplanation(index, v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int qIndex, int oIndex, Map<String, dynamic> option) {
    final isCorrect = option['isCorrect'] as bool;
    final optionId = option['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Radio button
          GestureDetector(
            onTap: () => _setCorrectAnswer(qIndex, oIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect ? const Color(0xFF84CC16) : Colors.transparent,
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF84CC16)
                      : Colors.grey.shade600,
                  width: 2.5,
                ),
              ),
              child: isCorrect
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Lettre A, B, C, D
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF84CC16).withOpacity(0.2)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect
                    ? const Color(0xFF84CC16)
                    : Colors.grey.shade700,
              ),
            ),
            child: Center(
              child: Text(
                optionId,
                style: TextStyle(
                  color: isCorrect ? const Color(0xFF84CC16) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Champ texte
          Expanded(
            child: TextFormField(
              initialValue: option['text'],
              style: TextStyle(
                color: isCorrect ? const Color(0xFF84CC16) : Colors.white,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: 'Option $optionId',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: isCorrect
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF84CC16),
                        size: 20,
                      )
                    : null,
              ),
              onChanged: (v) => _updateOptionText(qIndex, oIndex, v),
            ),
          ),

          // Supprimer option
          if ((_questions[qIndex]['options'] as List).length > 2)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
              onPressed: () => _removeOption(qIndex, oIndex),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Supprimer la question ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeQuestion(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF84CC16), width: 1),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
