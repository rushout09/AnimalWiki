// Hermetic tests for the credit logic in PaymentService. No network, no
// platform channels: SharedPreferences is mocked and these tests only touch
// the balance/referral bookkeeping, never initStoreInfo's billing calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animal_identifier/services/payment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('credits', () {
    test('a fresh install starts with 0 credits', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);
      expect(service.credits, 0);
    });

    test('useCredits deducts and persists when the balance covers it', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);
      await service.addCredits(3);

      final spent = await service.useCredits(1);

      expect(spent, isTrue);
      expect(service.credits, 2);
    });

    test('useCredits leaves the balance untouched when it is insufficient', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);

      final spent = await service.useCredits(1);

      expect(spent, isFalse);
      expect(service.credits, 0);
    });

    test('a balance of 0 stays 0 across a fresh PaymentService instance', () async {
      final first = PaymentService();
      await Future<void>.delayed(Duration.zero);
      await first.addCredits(1);
      await first.useCredits(1);
      expect(first.credits, 0);

      final second = PaymentService();
      await Future<void>.delayed(Duration.zero);
      expect(second.credits, 0);
    });
  });

  group('referral codes', () {
    test('a valid code grants credits once', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);

      final result = await service.applyReferralCode('review2025');

      expect(result['success'], isTrue);
      expect(service.credits, 5);
    });

    test('the same code cannot be redeemed twice', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);
      await service.applyReferralCode('review2025');

      final result = await service.applyReferralCode('REVIEW2025');

      expect(result['success'], isFalse);
      expect(service.credits, 5);
    });

    test('an unknown code is rejected', () async {
      final service = PaymentService();
      await Future<void>.delayed(Duration.zero);

      final result = await service.applyReferralCode('not-a-real-code');

      expect(result['success'], isFalse);
      expect(service.credits, 0);
    });
  });
}
