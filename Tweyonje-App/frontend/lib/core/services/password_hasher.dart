import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Password hashing using PBKDF2-HMAC-SHA256.
///
/// The hash format is self-describing so the work factor can be raised without
/// invalidating existing rows:
///
///     pbkdf2$sha256$<iterations>$<salt>$<hash>
///
/// where salt and hash are Base64. Legacy rows created as `sha256` havehes
/// (`<salt>:<sha256hex>`) are still verified and flagged for one-time upgrade.
class PasswordHasher {
  /// Default work factor. Store per-hash so it can be raised over time.
  /// OWASP recommends 600k+ for PBKDF2-HMAC-SHA256; 150k keeps login fast on
  /// low-end phones while remaining impractical to brute force.
  static const int defaultIterations = 150000;

  /// Iterations used when creating new passwords.
  final int iterations;

  PasswordHasher({this.iterations = defaultIterations});

  static const String newPrefix = 'pbkdf2';
  static const String _algorithm = 'sha256';

  /// Salt length in bytes.
  static const int _saltBytes = 16;

  /// Hashes [password] with a fresh random salt.
  String hash(String password) {
    final salt = _randomBytes(_saltBytes);
    final derived = _pbkdf2(password, salt, iterations);
    return '$newPrefix\$$_algorithm\$$iterations\$'
        '${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  /// Verifies [password] against a stored hash.
  ///
  /// Returns `(verified, needsUpgrade)`. `needsUpgrade` is true when the stored
  /// value is the legacy raw SHA-256 form or uses fewer iterations than the
  /// current default, so callers can transparently rehash on next sign-in.
  ({bool verified, bool needsUpgrade}) verify(String password, String stored) {
    if (stored.isEmpty) return (verified: false, needsUpgrade: false);

    bool ok;
    bool needsUpgrade;
    int storedIterations;

    if (stored.startsWith('$newPrefix\$')) {
      final parts = stored.split(r'$');
      if (parts.length != 5) return (verified: false, needsUpgrade: false);
      final algorithm = parts[1];
      if (algorithm != _algorithm) return (verified: false, needsUpgrade: false);
      storedIterations = int.tryParse(parts[2]) ?? 0;
      final salt = _safeDecode(parts[3]);
      final expected = _safeDecode(parts[4]);
      if (salt == null || expected == null || storedIterations <= 0) {
        return (verified: false, needsUpgrade: false);
      }
      final derived = _pbkdf2(password, salt, storedIterations);
      ok = _constantTimeEquals(derived, expected);
      needsUpgrade = storedIterations < iterations;
    } else if (stored.contains(':') && !stored.contains(r'$')) {
      // Legacy format: '<salt hex>:<sha256 hex>' from the pre-PBKDF2 build.
      final parts = stored.split(':');
      if (parts.length != 2) return (verified: false, needsUpgrade: false);
      storedIterations = 1;
      final expected = sha256
          .convert(utf8.encode('${parts[0]}.$password'))
          .toString();
      ok = _constantTimeEquals(utf8.encode(parts[1]), utf8.encode(expected));
      needsUpgrade = ok;
    } else {
      return (verified: false, needsUpgrade: false);
    }

    return (verified: ok, needsUpgrade: needsUpgrade);
  }

  /// PBKDF2 (RFC 2898) with HMAC-SHA256 producing a 32-byte key.
  Uint8List _pbkdf2(String password, List<int> salt, int iterations) {
    final prf = Hmac(sha256, utf8.encode(password));
    final hashLength = 32; // sha256 digest length in bytes
    final output = Uint8List(hashLength);

    // U1 = HMAC(password, SALT || INT(1))
    final first = BytesBuilder()
      ..add(salt)
      ..add([0, 0, 0, 1]);
    var u = prf.convert(first.toBytes()).bytes;

    for (var i = 0; i < hashLength; i++) {
      output[i] = u[i];
    }

    for (var i = 1; i < iterations; i++) {
      u = prf.convert(u).bytes;
      for (var j = 0; j < hashLength; j++) {
        output[j] ^= u[j];
      }
    }

    return output;
  }

  Uint8List? _safeDecode(String value) {
    try {
      return base64.decode(base64.normalize(value));
    } catch (_) {
      return null;
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Uint8List _randomBytes(int count) {
    final random = Random.secure();
    final bytes = Uint8List(count);
    for (var i = 0; i < count; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}