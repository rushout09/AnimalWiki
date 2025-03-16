
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/animal_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'Mammals';
  final List<String> _categories = [
    'Mammals', 'Birds', 'Reptiles', 'Fish', 'Amphibians', 'Insects'
  ];

  // Sample featured animals with fixed URLs
  final List<Animal> _featuredAnimals = [
    Animal(
      id: '1',
      name: 'African Elephant',
      species: 'Loxodonta africana',
      breed: '',
      description: 'The African bush elephant is the largest living terrestrial animal, with males standing 3.2–4.0 m tall at the shoulder and weighing 4,700–6,048 kg.',
      habitat: 'Sub-Saharan Africa',
      diet: 'Herbivore',
      lifespan: '60-70 years',
      imageUrl: '', // We'll handle this with a color placeholder
    ),
    Animal(
      id: '2', 
      name: 'Bengal Tiger',
      species: 'Panthera tigris tigris',
      breed: '',
      description: 'The Bengal tiger is the most numerous tiger subspecies. Its populations have been estimated at 2,500 in the wild.',
      habitat: 'Indian subcontinent',
      diet: 'Carnivore',
      lifespan: '8-10 years in the wild, up to 18 in captivity',
      imageUrl: '', // We'll handle this with a color placeholder
    ),
    Animal(
      id: '3',
      name: 'Giant Panda',
      species: 'Ailuropoda melanoleuca',
      breed: '',
      description: 'The giant panda has a distinctive black and white coat, with black fur around its eyes and on its ears, muzzle, legs, and shoulders.',
      habitat: 'Mountain forests in central China',
      diet: 'Primarily bamboo',
      lifespan: '15-20 years in the wild',
      imageUrl: '', // We'll handle this with a color placeholder
    ),
  ];

  // Colors for animal placeholders
  final List<Color> _animalColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFFF57C00), // Orange
    Color(0xFF2196F3), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Explore Species'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: AppTheme.shadowSmall,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textLight),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search animals...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppTheme.spacingLarge),
              
              // Category selector
              Text(
                'Categories',
                style: AppTheme.textTheme.headlineSmall,
              ),
              
              SizedBox(height: AppTheme.spacingMedium),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceMedium,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Text(
                            category,
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMedium,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingLarge),
              
              // Featured animals
              Text(
                'Featured Animals',
                style: AppTheme.textTheme.headlineSmall,
              ),
              
              SizedBox(height: AppTheme.spacingMedium),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _featuredAnimals.length,
                itemBuilder: (context, index) {
                  final animal = _featuredAnimals[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _buildAnimalCard(animal, _animalColors[index % _animalColors.length]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal, Color placeholderColor) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Animal image placeholder with color
          Container(
            width: 120,
            height: 120,
            color: placeholderColor,
            child: Center(
              child: Icon(
                Icons.pets,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          
          // Animal info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    animal.name,
                    style: AppTheme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    animal.species,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  // FIX: Use a scrollable row or Wrap for these pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoPill(Icons.home_rounded, animal.habitat),
                        SizedBox(width: 8),
                        _buildInfoPill(Icons.access_time_rounded, animal.lifespan),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action icon
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textLight,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.textLight,
            size: 12,
          ),
          SizedBox(width: 4),
          // FIX: Limit the width of the text to prevent overflow
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 100),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
