// Hermetic tests for VisionService against the proxy contract in
// proxy/README.md and proxy/src/handler.mjs. No network: http.Client is a
// MockClient that answers per route, matching the shape the real proxy
// returns (Google's own candidates[0].content.parts[0].text JSON).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:animal_identifier/services/vision_service.dart';

const String _baseUrl = 'https://proxy.example.test';

File _tempImageFile() {
  final file = File(
    '${Directory.systemTemp.createTempSync('vision_service_test').path}/photo.jpg',
  );
  file.writeAsBytesSync(<int>[1, 2, 3, 4]);
  return file;
}

http.Response _geminiShaped(Map<String, dynamic> payload) {
  final body = jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': jsonEncode(payload)}
          ]
        }
      }
    ]
  });
  return http.Response(body, 200);
}

void main() {
  group('VisionService.analyzeImage', () {
    test('classify then identify happy path', () async {
      final client = MockClient((request) async {
        expect(request.headers['content-type'], 'application/json');
        if (request.url.path == '/v1/classify') {
          return _geminiShaped({
            'contains_human': false,
            'contains_animal': true,
            'confidence': 97,
          });
        }
        if (request.url.path == '/v1/identify') {
          return _geminiShaped({
            'species': 'Panthera tigris',
            'common_name': 'Tiger',
            'breed': '',
            'estimated_age': '3-4 years',
            'estimated_weight_kg': 180,
            'health_status': 'Good',
            'activity_level': 'Active',
            'notable_features': ['Orange coat', 'Black stripes'],
            'mood': 'Alert',
            'rarity': 'Rare',
          });
        }
        throw StateError('unexpected route ${request.url.path}');
      });

      final service = VisionService(httpClient: client, baseUrl: _baseUrl);
      final result = await service.analyzeImage(_tempImageFile());

      expect(result['is_human'], false);
      expect(result['is_animal'], true);
      final animalData = result['animal_data'] as Map<String, dynamic>;
      expect(animalData['species'], 'Panthera tigris');
      expect(animalData['common_name'], 'Tiger');
      expect(animalData['estimated_weight_kg'], 180);
    });

    test('a human photo is reported without calling identify', () async {
      var identifyCalled = false;
      final client = MockClient((request) async {
        if (request.url.path == '/v1/identify') identifyCalled = true;
        return _geminiShaped({
          'contains_human': true,
          'contains_animal': false,
          'confidence': 95,
        });
      });

      final service = VisionService(httpClient: client, baseUrl: _baseUrl);
      final result = await service.analyzeImage(_tempImageFile());

      expect(result['is_human'], true);
      expect(identifyCalled, isFalse);
    });

    test('a no-animal photo is reported without calling identify', () async {
      var identifyCalled = false;
      final client = MockClient((request) async {
        if (request.url.path == '/v1/identify') identifyCalled = true;
        return _geminiShaped({
          'contains_human': false,
          'contains_animal': false,
          'confidence': 80,
        });
      });

      final service = VisionService(httpClient: client, baseUrl: _baseUrl);
      final result = await service.analyzeImage(_tempImageFile());

      expect(result['is_human'], false);
      expect(result['is_animal'], false);
      expect(identifyCalled, isFalse);
    });

    test('a 502 from the proxy ends in a friendly failure', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'upstream_error'}), 502);
      });

      final service = VisionService(httpClient: client, baseUrl: _baseUrl);

      expect(() => service.analyzeImage(_tempImageFile()), throwsException);
    });

    test('a timeout ends in a friendly failure', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _geminiShaped({'contains_human': false, 'contains_animal': false});
      });

      final service = VisionService(
        httpClient: client,
        baseUrl: _baseUrl,
        timeout: const Duration(milliseconds: 20),
      );

      expect(() => service.analyzeImage(_tempImageFile()), throwsException);
    });

    test('an empty base URL fails without making a call', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = VisionService(httpClient: client, baseUrl: '');

      await expectLater(() => service.analyzeImage(_tempImageFile()), throwsException);
      expect(called, isFalse);
    });
  });
}
