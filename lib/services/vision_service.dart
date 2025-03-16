import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VisionService {
  final String apiKey;
  
  VisionService({required this.apiKey});

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // First, determine if the image contains a human or an animal
      final String classificationPrompt = '''
Analyze this image and determine if it contains a human or an animal.
Return ONLY a JSON object with this format:
{
  "contains_human": true/false,
  "contains_animal": true/false,
  "confidence": 0-100 (percentage of confidence in the classification)
}
      ''';

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
                  'text': classificationPrompt
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Classification Response: ${response.body}');
        
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON from the text response
        final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        final match = jsonRegex.firstMatch(textResponse);
        
        if (match != null) {
          final classification = jsonDecode(match.group(0) ?? '{}');
          
          // If it's a human, return this information
          if (classification['contains_human'] == true && 
             (classification['contains_animal'] != true || 
              (classification['confidence'] > 70))) {
            return {
              'is_human': true,
              'message': 'This appears to be a human. This app is designed for animal identification only.'
            };
          }
          
          // If it's an animal, proceed with animal identification
          if (classification['contains_animal'] == true) {
            final animalData = await _identifyAnimal(imageFile);
            return {
              'is_human': false,
              'is_animal': true,
              'animal_data': animalData
            };
          }
          
          // If it's neither, or unclear
          return {
            'is_human': false,
            'is_animal': false,
            'message': 'Unable to identify a clear animal subject in this image. Please try a different image with a more visible animal.'
          };
        }
        
        return {'error': 'Could not parse classification response'};
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error analyzing image: $e');
      throw Exception('Error analyzing image: $e');
    }
  }

  /// Directly identifies an animal in the given image file
  /// Returns detailed animal identification data
  Future<Map<String, dynamic>> _identifyAnimal(File imageFile) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Enhanced prompt for more accurate identification with stronger emphasis on structure
      final String enhancedPrompt = '''
You are an expert zoologist and wildlife biologist. Carefully analyze this image of an animal and provide accurate identification.

I need you to:
1. Identify the animal's exact species with scientific name
2. Determine the breed or subspecies if applicable
3. Estimate the animal's age based on visual cues
4. Assess the animal's approximate health condition
5. Estimate the animal's weight in kilograms
6. Note any distinguishing or unique features visible in this specific animal
7. Determine current mood or state (alert, calm, playful, etc.)
8. Assess how rare or common this animal is

Return ONLY a JSON object with the following format (no additional text):
{
  "species": "Scientific name of the species",
  "common_name": "Common name people use for this animal",
  "breed": "Breed or subspecies if applicable, otherwise empty string",
  "estimated_age": "Age in years, can be a range if uncertain",
  "estimated_weight_kg": number,
  "health_status": "Excellent, Good, Fair, or Poor",
  "activity_level": "Very Active, Active, Moderate, Low, or Sedentary",
  "notable_features": ["Feature 1", "Feature 2", "Feature 3"],
  "mood": "Alert, Calm, Curious, Playful, etc.",
  "rarity": "Common, Uncommon, Rare, or Extremely Rare"
}

Follow the exact format above with no deviations. If you are uncertain about any value, provide your best estimate rather than omitting the field.
      ''';

      // Prepare the request to Gemini API
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
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Print response for debugging
        print('Animal Identification API Response: ${response.body}');
        
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON from the text response
        final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        final match = jsonRegex.firstMatch(textResponse);
        
        if (match != null) {
          final jsonStr = match.group(0) ?? '{}';
          final result = jsonDecode(jsonStr);
          
          // Ensure all fields exist and have appropriate types
          final Map<String, dynamic> animalData = {
            'species': result['species'] ?? 'Unknown species',
            'common_name': result['common_name'] ?? 'Unknown animal',
            'breed': result['breed'] ?? '',
            'estimated_age': result['estimated_age'] ?? 'Unknown',
            'estimated_weight_kg': _parseWeight(result['estimated_weight_kg']),
            'health_status': result['health_status'] ?? 'Unknown',
            'activity_level': result['activity_level'] ?? 'Unknown',
            'notable_features': result['notable_features'] ?? <String>[],
            'mood': result['mood'] ?? 'Unknown',
            'rarity': result['rarity'] ?? 'Unknown'
          };
          
          print("Processed animal data: $animalData");
          return animalData;
        }
        
        throw Exception('Could not parse animal identification data');
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to identify animal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in _identifyAnimal: $e');
      throw Exception('Error identifying animal: $e');
    }
  }
  
  // Helper to parse weight which might come in various formats
  int _parseWeight(dynamic weight) {
    if (weight == null) return 0;
    
    if (weight is int) return weight;
    if (weight is double) return weight.round();
    
    if (weight is String) {
      // Try to extract numeric portion
      RegExp regex = RegExp(r'(\d+)');
      var match = regex.firstMatch(weight);
      if (match != null) {
        return int.tryParse(match.group(0) ?? '0') ?? 0;
      }
    }
    
    return 0; // Default if parsing fails
  }

  // Public method for backward compatibility
  Future<String> identifyAnimal(File imageFile) async {
    try {
      // Call the new method first to check if it's a human
      final analysisResult = await analyzeImage(imageFile);
      
      // If it's a human, throw an exception
      if (analysisResult['is_human'] == true) {
        throw Exception(analysisResult['message']);
      }
      
      // If it's not an animal either
      if (analysisResult['is_animal'] == false) {
        throw Exception(analysisResult['message']);
      }
      
      // Return the animal data as a JSON string
      return jsonEncode(analysisResult['animal_data']);
    } catch (e) {
      print('Error in identifyAnimal: $e');
      // If analyzeImage throws an exception, try the old way as fallback
      final animalData = await _identifyAnimal(imageFile);
      return jsonEncode(animalData);
    }
  }
}