import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';
import 'api_client.dart';

/// Extension on ApiClient to add offline-aware methods
extension OfflineAwareApi on ApiClient {
  /// Make a POST request with offline queueing support
  Future<Map<String, dynamic>> postWithOfflineSupport({
    required String endpoint,
    required Map<String, dynamic> data,
    required SyncService syncService,
    required String actionType,
    String? localReference,
  }) async {
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();

    // If online, execute immediately
    final isConnected = connectivityResults.any((result) => result != ConnectivityResult.none);
    if (isConnected) {
      try {
        final response = await post(endpoint, data: data);
        return response.data as Map<String, dynamic>;
      } catch (e) {
        // If request fails, queue for later
        await _queueAction(
          syncService: syncService,
          endpoint: endpoint,
          method: 'POST',
          data: data,
          actionType: actionType,
          localReference: localReference,
        );
        rethrow;
      }
    } else {
      // Offline - queue the action
      await _queueAction(
        syncService: syncService,
        endpoint: endpoint,
        method: 'POST',
        data: data,
        actionType: actionType,
        localReference: localReference,
      );

      // Return optimistic response
      return {
        'status': 'queued',
        'local_reference': localReference ?? const Uuid().v4(),
        'message': 'Action queued for sync when online',
      };
    }
  }

  /// Make a PUT/PATCH request with offline queueing support
  Future<Map<String, dynamic>> updateWithOfflineSupport({
    required String endpoint,
    required Map<String, dynamic> data,
    required SyncService syncService,
    required String actionType,
    String method = 'PUT',
    String? localReference,
  }) async {
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();
    final isConnected = connectivityResults.any((result) => result != ConnectivityResult.none);

    if (isConnected) {
      try {
        final response = method.toUpperCase() == 'PATCH'
            ? await patch(endpoint, data: data)
            : await put(endpoint, data: data);
        return response.data as Map<String, dynamic>;
      } catch (e) {
        await _queueAction(
          syncService: syncService,
          endpoint: endpoint,
          method: method,
          data: data,
          actionType: actionType,
          localReference: localReference,
        );
        rethrow;
      }
    } else {
      await _queueAction(
        syncService: syncService,
        endpoint: endpoint,
        method: method,
        data: data,
        actionType: actionType,
        localReference: localReference,
      );

      return {
        'status': 'queued',
        'local_reference': localReference ?? const Uuid().v4(),
        'message': 'Update queued for sync when online',
      };
    }
  }

  Future<void> _queueAction({
    required SyncService syncService,
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    required String actionType,
    String? localReference,
  }) async {
    final action = PendingAction(
      id: const Uuid().v4(),
      type: actionType,
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: DateTime.now(),
      localReference: localReference,
    );

    await syncService.queueAction(action);
  }
}

/// Helper class for creating waste requests offline
class OfflineWasteRequestHelper {
  final SyncService syncService;
  final ApiClient apiClient;

  OfflineWasteRequestHelper({
    required this.syncService,
    required this.apiClient,
  });

  /// Create a waste request with offline support
  Future<Map<String, dynamic>> createRequest({
    required String category,
    required String pickupAddress,
    required double latitude,
    required double longitude,
    String? scheduledDate,
    String? scheduledTimeSlot,
    double? estimatedWeightKg,
    bool isEmergency = false,
    String? specialInstructions,
  }) async {
    final localRef = const Uuid().v4();

    final data = {
      'category': category,
      'pickup_address': pickupAddress,
      'latitude': latitude,
      'longitude': longitude,
      'scheduled_date': ?scheduledDate,
      'scheduled_time_slot': ?scheduledTimeSlot,
      'estimated_weight_kg': ?estimatedWeightKg,
      'is_emergency': isEmergency,
      'special_instructions': ?specialInstructions,
      '_local_reference': localRef,
    };

    try {
      return await apiClient.postWithOfflineSupport(
        endpoint: '/api/v1/waste-requests/',
        data: data,
        syncService: syncService,
        actionType: 'create_request',
        localReference: localRef,
      );
    } catch (e) {
      // Return optimistic local response
      return {
        'id': localRef,
        'reference_id': 'LOCAL-$localRef',
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
        '_is_local': true,
        '_queued': true,
        ...data,
      };
    }
  }

  /// Cancel a request with offline support
  Future<void> cancelRequest({
    required String requestId,
    String? reason,
  }) async {
    final data = {
      'reason': ?reason,
    };

    await apiClient.postWithOfflineSupport(
      endpoint: '/api/v1/waste-requests/$requestId/cancel/',
      data: data,
      syncService: syncService,
      actionType: 'cancel_request',
      localReference: requestId,
    );
  }

  /// Update collector location with offline support
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speedKmh,
  }) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      'heading': ?heading,
      'speed_kmh': ?speedKmh,
    };

    await apiClient.postWithOfflineSupport(
      endpoint: '/api/v1/tracking/update-location/',
      data: data,
      syncService: syncService,
      actionType: 'update_location',
    );
  }
}
