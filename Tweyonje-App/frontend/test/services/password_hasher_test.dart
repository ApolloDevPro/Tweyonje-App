import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tweyonje/core/services/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hashes and verifies a password', () {
      final hasher = PasswordHasher(iterations: 1000);
      final stored = hasher.hash('correct horse battery staple');

      expect(stored, startsWith('pbkdf2\$sha256\$1000\$'));
      final result = hasher.verify('correct horse battery staple', stored);
      expect(result.verified, isTrue);
      expect(result.needsUpgrade, isFalse, reason: 'iterations == default');
    });

    test('rejects a wrong password', () {
      final hasher = PasswordHasher(iterations: 1000);
      final stored = hasher.hash('correct horse battery staple');

      final result = hasher.verify('wrong password', stored);
      expect(result.verified, isFalse);
    });

    test('uses a fresh salt per hash', () {
      final hasher = PasswordHasher(iterations: 1000);
      final a = hasher.hash('same password');
      final b = hasher.hash('same password');

      expect(a, isNot(equals(b)));
      expect(hasher.verify('same password', a).verified, isTrue);
      expect(hasher.verify('same password', b).verified, isTrue);
    });

    test('verifies a legacy salted SHA-256 hash and flags an upgrade', () {
      final hasher = PasswordHasher();
      const salt = 'aabbccddeeff00112233445566778899';
      const password = 'legacy-secret';
      final legacyHash = sha256.convert(utf8.encode('$salt.$password'));
      final stored = '$salt:${legacyHash.toString()}';

      final result = hasher.verify(password, stored);
      expect(result.verified, isTrue);
      expect(result.needsUpgrade, isTrue);
      expect(hasher.verify('nope', stored).verified, isFalse);
    });

    test('flags a hash with too few iterations for upgrade', () {
      final stored = PasswordHasher(iterations: 1000)
          .hash('long-password-value-1');
      final result = PasswordHasher(iterations: 200000).verify(
        'long-password-value-1',
        stored,
      );

      expect(result.verified, isTrue);
      expect(result.needsUpgrade, isTrue);
    });

    test('is lenient with malformed stored values', () {
      final hasher = PasswordHasher(iterations: 1000);
      for (final garbage in ['', 'not-a-hash', 'pbkdf2\$sha256\$abc\$x\$y']) {
        final result = hasher.verify('anything', garbage);
        expect(result.verified, isFalse, reason: 'input: $garbage');
        expect(result.needsUpgrade, isFalse, reason: 'input: $garbage');
      }
    });
  });
}