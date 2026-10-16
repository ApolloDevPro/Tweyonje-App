import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

class CollectorDashboardNotifier extends StateNotifier<AsyncValue<CollectorDashboardData?>> {
  final ApiClient _api;

  CollectorDashboardNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.getCollectorDashboard();
      if (res.statusCode == 200) {
        state = AsyncValue.data(CollectorDashboardData.fromJson(res.data));
      } else {
        state = AsyncValue.error('Failed to load collector dashboard', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> _errorMessage(Future<Response> Function() call) async {
    try {
      final res = await call();
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchDashboard();
        return null;
      }
      final data = res.data;
      if (data is Map && data['error'] is String) return data['error'];
      if (data is Map && data['detail'] is String) return data['detail'];
      return 'Action failed. Please try again.';
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) return data['error'];
      if (data is Map && data['detail'] is String) return data['detail'];
      return 'Network error. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Starts a shift. Returns an error message, or null on success.
  Future<String?> startShift() {
    return _errorMessage(_api.startShift);
  }

  /// Ends the currently active shift. Returns an error message, or null on success.
  Future<String?> endShift() async {
    final shiftId = state.valueOrNull?.activeShiftId;
    if (shiftId == null || shiftId.isEmpty) {
      return 'No active shift found.';
    }
    return _errorMessage(() => _api.endShift(shiftId));
  }

  Future<String?> startTrip(String assignmentId) {
    return _errorMessage(() => _api.assignmentStartTrip(assignmentId));
  }

  Future<String?> arrive(String assignmentId) {
    return _errorMessage(() => _api.assignmentArrive(assignmentId));
  }

  Future<String?> complete(
    String assignmentId, {
    double? collectedWeightKg,
    String? notes,
  }) {
    return _errorMessage(
      () => _api.assignmentComplete(
        assignmentId,
        collectedWeightKg: collectedWeightKg,
        notes: notes,
      ),
    );
  }

  Future<String?> reject(String assignmentId, {String? reason}) {
    return _errorMessage(() => _api.assignmentReject(assignmentId, reason: reason));
  }
}

final collectorDashboardProvider =
    StateNotifierProvider<CollectorDashboardNotifier, AsyncValue<CollectorDashboardData?>>((ref) {
  final api = ref.watch(apiClientProvider);
  return CollectorDashboardNotifier(api);
});
