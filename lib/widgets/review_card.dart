import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';

// Widget pour afficher un avis/commentaire
class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec utilisateur et date
            Row(
              children: [
                UserAvatar(
                  imageUrl: review.userProfileImageUrl,
                  name: review.userFullName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userFullName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dateFormat.format(review.createdAt),
                        style: const TextStyle(
                          color: AppTheme.mediumColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Évaluation
            RatingDisplay(
              rating: review.rating,
              ratingCount: 0,
              showCount: false,
            ),

            const SizedBox(height: 8),

            // Commentaire
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
