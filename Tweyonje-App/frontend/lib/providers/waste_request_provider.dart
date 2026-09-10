import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

final wasteCategoriesProvider = FutureProvider<List<WasteCategory>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.getWasteCategories();
    if (res.statusCode == 200) {
      final list = (res.data is List) ? res.data : res.data['results'] ?? [];
      return (list as List).map((c) => WasteCategory.fromJson(c)).toList();
    }
  } catch (_) {}
  return [];
});

class WasteRequestsNotifier extends StateNotifier<AsyncValue<List<WasteRequest>>> {
  final ApiClient _api;

  WasteRequestsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.getMyRequests();
      if (res.statusCode == 200) {
        final list = (res.data is List) ? res.data : res.data['results'] ?? [];
        final requests = (list as List).map((r) => WasteRequest.fromJson(r)).toList();
        state = AsyncValue.data(requests);
      } else {
        state = AsyncValue.error('Failed to load requests', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createRequest(Map<String, dynamic> data) async {
    try {
      final res = await _api.createWasteRequest(data);
      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchRequests();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> cancelRequest(String id, String reason) async {
    try {
      final res = await _api.cancelRequest(id, reason);
      if (res.statusCode == 200) {
        await fetchRequests();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final wasteRequestsProvider =
    StateNotifierProvider<WasteRequestsNotifier, AsyncValue<List<WasteRequest>>>((ref) {
  final api = ref.watch(apiClientProvider);
  return WasteRequestsNotifier(api);
});

final rewardsStatusProvider = FutureProvider<RewardStatus?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.getRewardsStatus();
    if (res.statusCode == 200) {
      return RewardStatus.fromJson(res.data);
    }
  } catch (_) {}
  return null;
});
