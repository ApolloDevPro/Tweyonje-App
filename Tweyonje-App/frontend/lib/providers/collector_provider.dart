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

  Future<bool> startShift() async {
    try {
      final res = await _api.startShift();
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchDashboard();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> endShift(String shiftId) async {
    try {
      final res = await _api.endShift(shiftId);
      if (res.statusCode == 200) {
        await fetchDashboard();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateStatus(String assignmentId, String status) async {
    try {
      final res = await _api.updateAssignmentStatus(assignmentId, status);
      if (res.statusCode == 200) {
        await fetchDashboard();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final collectorDashboardProvider =
    StateNotifierProvider<CollectorDashboardNotifier, AsyncValue<CollectorDashboardData?>>((ref) {
  final api = ref.watch(apiClientProvider);
  return CollectorDashboardNotifier(api);
});
