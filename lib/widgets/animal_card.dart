import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/animal_model.dart';
import '../utils/constants.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showDetails;

  const AnimalCard({
    Key? key,
    required this.animal,
    this.onTap,
    this.onFavorite,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: animal.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: animal.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Icon(Icons.pets, size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(Icons.pets, size: 50, color: Colors.grey),
                        ),
                ),
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFavorite,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            animal.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: animal.isFavorite
                                ? Colors.red
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: AppTextStyles.subheading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${animal.breed} ${animal.species}",
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDetails) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.home, "Habitat", animal.habitat),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.restaurant, "Diet", animal.diet),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.timer, "Lifespan", animal.lifespan),
                    SizedBox(height: 16),
                    Text(
                      "About",
                      style: AppTextStyles.subheading,
                    ),
                    SizedBox(height: 8),
                    Text(
                      animal.description,
                      style: AppTextStyles.body,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}