/// Geospatial helpers for the app: geohash encoding, neighbor cells, and
/// Haversine distance. Pure Dart, no platform dependencies.
library;

import 'dart:math';

/// Geohash + distance utilities.
///
/// Geohashes give cheap spatial filtering in plain SQLite via
/// `WHERE geohash LIKE 'prefix%'`, avoiding any spatial extension. A request is
/// found by filtering on the center cell plus its 8 neighbors, then refining
/// with exact Haversine distance.
class GeoUtils {
  GeoUtils._();

  static const String alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Meters per degree of latitude (mean Earth radius 6371008.8 m).
  static const double _metersPerDegree = 111320.0;

  /// Earth radius in meters.
  static const double _earthRadiusM = 6371008.8;

  /// Precision used when persisting geohashes to the database.
  static const int storedPrecision = 12;

  /// Encodes [lat]/[lon] into a geohash of [precision] characters.
  static String encode(double lat, double lon, {int precision = 9}) {
    final latClamped = lat.clamp(-90.0, 90.0);
    final lonClamped = lon.clamp(-180.0, 180.0);

    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;

    final buffer = StringBuffer();
    var isLon = true;
    var hash = 0;
    var bits = 0;

    while (buffer.length < precision) {
      if (isLon) {
        final mid = (lonMin + lonMax) / 2;
        if (lonClamped >= mid) {
          hash = (hash << 1) | 1;
          lonMin = mid;
        } else {
          hash <<= 1;
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latClamped >= mid) {
          hash = (hash << 1) | 1;
          latMin = mid;
        } else {
          hash <<= 1;
          latMax = mid;
        }
      }

      isLon = !isLon;
      bits++;
      if (bits == 5) {
        buffer.write(alphabet[hash]);
        hash = 0;
        bits = 0;
      }
    }

    return buffer.toString();
  }

  /// Decodes a geohash to the center point of its cell.
  static ({double lat, double lon}) decode(String geohash) {
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    var isLon = true;

    for (final ch in geohash.split('')) {
      final value = alphabet.indexOf(ch);
      if (value < 0) {
        throw FormatException('Invalid geohash character: $ch');
      }
      for (var bit = 4; bit >= 0; bit--) {
        final on = ((value >> bit) & 1) == 1;
        if (isLon) {
          final mid = (lonMin + lonMax) / 2;
          if (on) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (on) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isLon = !isLon;
      }
    }

    return (lat: (latMin + latMax) / 2, lon: (lonMin + lonMax) / 2);
  }

  /// Geohash cell size in degrees for a given [precision].
  ///
  /// Bits alternate between longitude and latitude starting with longitude, so
  /// over `5 * precision` bits longitude receives `ceil(5p/2)` and latitude
  /// `floor(5p/2)`.
  static ({double latDeg, double lonDeg}) cellDegrees(int precision) {
    final totalBits = 5 * precision;
    final lonBits = (totalBits + 1) ~/ 2;
    final latBits = totalBits - lonBits;
    return (
      latDeg: 180.0 / pow(2, latBits).toDouble(),
      lonDeg: 360.0 / pow(2, lonBits).toDouble(),
    );
  }

  /// Approximate cell size in meters for the given [precision] at [latitude].
  static ({double heightM, double widthM}) cellMeters(
    int precision, {
    double latitude = 0.0,
  }) {
    final degrees = cellDegrees(precision);
    final widthM = degrees.lonDeg *
        _metersPerDegree *
        cos(latitude * pi / 180).clamp(0.0, 1.0);
    return (heightM: degrees.latDeg * _metersPerDegree, widthM: widthM);
  }

  /// Nearest geohash precision whose 3x3 neighborhood is guaranteed to cover
  /// [radiusMeters] around a point at [latitude]. Larger precisions filter
  /// fewer rows at the cost of matching adjacent cells.
  static int precisionForRadius(double radiusMeters, {double latitude = 0.0}) {
    var result = 1;
    for (var p = 1; p <= storedPrecision; p++) {
      final cell = cellMeters(p, latitude: latitude);
      if (cell.heightM >= radiusMeters && cell.widthM >= radiusMeters) {
        result = p;
      } else {
        break;
      }
    }
    return result;
  }

  /// The geohash of the cell containing [lat]/[lon] at [precision], plus its
  /// 8 immediate neighbors (9 cells total). Every point within one cell-size
  /// of [lat]/[lon] is guaranteed to fall in at least one of these cells.
  static Set<String> neighborhood(String centerGeohash) {
    final center = decode(centerGeohash);
    final precision = centerGeohash.length;
    final degrees = cellDegrees(precision);

    final result = <String>{};
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        result.add(
          encode(
            center.lat + dy * degrees.latDeg,
            center.lon + dx * degrees.lonDeg,
            precision: precision,
          ),
        );
      }
    }
    return result;
  }

  /// Great-circle distance between two points, in meters.
  static double distanceMeters(double lat1, double lon1,
      double lat2, double lon2) {
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusM * c;
  }
}