// Hermetic tests for AnimalService against the proxy contract in
// proxy/README.md and proxy/src/handler.mjs. No network: http.Client is a
// MockClient. These tests exist mainly to prove the name-cleaning logic
// matches the proxy's NAME_RE before anything is sent.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:animal_identifier/services/animal_service.dart';

const String _baseUrl = 'https://proxy.example.test';

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
  group('AnimalService.getAnimalInfo', () {
    test('a name with forbidden characters is cleaned before the call', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        expect(request.url.toString(), '$_baseUrl/v1/info');
        expect(request.headers['content-type'], 'application/json');
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _geminiShaped({
          'id': 'proxy-generated-id',
          'name': 'Grey Wolf',
          'species': 'Canis lupus',
          'breed': '',
          'description': 'A wolf.',
          'habitat': 'Forests and tundra',
          'diet': 'Carnivore',
          'lifespan': '6-8 years',
          'taxonomy': {'kingdom': 'Animalia'},
          'conservation': {'status': 'LC'},
          'behavior': {'activity_pattern': 'Nocturnal'},
          'interesting_facts': ['Howls at night'],
          'imageUrl': '',
        });
      });

      final service = AnimalService(httpClient: client, baseUrl: _baseUrl);
      final animal = await service.getAnimalInfo({
        'species': 'Canis   lupus###',
        'common_name': 'Grey #\$% Wolf',
        'breed': null,
      });

      expect(
        sentBody,
        {'species': 'Canis lupus', 'common_name': 'Grey Wolf', 'breed': ''},
      );
      expect(animal.id, 'proxy-generated-id');
      expect(animal.species, 'Canis lupus');
      expect(animal.taxonomy, {'kingdom': 'Animalia'});
    });

    test('an empty name after cleaning fails without making a call', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = AnimalService(httpClient: client, baseUrl: _baseUrl);

      await expectLater(
        () => service.getAnimalInfo({'species': '###', 'common_name': '!!!', 'breed': ''}),
        throwsException,
      );
      expect(called, isFalse);
    });

    test('a missing name is filled in from the other one', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _geminiShaped({
          'id': '1',
          'name': 'Tiger',
          'species': 'Panthera tigris',
          'breed': '',
          'description': 'd',
          'habitat': 'h',
          'diet': 'di',
          'lifespan': 'l',
          'imageUrl': '',
        });
      });

      final service = AnimalService(httpClient: client, baseUrl: _baseUrl);
      await service.getAnimalInfo({'species': '', 'common_name': 'Tiger', 'breed': ''});

      expect(sentBody!['species'], 'Tiger');
      expect(sentBody!['common_name'], 'Tiger');
    });

    test('a 502 from the proxy ends in a friendly failure', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'upstream_error'}), 502);
      });

      final service = AnimalService(httpClient: client, baseUrl: _baseUrl);

      await expectLater(
        () => service.getAnimalInfo({'species': 'Canis lupus', 'common_name': 'Wolf'}),
        throwsException,
      );
    });

    test('a timeout ends in a friendly failure', () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _geminiShaped({'id': '1', 'name': 'Wolf'});
      });

      final service = AnimalService(
        httpClient: client,
        baseUrl: _baseUrl,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        () => service.getAnimalInfo({'species': 'Canis lupus', 'common_name': 'Wolf'}),
        throwsException,
      );
    });

    test('an empty base URL fails without making a call', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = AnimalService(httpClient: client, baseUrl: '');

      await expectLater(
        () => service.getAnimalInfo({'species': 'Canis lupus', 'common_name': 'Wolf'}),
        throwsException,
      );
      expect(called, isFalse);
    });
  });
}
