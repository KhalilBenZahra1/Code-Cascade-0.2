import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _email;
  final List<String> _selectedExpertises = [];
  String? _password;
  String? _confirmPassword;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _showExpertiseError = false;
  String _selectedRole = 'Apprenant';
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final List<String> _expertiseList = [
    'Flutter',
    'React',
    'React Native',
    'Node.js',
    'Python',
    'Java',
    'Swift',
    'Kotlin',
    'DevOps',
    'UI/UX Design',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: Color(0xFF84CC16),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedRole == 'Formateur'
                      ? 'Créez votre compte'
                      : 'Commencez votre parcours d\'apprentissage',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Je suis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'Apprenant'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'Apprenant'
                                  ? const Color(0xFF84CC16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Apprenant',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'Apprenant'
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'Formateur'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'Formateur'
                                  ? const Color(0xFF84CC16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Formateur',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'Formateur'
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Nom complet',
                  hint: 'Jean Dupont',
                  icon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Entrez votre nom complet';
                    }
                    return null;
                  },
                  onSaved: (value) => _fullName = value,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email',
                  hint: 'votre@email.com',
                  icon: Icons.email_outlined,
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Entrez votre email';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value,
                ),
                if (_selectedRole == 'Formateur') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: 'Domaines d\'expertise',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedExpertises.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF84CC16).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedExpertises.length} sélectionné(s)',
                            style: const TextStyle(
                              color: Color(0xFF84CC16),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _showExpertiseError && _selectedExpertises.isEmpty
                            ? Colors.red
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _expertiseList.map((expertise) {
                        final isSelected = _selectedExpertises.contains(
                          expertise,
                        );
                        return FilterChip(
                          label: Text(expertise),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedExpertises.add(expertise);
                              } else {
                                _selectedExpertises.remove(expertise);
                              }
                              if (_selectedExpertises.isNotEmpty) {
                                _showExpertiseError = false;
                              }
                            });
                          },
                          selectedColor: const Color(0xFF84CC16),
                          backgroundColor: const Color(0xFF0F172A),
                          checkmarkColor: Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF84CC16)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_showExpertiseError && _selectedExpertises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Sélectionnez au moins une expertise',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: 'Mot de passe',
                  hint: _selectedRole == 'Formateur'
                      ? 'Min. 8 caractères'
                      : 'Mot de passe',
                  isConfirm: false,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Entrez votre mot de passe';
                    }
                    if (_selectedRole == 'Formateur' &&
                        (value?.length ?? 0) < 8) {
                      return 'Minimum 8 caractères';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: 'Confirmer le mot de passe',
                  hint: 'Retapez votre mot de passe',
                  isConfirm: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Confirmez votre mot de passe';
                    }
                    return null;
                  },
                  onSaved: (value) => _confirmPassword = value,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF84CC16),
                      checkColor: Colors.black,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'J\'accepte les conditions générales d\'utilisation et la politique de confidentialité',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_acceptTerms && !_isLoading)
                        ? () async {
                            setState(() {
                              _showExpertiseError =
                                  _selectedRole == 'Formateur' &&
                                  _selectedExpertises.isEmpty;
                            });

                            if (!_formKey.currentState!.validate() ||
                                _showExpertiseError) {
                              return;
                            }

                            _formKey.currentState!.save();

                            if (_password != _confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Les mots de passe ne correspondent pas',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              setState(() {
                                _isLoading = true;
                              });

                              final result = await _authService.signUp(
                                fullName: _fullName!,
                                email: _email!,
                                password: _password!,
                                role: _selectedRole,
                                expertises: _selectedRole == 'Formateur'
                                    ? _selectedExpertises
                                    : [],
                              );

                              if (!mounted) return;
                              Navigator.pushReplacementNamed(
                                context,
                                result.targetRoute,
                              );
                            } on FirebaseAuthException catch (e) {
                              if (!mounted) return;

                              String message = 'Une erreur est survenue';
                              if (e.code == 'email-already-in-use') {
                                message = 'Cet email est déjà utilisé';
                              } else if (e.code == 'invalid-email') {
                                message = 'Email invalide';
                              } else if (e.code == 'weak-password') {
                                message = 'Mot de passe trop faible';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(
                        0xFF84CC16,
                      ).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Créer mon compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Color(0xFF84CC16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: const Color(0xFF84CC16)),
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
              borderSide: const BorderSide(color: Color(0xFF84CC16)),
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required bool isConfirm,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    final isVisible = isConfirm
        ? _isConfirmPasswordVisible
        : _isPasswordVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(color: Colors.white),
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF84CC16),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  if (isConfirm) {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  } else {
                    _isPasswordVisible = !_isPasswordVisible;
                  }
                });
              },
            ),
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
              borderSide: const BorderSide(color: Color(0xFF84CC16)),
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }
}