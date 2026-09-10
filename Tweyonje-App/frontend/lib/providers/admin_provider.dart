import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).getAdminDashboard();
    if (res.statusCode == 200 && res.data is Map) {
      return AdminDashboardData.fromJson(Map<String, dynamic>.from(res.data));
    }
  } catch (e) {
    throw Exception('Failed to load dashboard data: $e');
  }
  throw Exception('Failed to load dashboard data');
});

final adminUsersProvider = FutureProvider<List<User>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).getAdminUsers();
    if (res.statusCode == 200 && res.data is List) {
      return (res.data as List)
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  } catch (_) {}
  return [];
});

class AdminState {
  final bool isCreating;
  final String? message;
  final bool isError;

  const AdminState({
    this.isCreating = false,
    this.message,
    this.isError = false,
  });

  AdminState copyWith({
    bool? isCreating,
    String? message,
    bool? isError,
  }) {
    return AdminState(
      isCreating: isCreating ?? this.isCreating,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class AdminController extends StateNotifier<AdminState> {
  final ApiClient _api;
  final Ref _ref;

  AdminController(this._api, this._ref) : super(const AdminState());

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(isCreating: true, message: null, isError: false);
    try {
      final res = await _api.createAdminUser({
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'role': role,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        state = state.copyWith(
          isCreating: false,
          message: 'Account created successfully.',
          isError: false,
        );
        _ref.invalidate(adminUsersProvider);
        return true;
      }
      state = state.copyWith(
        isCreating: false,
        message: 'Failed to create account.',
        isError: true,
      );
      return false;
    } catch (e) {
      String msg = 'Failed to create account. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          msg = data['detail'] ??
              (data['email'] is List ? data['email'][0] : null) ??
              (data['password'] is List ? data['password'][0] : null) ??
              (data['non_field_errors'] is List
                  ? data['non_field_errors'][0]
                  : null) ??
              data.values.first.toString();
        }
      }
      state = state.copyWith(isCreating: false, message: msg, isError: true);
      return false;
    }
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>((ref) {
  return AdminController(ref.watch(apiClientProvider), ref);
});