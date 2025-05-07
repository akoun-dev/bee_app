import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

// Écran de vérification d'email
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  Timer? _timer;
  
  // Animation controller pour les transitions
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
    
    // Démarrer la vérification périodique
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  // Démarrer la vérification périodique de l'état de vérification de l'email
  void _startVerificationCheck() {
    // Vérifier toutes les 5 secondes si l'email a été vérifié
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isVerified = await authService.isEmailVerified();
      
      if (isVerified) {
        _timer?.cancel();
        
        if (mounted) {
          // Rediriger vers le tableau de bord
          context.go('/dashboard');
        }
      }
    });
  }

  // Renvoyer l'email de vérification
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.emailVerificationSuccess),
            backgroundColor: AppTheme.accentColor,
          ),
        );
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
  
  // Vérifier manuellement si l'email a été vérifié
  Future<void> _checkEmailVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isVerified = await authService.isEmailVerified();
      
      if (isVerified) {
        if (mounted) {
          // Rediriger vers le tableau de bord
          context.go('/dashboard');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre email n\'a pas encore été vérifié. Veuillez vérifier votre boîte de réception.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // En-tête
                            _buildHeader(),
                            
                            const SizedBox(height: 24),
                            
                            // Message d'erreur
                            if (_errorMessage != null) _buildErrorMessage(),
                            
                            // Message principal
                            Text(
                              AppConstants.emailVerificationMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.mediumColor,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Afficher l'email
                            Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Bouton pour vérifier l'email
                            PrimaryButton(
                              text: AppConstants.checkEmailButton,
                              onPressed: _checkEmailVerification,
                              isLoading: _isLoading,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Bouton pour renvoyer l'email
                            OutlinedButton(
                              onPressed: _isLoading ? null : _resendVerificationEmail,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppTheme.primaryColor),
                              ),
                              child: Text(
                                AppConstants.resendEmailButton,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
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
  
  // Construire l'en-tête
  Widget _buildHeader() {
    return Column(
      children: [
        // Icône
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
            Icons.mark_email_read,
            size: 40,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Titre
        const Text(
          AppConstants.emailVerificationTitle,
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
          AppConstants.emailVerificationSubtitle,
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
