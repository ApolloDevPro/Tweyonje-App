import '../constants/app_constants.dart';

/// Uganda phone-number helpers.
///
/// The backend stores the phone verbatim and matches it exactly at login, so
/// every number must be normalized to one canonical form before it is sent:
/// E.164 with the Ugandan country code, e.g. `+256704567936`.
class PhoneUtils {
  PhoneUtils._();

  /// Matches a Ugandan MSISDN in any of the common local/international forms:
  /// `+256704567936`, `256704567936`, `0704567936`, `704567936`.
  static final RegExp _ugandaMsisdn = RegExp(r'^(?:\+?256|0)([73]\d{8})$');

  /// Returns the canonical `+256…` form of [raw], or `null` when the input is
  /// not a valid Ugandan mobile number.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[\s\-().]'), '');
    if (cleaned.isEmpty) return null;
    final match = _ugandaMsisdn.firstMatch(cleaned);
    if (match == null) return null;
    return '${AppConstants.countryCode}${match.group(1)}';
  }

  /// True when [raw] can be normalized to a valid Ugandan mobile number.
  static bool isValid(String? raw) => normalize(raw) != null;

  /// True when [value] looks like an email address (used to disambiguate the
  /// "email or phone" login field).
  static bool looksLikeEmail(String value) => value.contains('@');
}
