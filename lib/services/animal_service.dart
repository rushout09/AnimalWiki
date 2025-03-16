// 1. First, update the AnimalService.dart to ensure proper data mapping:

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/animal_model.dart';

class AnimalService {
  final String apiKey;
  
  AnimalService({required this.apiKey});

  Future<Animal> getAnimalInfo(Map<String, dynamic> identificationData) async {
    try {
      print("Identification data received: $identificationData"); // Debug logging
      
      final String species = identificationData['species'] ?? 'Unknown';
      final String commonName = identificationData['common_name'] ?? 'Unknown Animal';
      final String breed = identificationData['breed'] ?? '';
      final String estimatedAge = identificationData['estimated_age'] ?? 'Unknown';
      final dynamic estimatedWeight = identificationData['estimated_weight_kg'];
      final String healthStatus = identificationData['health_status'] ?? 'Unknown';
      final String activityLevel = identificationData['activity_level'] ?? 'Unknown';
      final String mood = identificationData['mood'] ?? 'Unknown';
      final String rarity = identificationData['rarity'] ?? 'Unknown';
      final List<String> notableFeatures = identificationData['notable_features'] != null ? 
          (identificationData['notable_features'] as List).map((item) => item.toString()).toList() : [];

      print("Processing species: $species, common name: $commonName"); // Debug logging

      // Enhanced prompt for more detailed information
      final String enhancedPrompt = '''
You are an expert zoologist specializing in animal biology, behavior, and conservation. 
I need comprehensive, accurate information about the ${breed} ${species} (Common name: ${commonName}).

Provide a detailed profile that includes:
1. Accurate scientific and taxonomic information
2. Detailed habitat information including geographic regions
3. Diet and feeding behaviors
4. Typical lifespan in wild and captivity
5. Conservation status with accurate IUCN classification
6. Detailed description of physical characteristics and adaptations
7. Typical personality traits and behaviors
8. Notable facts and interesting features about this animal
9. Challenges facing this species in the wild if applicable

Return ONLY a valid JSON object with the following fields (do not include any other text):
{
  "id": "${DateTime.now().millisecondsSinceEpoch}",
  "name": "${commonName}",
  "species": "${species}",
  "breed": "${breed}",
  "description": "Comprehensive description covering physical characteristics, behaviors, and notable features",
  "habitat": "Detailed natural habitat information including geographic regions",
  "diet": "Specific dietary requirements and feeding behaviors",
  "lifespan": "Typical lifespan information with range for wild vs captivity",
  "taxonomy": {
    "kingdom": "Animalia",
    "phylum": "Specific phylum",
    "class": "Specific class",
    "order": "Specific order",
    "family": "Specific family",
    "genus": "Specific genus"
  },
  "conservation": {
    "status": "IUCN classification (LC, NT, VU, EN, CR, EW, or EX)",
    "population_trend": "Increasing, Stable, or Decreasing",
    "threats": ["Threat 1", "Threat 2", "Threat 3"]
  },
  "behavior": {
    "activity_pattern": "Diurnal, Nocturnal, Crepuscular, etc.",
    "social_structure": "Solitary, Pair-bonding, Social groups, etc.",
    "personality_traits": ["Trait 1", "Trait 2", "Trait 3", "Trait 4"]
  },
  "interesting_facts": ["Fact 1", "Fact 2", "Fact 3"],
  "imageUrl": ""
}
      ''';

      // Use Gemini to get detailed information about the animal
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'
      );
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': enhancedPrompt
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Print response for debugging
        print('Animal Info API Response: ${response.body}');
        
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON from the text response
        final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        final match = jsonRegex.firstMatch(textResponse);
        
        if (match != null) {
          final jsonStr = match.group(0) ?? '{}';
          final animalData = jsonDecode(jsonStr);
          
          // Create extended Animal model from the data
          return _createExtendedAnimal(animalData, identificationData);
        }
        throw Exception('Could not parse animal data');
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to get animal info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in getAnimalInfo: $e');
      throw Exception('Error getting animal info: $e');
    }
  }
  
  // Helper method to create an extended Animal object with all the new fields
  Animal _createExtendedAnimal(Map<String, dynamic> animalData, Map<String, dynamic> identificationData) {
    print("Creating animal from API data: $animalData"); // Debug logging
    print("And identification data: $identificationData"); // Debug logging
    
    // Create the basic animal model with the required fields
    final animal = Animal(
      id: animalData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: animalData['name'] ?? identificationData['common_name'] ?? 'Unknown Animal',
      species: animalData['species'] ?? identificationData['species'] ?? 'Unknown',
      breed: animalData['breed'] ?? identificationData['breed'] ?? '',
      description: animalData['description'] ?? 'No description available',
      habitat: animalData['habitat'] ?? 'Unknown habitat',
      diet: animalData['diet'] ?? 'Unknown diet',
      lifespan: animalData['lifespan'] ?? 'Unknown lifespan',
      imageUrl: animalData['imageUrl'] ?? '',
      
      // Include the direct properties from identification
      estimatedAge: identificationData['estimated_age'],
      estimatedWeightKg: _parseWeightKg(identificationData['estimated_weight_kg']),
      healthStatus: identificationData['health_status'],
      activityLevel: identificationData['activity_level'],
      mood: identificationData['mood'],
      rarity: identificationData['rarity'],
      notableFeatures: identificationData['notable_features'] != null ? 
          (identificationData['notable_features'] as List).map((item) => item.toString()).toList() : null,
      
      // Include nested properties
      taxonomy: animalData['taxonomy'],
      conservation: animalData['conservation'],
      behavior: animalData['behavior'],
      interestingFacts: animalData['interesting_facts'] != null ? 
          (animalData['interesting_facts'] as List).map((item) => item.toString()).toList() : null,
    );
    
    print("Created animal: ${animal.name}, age: ${animal.estimatedAge}, weight: ${animal.estimatedWeightKg}"); // Debug logging
    
    return animal;
  }
  
  // Helper to parse weight which might come in various formats
  int? _parseWeightKg(dynamic weight) {
    if (weight == null) return null;
    
    if (weight is int) return weight;
    if (weight is double) return weight.round();
    
    if (weight is String) {
      // Try to extract numeric portion
      RegExp regex = RegExp(r'(\d+)');
      var match = regex.firstMatch(weight);
      if (match != null) {
        return int.tryParse(match.group(0) ?? '0');
      }
    }
    
    return null;
  }
}

