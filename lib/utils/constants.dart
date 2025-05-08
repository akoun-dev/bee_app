// Constantes utilisées dans l'application

class AppConstants {
  // Nom de l'application
  static const String appName = 'ZIBENE SECURITY';

  // Messages d'erreur
  static const String errorGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorConnection = 'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String errorAuthentication = 'Erreur d\'authentification. Vérifiez vos identifiants.';
  static const String errorPermission = 'Vous n\'avez pas les permissions nécessaires.';

  // Messages d'erreur d'authentification
  static const String errorEmailAlreadyInUse = 'Cette adresse email est déjà utilisée par un autre compte. Veuillez utiliser une autre adresse email ou vous connecter.';
  static const String errorWeakPassword = 'Le mot de passe est trop faible. Veuillez utiliser un mot de passe plus fort (au moins 6 caractères).';
  static const String errorInvalidEmail = 'L\'adresse email est invalide. Veuillez vérifier votre saisie.';
  static const String errorWrongPassword = 'Mot de passe incorrect. Veuillez réessayer ou utiliser la fonction "Mot de passe oublié".';
  static const String errorUserNotFound = 'Aucun compte trouvé avec cette adresse email. Veuillez vérifier votre saisie ou créer un compte.';
  static const String errorUserDisabled = 'Ce compte a été désactivé. Veuillez contacter le support pour plus d\'informations.';
  static const String errorTooManyRequests = 'Trop de tentatives de connexion. Veuillez réessayer plus tard.';
  static const String errorOperationNotAllowed = 'Cette opération n\'est pas autorisée. Veuillez contacter le support.';
  static const String errorEmailNotVerified = 'Votre adresse email n\'a pas encore été vérifiée. Veuillez vérifier votre boîte de réception et cliquer sur le lien de confirmation.';

  // Messages de succès
  static const String successRegistration = 'Inscription réussie !';
  static const String successLogin = 'Connexion réussie !';
  static const String successReservation = 'Réservation effectuée avec succès !';
  static const String successProfileUpdate = 'Profil mis à jour avec succès !';
  static const String successReview = 'Merci pour votre avis !';

  // Textes pour l'authentification
  static const String loginTitle = 'Connexion';
  static const String registerTitle = 'Inscription';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Mot de passe';
  static const String fullNameLabel = 'Nom complet';
  static const String phoneLabel = 'Numéro de téléphone';
  static const String loginButton = 'Se connecter';
  static const String registerButton = 'S\'inscrire';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas encore de compte ?';
  static const String alreadyAccount = 'Déjà un compte ?';

  // Textes pour la réinitialisation de mot de passe
  static const String resetPasswordTitle = 'Réinitialisation du mot de passe';
  static const String resetPasswordSubtitle = 'Entrez votre adresse email pour recevoir un lien de réinitialisation';
  static const String resetPasswordButton = 'Envoyer le lien de réinitialisation';
  static const String resetPasswordSuccess = 'Un email de réinitialisation a été envoyé à votre adresse email.';
  static const String backToLogin = 'Retour à la connexion';

  // Textes pour la vérification d'email
  static const String emailVerificationTitle = 'Vérification d\'email requise';
  static const String emailVerificationSubtitle = 'Veuillez vérifier votre adresse email pour continuer';
  static const String emailVerificationMessage = 'Un email de vérification a été envoyé à votre adresse email. Veuillez cliquer sur le lien dans cet email pour vérifier votre compte.';
  static const String resendEmailButton = 'Renvoyer l\'email de vérification';
  static const String emailVerificationSuccess = 'Email de vérification envoyé avec succès !';
  static const String checkEmailButton = 'J\'ai vérifié mon email';

  // Textes pour le tableau de bord
  static const String dashboardTitle = 'Tableau de bord';
  static const String welcomeMessage = 'Bienvenue sur votre tableau de bord';
  static const String quickActions = 'Actions rapides';
  static const String recentReservations = 'Réservations récentes';
  static const String recommendedAgents = 'Agents recommandés';

  // Textes pour les agents
  static const String agentsTitle = 'Agents disponibles';
  static const String agentDetailsTitle = 'Profil de l\'agent';
  static const String bookAgent = 'Réserver cet agent';
  static const String agentInfo = 'Informations';
  static const String agentBackground = 'Antécédents';
  static const String agentReviews = 'Avis et commentaires';
  static const String certified = 'Certifié';
  static const String notCertified = 'Non certifié';

  // Textes pour les réservations
  static const String reservationTitle = 'Nouvelle réservation';
  static const String reservationHistoryTitle = 'Historique des réservations';
  static const String startDate = 'Date de début';
  static const String endDate = 'Date de fin';
  static const String location = 'Lieu';
  static const String description = 'Description de la mission';
  static const String submitReservation = 'Soumettre la réservation';
  static const String pending = 'En attente';
  static const String approved = 'Approuvée';
  static const String rejected = 'Rejetée';
  static const String completed = 'Terminée';
  static const String cancelled = 'Annulée';
  static const String rateAgent = 'Noter cet agent';

  // Textes pour le profil utilisateur
  static const String profileTitle = 'Mon profil';
  static const String editProfile = 'Modifier le profil';
  static const String saveChanges = 'Enregistrer les modifications';
  static const String logout = 'Déconnexion';
  static const String securityPriority = 'Votre sécurité est notre priorité';

  // Textes pour l'administration
  static const String adminTitle = 'Administration';
  static const String adminLogin = 'Connexion administrateur';
  static const String pendingReservations = 'Réservations en attente';
  static const String agentsManagement = 'Gestion des agents';
  static const String statistics = 'Statistiques';
  static const String addAgent = 'Ajouter un agent';
  static const String editAgent = 'Modifier l\'agent';
  static const String deleteAgent = 'Supprimer l\'agent';
  static const String approveReservation = 'Approuver';
  static const String rejectReservation = 'Rejeter';

  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Durées
  static const int snackBarDuration = 3; // secondes
  static const int splashDuration = 2; // secondes

  // Valeurs par défaut
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultSpacing = 16.0;
}
