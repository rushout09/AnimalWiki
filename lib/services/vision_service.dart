import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class VisionService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  VisionService({
    http.Client? httpClient,
    String baseUrl = kProxyBaseUrl,
    Duration timeout = const Duration(seconds: 60),
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl,
        _timeout = timeout;

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    if (_baseUrl.isEmpty) {
      throw Exception('No proxy base URL is configured.');
    }

    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    final classification = await _callProxy('classify', {'image': base64Image});
    final classificationJson = _extractJson(classification);
    if (classificationJson == null) {
      throw Exception('Could not parse classification response');
    }

    if (classificationJson['contains_human'] == true &&
        (classificationJson['contains_animal'] != true ||
            (classificationJson['confidence'] is num && classificationJson['confidence'] > 70))) {
      return {
        'is_human': true,
        'message': 'This appears to be a human. This app is designed for animal identification only.',
      };
    }

    if (classificationJson['contains_animal'] != true) {
      return {
        'is_human': false,
        'is_animal': false,
        'message': 'Unable to identify a clear animal subject in this image. Please try a different image with a more visible animal.',
      };
    }

    final identify = await _callProxy('identify', {'image': base64Image});
    final identifyJson = _extractJson(identify);
    if (identifyJson == null) {
      throw Exception('Could not parse animal identification data');
    }

    final Map<String, dynamic> animalData = {
      'species': identifyJson['species'] ?? 'Unknown species',
      'common_name': identifyJson['common_name'] ?? 'Unknown animal',
      'breed': identifyJson['breed'] ?? '',
      'estimated_age': identifyJson['estimated_age'] ?? 'Unknown',
      'estimated_weight_kg': _parseWeight(identifyJson['estimated_weight_kg']),
      'health_status': identifyJson['health_status'] ?? 'Unknown',
      'activity_level': identifyJson['activity_level'] ?? 'Unknown',
      'notable_features': identifyJson['notable_features'] ?? <String>[],
      'mood': identifyJson['mood'] ?? 'Unknown',
      'rarity': identifyJson['rarity'] ?? 'Unknown',
    };

    return {
      'is_human': false,
      'is_animal': true,
      'animal_data': animalData,
    };
  }

  Future<Map<String, dynamic>> _callProxy(String route, Map<String, dynamic> body) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/$route'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (e) {
      throw Exception('Error calling the proxy: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Proxy returned ${response.statusCode}: ${response.body}');
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Could not parse the proxy response');
    }
  }

  Map<String, dynamic>? _extractJson(Map<String, dynamic> proxyResponse) {
    String textResponse;
    try {
      textResponse = proxyResponse['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (e) {
      return null;
    }

    final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
    final match = jsonRegex.firstMatch(textResponse);
    if (match == null) return null;

    try {
      return jsonDecode(match.group(0) ?? '{}') as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Helper to parse weight which might come in various formats
  int _parseWeight(dynamic weight) {
    if (weight == null) return 0;

    if (weight is int) return weight;
    if (weight is double) return weight.round();

    if (weight is String) {
      RegExp regex = RegExp(r'(\d+)');
      var match = regex.firstMatch(weight);
      if (match != null) {
        return int.tryParse(match.group(0) ?? '0') ?? 0;
      }
    }

    return 0;
  }
}
