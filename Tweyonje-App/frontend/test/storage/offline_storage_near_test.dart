import 'package:flutter_test/flutter_test.dart';

import 'package:tweyonje/core/database/app_database.dart';
import 'package:tweyonje/core/storage/offline_storage.dart';
import 'package:tweyonje/models/models.dart';

void main() {
  final storage = OfflineStorage();

  setUp(() async {
    await AppDatabase.instance.close();
    final db = await AppDatabase.instance.database;
    await db.delete('waste_requests');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  WasteRequest request(
    String id,
    double lat,
    double lon, {
    String? address = 'Kampala',
  }) {
    return WasteRequest(
      id: id,
      referenceId: 'WR-$id',
      pickupAddress: address!,
      latitude: lat,
      longitude: lon,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  test('saves geohash/lat/lon columns', () async {
    await storage.saveWasteRequest(request('a-1', 0.3476, 32.5825));

    final db = await AppDatabase.instance.database;
    final rows = await db.query('waste_requests', where: 'id = ?', whereArgs: ['a-1']);
    expect(rows, hasLength(1));
    expect(rows.first['lat'], 0.3476);
    expect(rows.first['lon'], 32.5825);
    expect(rows.first['geohash'], isNotNull);
  });

  test('returns only requests within the radius, nearest first', () async {
    // Kampala center, ~8 km east, Entebbe (~36 km south-west).
    await storage.saveWasteRequest(request('near-1', 0.3476, 32.6545));
    await storage.saveWasteRequest(request('near-2', 0.3476, 32.5825));
    await storage.saveWasteRequest(request('far-1', 0.0505, 32.4586));
    // Request without coordinates must never be matched by the spatial query.
    await storage.saveWasteRequest(
      WasteRequest(
        id: 'no-coords',
        referenceId: 'WR-no-coords',
        pickupAddress: 'Unknown',
      ),
    );

    final within5km = await storage.getWasteRequestsNear(
      latitude: 0.3476,
      longitude: 32.5825,
      radiusMeters: 5000,
    );
    expect(within5km.map((r) => r.id).toSet(), {'near-2'});

    final within40km = await storage.getWasteRequestsNear(
      latitude: 0.3476,
      longitude: 32.5825,
      radiusMeters: 40000,
    );
    expect(
      within40km.map((r) => r.id).toList(),
      ['near-2', 'near-1', 'far-1'],
      reason: 'nearest-first by Haversine distance',
    );
    expect(within40km.map((r) => r.id), isNot(contains('no-coords')));
  });

  test('respects the limit parameter', () async {
    await storage.saveWasteRequest(request('l1', 0.3539, 32.6177));
    await storage.saveWasteRequest(request('l2', 0.3476, 32.5825));
    await storage.saveWasteRequest(request('l3', 0.3606, 32.5501));

    final result = await storage.getWasteRequestsNear(
      latitude: 0.3476,
      longitude: 32.5825,
      radiusMeters: 20000,
      limit: 2,
    );
    expect(result, hasLength(2));
    expect(result.first.id, 'l2');
  });
}