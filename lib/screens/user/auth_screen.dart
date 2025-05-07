import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

// Écran d'authentification pour les utilisateurs
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // État
  bool _isLogin = true; // true pour connexion, false pour inscription
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Basculer entre connexion et inscription
  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
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
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        // Connexion
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // La redirection sera gérée automatiquement par le router
          // en fonction du statut d'administrateur
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
          // La redirection sera gérée automatiquement par le router
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    // Vérifier que l'email est valide
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() {
        _errorMessage = 'Veuillez entrer une adresse email valide pour réinitialiser votre mot de passe.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un email de réinitialisation a été envoyé à votre adresse email.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Cette méthode n'est plus nécessaire car nous utilisons une seule page de connexion
  // void _navigateToAdminLogin() {
  //   context.go('/admin');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo ou titre
                  const Icon(
                    Icons.security,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? AppConstants.loginTitle : AppConstants.registerTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),

                  // Afficher le message d'erreur s'il y en a un
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.errorColor),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champs du formulaire
                  if (!_isLogin) ...[
                    // Nom complet (inscription uniquement)
                    CustomTextField(
                      label: AppConstants.fullNameLabel,
                      controller: _fullNameController,
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
                  CustomTextField(
                    label: AppConstants.emailLabel,
                    controller: _emailController,
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
                  CustomTextField(
                    label: AppConstants.passwordLabel,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  const SizedBox(height: 16),

                  if (!_isLogin) ...[
                    // Téléphone (inscription uniquement)
                    CustomTextField(
                      label: AppConstants.phoneLabel,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bouton de connexion/inscription
                  PrimaryButton(
                    text: _isLogin ? AppConstants.loginButton : AppConstants.registerButton,
                    onPressed: _submitForm,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Lien pour basculer entre connexion et inscription
                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      _isLogin ? AppConstants.noAccount : AppConstants.alreadyAccount,
                    ),
                  ),

                  // Lien pour mot de passe oublié (connexion uniquement)
                  if (_isLogin) ...[
                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text(AppConstants.forgotPassword),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Nous n'avons plus besoin du bouton de connexion administrateur
                  // car nous utilisons une seule page de connexion pour tous les utilisateurs
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
