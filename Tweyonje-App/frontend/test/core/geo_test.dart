import 'package:flutter_test/flutter_test.dart';

import 'package:tweyonje/core/utils/geo.dart';

void main() {
  group('GeoUtils', () {
    test('encodes the Wikipedia reference example', () {
      expect(
        GeoUtils.encode(57.64911, 10.40744, precision: 11),
        'u4pruydqqvj',
      );
    });

    test('decode of encode stays within the expected cell', () {
      const lat = 0.3476;
      const lon = 32.5825;
      const precision = 6;

      final encoded = GeoUtils.encode(lat, lon, precision: precision);
      final center = GeoUtils.decode(encoded);
      final cell = GeoUtils.cellDegrees(precision);

      expect((lat - center.lat).abs(), lessThanOrEqualTo(cell.latDeg / 2));
      expect((lon - center.lon).abs(), lessThanOrEqualTo(cell.lonDeg / 2));
    });

    test('neighborhood returns 9 distinct cells', () {
      final cells = GeoUtils.neighborhood(
        GeoUtils.encode(0.3476, 32.5825, precision: 6),
      );
      expect(cells.length, 9);
      expect(cells, contains(GeoUtils.encode(0.3476, 32.5825, precision: 6)));
    });

    test('haversine distance (one degree of latitude)', () {
      final d = GeoUtils.distanceMeters(0.0, 0.0, 1.0, 0.0);
      // One degree of latitude is ~111.32 km.
      expect(d, closeTo(111320, 500));
    });

    test('haversine distance Kampala to Entebbe (~34 km)', () {
      final d = GeoUtils.distanceMeters(0.3476, 32.5825, 0.0505, 32.4586);
      expect(d, inInclusiveRange(32000, 37000));
    });

    test('radius precision picks the finest cell covering the radius', () {
      expect(GeoUtils.precisionForRadius(5000, latitude: 0.35), 4);
      expect(GeoUtils.precisionForRadius(300, latitude: 0.35), 6);
      expect(GeoUtils.precisionForRadius(20000), 3);
    });

    test('rejects malformed geohashes', () {
      expect(() => GeoUtils.decode('not-a-geohash-zzzzz'), throwsFormatException);
    });
  });
}