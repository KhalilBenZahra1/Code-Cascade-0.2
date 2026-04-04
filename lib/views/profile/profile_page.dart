import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';

class ProfilePage extends StatefulWidget {
  final bool forceExpertiseSetup;

  const ProfilePage({super.key, this.forceExpertiseSetup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    'Autre',
  ];

  bool _routeArgsInitialized = false;
  bool _mustCompleteExpertise = false;
  bool _mandatoryDialogOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadUser();
      if (!mounted) return;
      await _ensureMandatoryExpertiseFlow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _mustCompleteExpertise =
          widget.forceExpertiseSetup || (args['forceExpertiseSetup'] == true);
    } else {
      _mustCompleteExpertise = widget.forceExpertiseSetup;
    }

    _routeArgsInitialized = true;
  }

  Future<void> _ensureMandatoryExpertiseFlow() async {
    if (!_mustCompleteExpertise || _mandatoryDialogOpened) {
      return;
    }

    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.isCurrent != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensureMandatoryExpertiseFlow();
        }
      });
      return;
    }

    final provider = context.read<ProfileProvider>();
    if (provider.isLoading) {
      return;
    }

    if (!provider.isTrainer || provider.expertises.isNotEmpty) {
      if (mounted) {
        setState(() {
          _mustCompleteExpertise = false;
        });
      }
      return;
    }

    _mandatoryDialogOpened = true;
    try {
      await _showExpertisesDialog(provider, mandatory: true);
    } finally {
      _mandatoryDialogOpened = false;
    }

    if (!mounted) return;

    final refreshedProvider = context.read<ProfileProvider>();
    if (refreshedProvider.isTrainer &&
        refreshedProvider.expertises.isNotEmpty) {
      setState(() {
        _mustCompleteExpertise = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/trainer/dashboard');
      });
    }
  }

  Future<void> _showEditTextDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(title, style: const TextStyle(color: Colors.white)),
              content: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF84CC16)),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await onSave(value);

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            // Cas email
                            if (title.toLowerCase().contains('email')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Un email de confirmation a été envoyé. Le changement sera effectif après validation.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              // Cas normal (nom, etc.)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Modification enregistrée'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: Colors.black,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showExpertisesDialog(
    ProfileProvider provider, {
    bool mandatory = false,
  }) async {
    final standardExpertises = _expertiseList
        .where((e) => e != 'Autre')
        .toSet();
    final selected = provider.expertises
        .where((e) => standardExpertises.contains(e))
        .toList();
    final customExpertises = provider.expertises
        .where((e) => !standardExpertises.contains(e))
        .toList();
    final otherController = TextEditingController(
      text: customExpertises.isNotEmpty ? customExpertises.first : '',
    );
    if (customExpertises.isNotEmpty && !selected.contains('Autre')) {
      selected.add('Autre');
    }

    final selectedForSubmit = await showDialog<List<String>>(
      context: context,
      barrierDismissible: !mandatory,
      builder: (dialogContext) {
        bool showError = false;

        bool hasValidSelection() {
          final hasStandard = selected.any((e) => e != 'Autre');
          final hasCustom =
              selected.contains('Autre') &&
              otherController.text.trim().isNotEmpty;
          return hasStandard || hasCustom;
        }

        List<String> buildExpertisesForSubmit() {
          final values = selected
              .where((e) => e != 'Autre')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet();

          final custom = otherController.text.trim();
          if (selected.contains('Autre') && custom.isNotEmpty) {
            values.add(custom);
          }

          return values.toList();
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Modifier les expertises',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mandatory)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Choisissez au moins un domaine pour continuer.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _expertiseList.map((expertise) {
                        final isSelected = selected.contains(expertise);

                        return FilterChip(
                          label: Text(expertise),
                          selected: isSelected,
                          onSelected: (value) {
                            setDialogState(() {
                              if (value) {
                                selected.add(expertise);
                              } else {
                                selected.remove(expertise);
                                if (expertise == 'Autre') {
                                  otherController.clear();
                                }
                              }

                              if (hasValidSelection()) {
                                showError = false;
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
                        );
                      }).toList(),
                    ),
                    if (selected.contains('Autre')) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otherController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Precisez votre domaine',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) {
                          if (showError && hasValidSelection()) {
                            setDialogState(() {
                              showError = false;
                            });
                          }
                        },
                      ),
                    ],
                    if (showError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Selectionnez au moins une expertise',
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!mandatory)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (!hasValidSelection()) {
                      setDialogState(() {
                        showError = true;
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, buildExpertisesForSubmit());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    otherController.dispose();

    if (selectedForSubmit == null) {
      return;
    }

    try {
      await provider.updateExpertises(selectedForSubmit);

      if (!mounted) return;

      if (mandatory) {
        if (mounted) {
          setState(() {
            _mustCompleteExpertise = false;
          });
        }

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/app-router',
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expertises mises a jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );

      if (mandatory) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureMandatoryExpertiseFlow();
        });
      }
    }
  }

  Future<void> _showPasswordDialog(ProfileProvider provider) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        bool hideCurrent = true;
        bool hideNew = true;
        bool hideConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Modifier le mot de passe',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordField(
                      controller: currentPasswordController,
                      hint: 'Mot de passe actuel',
                      obscureText: hideCurrent,
                      onToggle: () {
                        setDialogState(() {
                          hideCurrent = !hideCurrent;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: newPasswordController,
                      hint: 'Nouveau mot de passe',
                      obscureText: hideNew,
                      onToggle: () {
                        setDialogState(() {
                          hideNew = !hideNew;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      hint: 'Confirmer le nouveau mot de passe',
                      obscureText: hideConfirm,
                      onToggle: () {
                        setDialogState(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentPassword = currentPasswordController.text
                              .trim();
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword = confirmPasswordController.text
                              .trim();

                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Remplissez tous les champs'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Le nouveau mot de passe doit contenir au moins 6 caractères',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La confirmation du mot de passe est incorrecte',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await provider.changePassword(
                              currentPassword: currentPassword,
                              newPassword: newPassword,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mot de passe mis à jour'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: Colors.black,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF84CC16)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF84CC16)),
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF84CC16)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_mustCompleteExpertise,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          automaticallyImplyLeading: !_mustCompleteExpertise,
          centerTitle: true,
          title: const Text(
            'Mon profil',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF84CC16)),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF84CC16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        provider.getInitials(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildProfileRow(
                    icon: Icons.person_outline,
                    label: 'Nom complet',
                    value: provider.displayName,
                    onEdit: () {
                      _showEditTextDialog(
                        title: 'Modifier le nom complet',
                        initialValue: provider.displayName,
                        onSave: (value) => provider.updateDisplayName(value),
                      );
                    },
                  ),

                  _buildProfileRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: provider.email,
                    onEdit: () {
                      _showEditTextDialog(
                        title: "Modifier l'email",
                        initialValue: provider.email,
                        keyboardType: TextInputType.emailAddress,
                        onSave: (value) => provider.updateEmailOnly(value),
                      );
                    },
                  ),

                  _buildProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'Rôle',
                    value: provider.role,
                  ),

                  if (provider.isTrainer)
                    _buildProfileRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Expertises',
                      value: provider.expertises.isEmpty
                          ? 'Aucune expertise'
                          : provider.expertises.join(', '),
                      onEdit: () {
                        _showExpertisesDialog(provider);
                      },
                    ),

                  _buildProfileRow(
                    icon: Icons.lock_outline,
                    label: 'Mot de passe',
                    value: '••••••••',
                    onEdit: () {
                      _showPasswordDialog(provider);
                    },
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _mustCompleteExpertise
                          ? null
                          : () async {
                              try {
                                await provider.signOut();
                                if (!context.mounted) return;

                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur : $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.logout),
                      label: const Text('Déconnexion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
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
          },
        ),
      ),
    );
  }
}
