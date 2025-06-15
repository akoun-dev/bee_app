import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

// Widgets communs réutilisables dans l'application

// Bouton principal
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(text),
      ),
    );
  }
}

// Bouton secondaire
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}

// Champ de texte personnalisé
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    );
  }
}

// Avatar utilisateur
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? name;

  const UserAvatar({super.key, this.imageUrl, this.size = 40, this.name});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder:
            (context, imageProvider) =>
                CircleAvatar(radius: size / 2, backgroundImage: imageProvider),
        placeholder:
            (context, url) => CircleAvatar(
              radius: size / 2,
              backgroundColor: AppTheme.lightColor,
              child: const CircularProgressIndicator(),
            ),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
      );
    } else {
      return _buildFallbackAvatar();
    }
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        name != null && name!.isNotEmpty
            ? name!.substring(0, 1).toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Avatar spécialisé pour les agents - utilise toujours l'image guard.png
class AgentAvatar extends StatelessWidget {
  final double size;
  final String? name;
  final bool isCircular;

  const AgentAvatar({
    super.key,
    this.size = 40,
    this.name,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircular) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: const AssetImage('assets/images/guard.png'),
        backgroundColor: AppTheme.lightColor,
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: const DecorationImage(
            image: AssetImage('assets/images/guard.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}

// Widget pour les images d'agents avec support Firebase Storage
class AgentImage extends StatelessWidget {
  final String? agentId; // ID de l'agent pour charger son image
  final String? imageUrl; // URL directe de l'image (optionnel)
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AgentImage({
    super.key,
    this.agentId,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    // Si une URL directe est fournie, l'utiliser avec cache
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Placeholder pendant le chargement avec animation
        placeholder:
            (context, url) => Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (height != null && height! > 60) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Chargement...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
        // Image par défaut en cas d'erreur - utiliser l'image guard.png
        errorWidget:
            (context, url, error) => Image.asset(
              'assets/images/guard.png',
              width: width,
              height: height,
              fit: fit,
              // Si même l'image par défaut échoue, afficher un placeholder
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        size: (height ?? 100) * 0.4,
                        color: Colors.grey[400],
                      ),
                      if (height != null && height! > 80)
                        Text(
                          'Agent\nZIBENE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        // Configuration du cache
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 800, // Limite la taille sur disque
        maxHeightDiskCache: 800,
      );
    } else {
      // Image par défaut si aucune URL n'est fournie - utiliser l'image guard.png
      image = Image.asset(
        'assets/images/guard.png',
        width: width,
        height: height,
        fit: fit,
        // Si l'image par défaut n'existe pas, afficher un placeholder
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: (height ?? 100) * 0.4,
                  color: Colors.grey[400],
                ),
                if (height != null && height! > 80)
                  Text(
                    'Agent\nZIBENE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    // Appliquer le borderRadius si spécifié
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

// Barre d'évaluation
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double size;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.ratingCount,
    this.size = 20,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: RatingBar.builder(
            initialRating: rating,
            minRating: 0,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: size,
            ignoreGestures: true,
            itemBuilder:
                (context, _) =>
                    const Icon(Icons.star, color: AppTheme.secondaryColor),
            onRatingUpdate: (_) {},
          ),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: TextStyle(color: AppTheme.mediumColor, fontSize: size * 0.8),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// Badge de statut
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = AppConstants.pending;
        break;
      case 'approved':
        color = AppTheme.accentColor;
        text = AppConstants.approved;
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        text = AppConstants.rejected;
        break;
      case 'completed':
        color = AppTheme.primaryColor;
        text = AppConstants.completed;
        break;
      case 'cancelled':
        color = AppTheme.mediumColor;
        text = AppConstants.cancelled;
        break;
      default:
        color = AppTheme.mediumColor;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Indicateur de chargement
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppTheme.mediumColor),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Message d'erreur
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mediumColor),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Message vide
class EmptyMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.mediumColor, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mediumColor),
            ),
          ],
        ),
      ),
    );
  }
}
