import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';


class Step1CourseInfo extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onUpdate;
  final List<String> categories;

  const Step1CourseInfo({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.categories,
  });

  @override
  State<Step1CourseInfo> createState() => _Step1CourseInfoState();
}

class _Step1CourseInfoState extends State<Step1CourseInfo> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _levels = ['Débutant', 'Intermédiaire', 'Avancé'];

  List<String> _resolvedCategories() {
    final categories = widget.categories
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final selectedCategory = (widget.data['category'] as String?)?.trim() ?? '';
    if (selectedCategory.isNotEmpty && !categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }

    return categories;
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'ppt',
        'pptx',
        'mp4',
        'mov',
        'avi',
        'xls',
        'xlsx',
      ],
      allowMultiple: true,
    );

    if (result != null) {
      final newFiles = result.files
          .map(
            (f) => {
              'name': f.name,
              'path': f.path,
              'size': f.size,
              'type': _getFileType(f.extension),
            },
          )
          .toList();

      final updatedFiles = [...widget.data['files'], ...newFiles];
      widget.onUpdate('files', updatedFiles);
    }
  }

  String _getFileType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'ppt':
      case 'pptx':
        return 'presentation';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'xls':
      case 'xlsx':
        return 'excel';
      default:
        return 'unknown';
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

  @override
  Widget build(BuildContext context) {
    final availableCategories = _resolvedCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du cours
            _buildLabel('Titre du cours', true),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.data['title'],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Ex: Maîtriser React en 30 jours'),
              validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              onChanged: (v) => widget.onUpdate('title', v),
            ),

            const SizedBox(height: 20),

            // Catégorie
            _buildLabel('Catégorie', true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue:
                  availableCategories.contains(widget.data['category'])
                  ? widget.data['category']
                  : null,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                availableCategories.isEmpty
                    ? 'Aucun domaine d\'expertise disponible'
                    : 'Sélectionnez une catégorie',
              ),
              items: availableCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: availableCategories.isEmpty
                  ? null
                  : (v) => widget.onUpdate('category', v),
              validator: (v) {
                if (availableCategories.isEmpty) {
                  return 'Ajoutez un domaine d\'expertise dans votre profil';
                }
                return v == null ? 'Sélectionnez une catégorie' : null;
              },
            ),

            const SizedBox(height: 20),

            // Niveau (Segmented control)
            _buildLabel('Niveau', true),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: _levels.map((level) {
                  final isSelected = widget.data['level'] == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onUpdate('level', level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF84CC16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          level,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            _buildLabel('Description', true),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.data['description'],
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: _inputDecoration(
                'Décrivez ce que les apprenants vont apprendre...',
              ),
              //   validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
              onChanged: (v) => widget.onUpdate('description', v),
            ),

            const SizedBox(height: 24),

            // Upload de fichiers
            _buildLabel('Contenu du cours', true),
            const SizedBox(height: 8),
            Text(
              'PDF, PowerPoint, Vidéo ou Excel',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Zone d'upload
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF84CC16).withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF84CC16).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 32,
                        color: Color(0xFF84CC16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cliquez pour télécharger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, PPT, PPTX, MP4 jusqu\'à 100MB',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Liste des fichiers uploadés
            if (widget.data['files'].isNotEmpty) ...[
              const SizedBox(height: 16),
              ...widget.data['files'].asMap().entries.map<Widget>((entry) {
                return _buildFileItem(entry.value, entry.key);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file, int index) {
    final fileType = file['type'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFileColor(fileType).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(fileType),
              color: _getFileColor(fileType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${((file['size'] ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB • ${_getFileTypeLabel(fileType)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () {
              final updated = [...widget.data['files']];
              updated.removeAt(index);
              widget.onUpdate('files', updated);
            },
          ),
        ],
      ),
    );
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

  Widget _buildLabel(String text, bool required) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF84CC16), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
