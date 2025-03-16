// 2. Update the Animal model to include explicit properties for the identification data:

class Animal {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String description;
  final String habitat;
  final String diet;
  final String lifespan;
  final String imageUrl;
  final bool isFavorite;
  
  // Direct properties from identification
  final String? estimatedAge;
  final int? estimatedWeightKg;
  final String? healthStatus;
  final String? activityLevel;
  final String? mood;
  final String? rarity;
  final List<String>? notableFeatures;
  
  // Nested properties
  final Map<String, dynamic>? taxonomy;
  final Map<String, dynamic>? conservation;
  final Map<String, dynamic>? behavior;
  final List<String>? interestingFacts;

  Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.description,
    required this.habitat,
    required this.diet,
    required this.lifespan,
    required this.imageUrl,
    this.isFavorite = false,
    this.estimatedAge,
    this.estimatedWeightKg,
    this.healthStatus,
    this.activityLevel,
    this.mood,
    this.rarity,
    this.notableFeatures,
    this.taxonomy,
    this.conservation,
    this.behavior,
    this.interestingFacts,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'] ?? '',
      description: json['description'] ?? '',
      habitat: json['habitat'] ?? '',
      diet: json['diet'] ?? '',
      lifespan: json['lifespan'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      estimatedAge: json['estimated_age'],
      estimatedWeightKg: json['estimated_weight_kg'] is int 
          ? json['estimated_weight_kg'] 
          : (json['estimated_weight_kg'] is String 
              ? int.tryParse(json['estimated_weight_kg']) 
              : null),
      healthStatus: json['health_status'],
      activityLevel: json['activity_level'],
      mood: json['mood'],
      rarity: json['rarity'],
      notableFeatures: json['notable_features'] != null 
          ? List<String>.from(json['notable_features']) 
          : null,
      taxonomy: json['taxonomy'],
      conservation: json['conservation'],
      behavior: json['behavior'],
      interestingFacts: json['interesting_facts'] != null 
          ? List<String>.from(json['interesting_facts']) 
          : null,
    );
  }

  Animal copyWith({
    bool? isFavorite,
  }) {
    return Animal(
      id: this.id,
      name: this.name,
      species: this.species,
      breed: this.breed,
      description: this.description,
      habitat: this.habitat,
      diet: this.diet,
      lifespan: this.lifespan,
      imageUrl: this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      estimatedAge: this.estimatedAge,
      estimatedWeightKg: this.estimatedWeightKg,
      healthStatus: this.healthStatus,
      activityLevel: this.activityLevel,
      mood: this.mood,
      rarity: this.rarity,
      notableFeatures: this.notableFeatures,
      taxonomy: this.taxonomy,
      conservation: this.conservation,
      behavior: this.behavior,
      interestingFacts: this.interestingFacts,
    );
  }
}

