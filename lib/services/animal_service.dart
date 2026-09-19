import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/animal_model.dart';
import '../utils/constants.dart';

class AnimalService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  AnimalService({
    http.Client? httpClient,
    String baseUrl = kProxyBaseUrl,
    Duration timeout = const Duration(seconds: 60),
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl,
        _timeout = timeout;

  // Letters (any script), digits, spaces and a handful of punctuation marks,
  // matching the proxy's own NAME_RE in proxy/src/handler.mjs.
  static final RegExp _allowedNameChar = RegExp(r"[\p{L}\p{N} .,'’()\-/×]", unicode: true);
  static const int _maxNameChars = 120;

  Future<Animal> getAnimalInfo(Map<String, dynamic> identificationData) async {
    if (_baseUrl.isEmpty) {
      throw Exception('No proxy base URL is configured.');
    }

    String species = _cleanName(identificationData['species']?.toString());
    String commonName = _cleanName(identificationData['common_name']?.toString());
    final String breed = _cleanName(identificationData['breed']?.toString());

    if (species.isEmpty && commonName.isEmpty) {
      throw Exception('Could not identify this animal clearly enough to look it up.');
    }
    if (species.isEmpty) species = commonName;
    if (commonName.isEmpty) commonName = species;

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/info'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'species': species,
              'common_name': commonName,
              'breed': breed,
            }),
          )
          .timeout(_timeout);
    } catch (e) {
      throw Exception('Error getting animal info: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to get animal info: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> animalData;
    try {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String textResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
      final match = jsonRegex.firstMatch(textResponse);
      if (match == null) throw Exception('no json in response');
      animalData = jsonDecode(match.group(0) ?? '{}') as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Could not parse animal data');
    }

    final Map<String, dynamic> cleanedIdentification = {
      ...identificationData,
      'species': species,
      'common_name': commonName,
      'breed': breed,
    };

    return _createExtendedAnimal(animalData, cleanedIdentification);
  }

  // Keep only the proxy's allowed characters, collapse repeated spaces,
  // trim, then cut to the proxy's character limit.
  String _cleanName(String? raw) {
    if (raw == null) return '';
    final buffer = StringBuffer();
    for (final int rune in raw.runes) {
      final String char = String.fromCharCode(rune);
      if (_allowedNameChar.hasMatch(char)) buffer.write(char);
    }
    String cleaned = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length > _maxNameChars) {
      cleaned = cleaned.substring(0, _maxNameChars);
    }
    return cleaned;
  }

  // Helper method to create an extended Animal object with all the new fields
  Animal _createExtendedAnimal(Map<String, dynamic> animalData, Map<String, dynamic> identificationData) {
    // Create the basic animal model with the required fields
    final animal = Animal(
      id: animalData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

    return animal;
  }

  // Helper to parse weight which might come in various formats
  int? _parseWeightKg(dynamic weight) {
    if (weight == null) return null;

    if (weight is int) return weight;
    if (weight is double) return weight.round();

    if (weight is String) {
      RegExp regex = RegExp(r'(\d+)');
      var match = regex.firstMatch(weight);
      if (match != null) {
        return int.tryParse(match.group(0) ?? '0');
      }
    }

    return null;
  }
}
