import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

// Écran d'authentification amélioré avec un design professionnel
class EnhancedAuthScreen extends StatefulWidget {
  const EnhancedAuthScreen({super.key});

  @override
  State<EnhancedAuthScreen> createState() => _EnhancedAuthScreenState();
}

class _EnhancedAuthScreenState extends State<EnhancedAuthScreen> with SingleTickerProviderStateMixin {
  // Contrôleurs pour les champs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // Animation controller pour les transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // État
  bool _isLogin = true; // true pour connexion, false pour inscription
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialiser les animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Démarrer l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Basculer entre connexion et inscription
  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;

      // Réinitialiser l'animation
      _animationController.reset();
      _animationController.forward();
    });
  }

  // Afficher/masquer le mot de passe
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // Soumettre le formulaire
  Future<void> _submitForm() async {
    // Masquer le clavier
    FocusScope.of(context).unfocus();

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        try {
          // Connexion
          final user = await authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (mounted) {
            // Redirection manuelle en fonction du statut d'administrateur
            // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
            Future.microtask(() {
              if (mounted) {
                if (user.isAdmin) {
                  context.go('/admin/dashboard');
                } else {
                  context.go('/dashboard');
                }
              }
            });
          }
        } catch (authError) {
          // Vérifier si l'erreur est liée à la vérification d'email
          String errorMsg = authError.toString();
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring('Exception: '.length);
          }

          if (errorMsg == AppConstants.errorEmailNotVerified) {
            // Rediriger vers l'écran de vérification d'email
            if (mounted) {
              final email = _emailController.text.trim();

              // Tenter de se connecter sans vérification d'email pour obtenir l'utilisateur
              try {
                await authService.signIn(
                  email: email,
                  password: _passwordController.text,
                  requireEmailVerification: false, // Ne pas exiger la vérification d'email
                );

                // Envoyer un email de vérification
                await authService.sendEmailVerification();

                // Rediriger vers l'écran de vérification d'email
                // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
                Future.microtask(() {
                  if (mounted) {
                    context.go('/verify-email?email=$email');
                  }
                });
                return;
              } catch (innerError) {
                // Si la connexion échoue pour une autre raison, relancer l'erreur originale
                throw authError;
              }
            }
          }

          // Relancer l'erreur pour qu'elle soit traitée par le bloc catch externe
          rethrow;
        }
      } else {
        // Inscription
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        if (mounted) {
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.successRegistration),
              backgroundColor: AppTheme.accentColor,
            ),
          );

          // Redirection manuelle vers le tableau de bord
          // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
          Future.microtask(() {
            if (mounted) {
              context.go('/dashboard');
            }
          });
        }
      }
    } catch (e) {
      // Extraire le message d'erreur sans le préfixe "Exception: "
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Naviguer vers l'écran de réinitialisation de mot de passe
  void _navigateToResetPassword() {
    // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
    Future.microtask(() {
      if (mounted) {
        context.go('/reset-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pas besoin de dimensions d'écran pour l'instant

    return Scaffold(
      // Utiliser un fond avec dégradé
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withAlpha(204), // 0.8 * 255 = 204
              Colors.white,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 450, // Limiter la largeur sur les grands écrans
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo et titre
                              _buildHeader(),

                              const SizedBox(height: 24),

                              // Message d'erreur
                              if (_errorMessage != null) _buildErrorMessage(),

                              // Champs du formulaire
                              _buildFormFields(),

                              const SizedBox(height: 24),

                              // Bouton principal
                              PrimaryButton(
                                text: _isLogin ? AppConstants.loginButton : AppConstants.registerButton,
                                onPressed: _submitForm,
                                isLoading: _isLoading,
                              ),

                              const SizedBox(height: 16),

                              // Options supplémentaires
                              _buildAdditionalOptions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construire l'en-tête avec logo et titre
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(77), // 0.3 * 255 = 77
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/bee-logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),

        // Titre de l'application
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Sous-titre
        Text(
          _isLogin ? AppConstants.loginTitle : AppConstants.registerTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryColor.withAlpha(179), // 0.7 * 255 = 179
          ),
        ),
      ],
    );
  }

  // Construire le message d'erreur
  Widget _buildErrorMessage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.errorColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Construire les champs du formulaire
  Widget _buildFormFields() {
    return Column(
      children: [
        // Nom complet (inscription uniquement)
        if (!_isLogin) ...[
          _buildTextField(
            controller: _fullNameController,
            label: AppConstants.fullNameLabel,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom complet';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        // Email
        _buildTextField(
          controller: _emailController,
          label: AppConstants.emailLabel,
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre email';
            }
            if (!value.contains('@')) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Mot de passe
        _buildTextField(
          controller: _passwordController,
          label: AppConstants.passwordLabel,
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.mediumColor,
            ),
            onPressed: _togglePasswordVisibility,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre mot de passe';
            }
            if (!_isLogin && value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
        ),

        // Téléphone (inscription uniquement)
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: AppConstants.phoneLabel,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ],
    );
  }

  // Construire un champ de texte personnalisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppTheme.secondaryColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Construire les options supplémentaires
  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        // Lien pour basculer entre connexion et inscription
        TextButton(
          onPressed: _toggleAuthMode,
          child: Text(
            _isLogin ? AppConstants.noAccount : AppConstants.alreadyAccount,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Lien pour mot de passe oublié (connexion uniquement)
        if (_isLogin) ...[
          TextButton(
            onPressed: _navigateToResetPassword,
            child: const Text(
              AppConstants.forgotPassword,
              style: TextStyle(
                color: AppTheme.mediumColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
