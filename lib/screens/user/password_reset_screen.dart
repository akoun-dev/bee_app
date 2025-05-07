import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

// Écran de réinitialisation de mot de passe
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> with SingleTickerProviderStateMixin {
  // Contrôleur pour le champ de texte
  final TextEditingController _emailController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // État
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSent = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController.dispose();
    super.dispose();
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
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _resetSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Extraire le message d'erreur sans le préfixe "Exception: "
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  // Retourner à l'écran de connexion
  void _navigateToLogin() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
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
                        child: _resetSent ? _buildSuccessMessage() : _buildResetForm(),
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

  // Construire le formulaire de réinitialisation
  Widget _buildResetForm() {
    return Form(
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

          // Champ email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: AppConstants.emailLabel,
              prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
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

          const SizedBox(height: 24),

          // Bouton de réinitialisation
          PrimaryButton(
            text: AppConstants.resetPasswordButton,
            onPressed: _submitForm,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 16),

          // Lien pour retourner à la connexion
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              AppConstants.backToLogin,
              style: TextStyle(
                color: AppTheme.mediumColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construire le message de succès
  Widget _buildSuccessMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppTheme.accentColor,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Un email de réinitialisation a été envoyé à ${_emailController.text}. Veuillez vérifier votre boîte de réception et suivre les instructions.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.mediumColor,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: AppConstants.backToLogin,
          onPressed: _navigateToLogin,
          isLoading: false,
        ),
      ],
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
          child: const Icon(
            Icons.lock_reset,
            size: 40,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Titre
        const Text(
          AppConstants.resetPasswordTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Sous-titre
        const Text(
          AppConstants.resetPasswordSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.mediumColor,
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
}
