import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import 'logger.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../security/security_config.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;
  bool _refreshing = false;

  /// Invoked when the 401 recovery (token refresh) fails, so the app can
  /// sign the user out instead of silently running with an expired session.
  Future<void> Function()? onSessionExpired;

  ApiClient(this._dio, this._storageService) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Add security interceptor
    _dio.interceptors.add(SecurityInterceptor(SecurityConfig.instance));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Log API call
          Logger.logApiCall(
            options.method,
            options.path,
            params: options.queryParameters,
          );

          // Add authentication token except for public auth endpoints
          final isAuthEndpoint =
              options.path.contains('/auth/login/') ||
              options.path.contains('/auth/register/') ||
              options.path.contains('/auth/refresh/') ||
              options.path.contains('/auth/password-reset/');

          if (!isAuthEndpoint) {
            final token = await _storageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Don't override content type for multipart/form-data requests — Dio sets
          // the correct multipart boundary automatically when a FormData body is used.
          final isFormData = options.data is FormData;
          if (!isFormData) {
            options.headers['Content-Type'] = 'application/json';
          }
          options.headers['Accept'] = 'application/json';

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log API response
          Logger.logApiResponse(
            response.requestOptions.path,
            response.statusCode ?? 0,
            data: response.data,
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log API error
          Logger.logApiError(
            error.requestOptions.path,
            error.response?.statusCode ?? 0,
            errorMessage: error.message,
          );

          // Handle token refresh for 401 errors, but not for auth endpoints that
          // already involve authentication (e.g. login with wrong credentials) or
          // for the refresh request itself (prevents infinite refresh recursion).
          final path = error.requestOptions.path;
          final isAuthEndpoint =
              path.contains('/auth/login/') || path.contains('/auth/refresh/');
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              !alreadyRetried &&
              !_refreshing) {
            try {
              _refreshing = true;
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the original request once with the fresh token.
                final token = await _storageService.getAccessToken();
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $token';
                opts.extra['retried'] = true;

                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (e) {
              Logger.error('Token refresh failed', error: e);
              // Token refresh failed, so the session can no longer be trusted.
              await _sessionExpired();
              return handler.next(error);
            } finally {
              _refreshing = false;
            }

            // Refresh returned false (no/invalid refresh token): sign out.
            await _sessionExpired();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _sessionExpired() async {
    await _storageService.clearAuthData();
    await onSessionExpired?.call();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        await _storageService.saveAccessToken(access);
        return true;
      }
    } catch (e) {
      Logger.error('Token refresh failed', error: e);
    }
    return false;
  }

  // HTTP Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(path, queryParameters: queryParameters);
  }

  // File upload
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
  }) {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromFileSync(filePath),
      ...?data,
    });
    return _dio.post(path, data: formData);
  }

  // Multiple file upload
  Future<Response> uploadFiles(
    String path,
    List<String> filePaths, {
    Map<String, dynamic>? data,
  }) {
    final formData = FormData.fromMap({
      for (var i = 0; i < filePaths.length; i++)
        'files[$i]': MultipartFile.fromFileSync(filePaths[i]),
      ...?data,
    });
    return _dio.post(path, data: formData);
  }

  // ── Authentication ──
  Future<Response> login(String emailOrPhone, String password) {
    return post(
      ApiEndpoints.login,
      data: {'email': emailOrPhone, 'password': password},
    );
  }

  Future<Response> getCurrentUser() {
    return get(ApiEndpoints.me);
  }

  Future<Response> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? consentPolicyVersion,
    String preferredLanguage = 'en',
  }) {
    // DRF's phone field is `required=False, allow_blank=True` but NOT
    // `allow_null` — sending `"phone": null` is rejected with a 400, so the
    // key must be omitted entirely when there is no number.
    return post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (consentPolicyVersion != null && consentPolicyVersion.isNotEmpty)
          'consent_policy_version': consentPolicyVersion,
        'preferred_language': preferredLanguage,
      },
    );
  }

  Future<Response> logout(String refreshToken) {
    return post(
      ApiEndpoints.logout,
      data: {'refresh': refreshToken},
    );
  }

  Future<Response> registerDevice(String token) {
    return post(
      ApiEndpoints.registerDevice,
      data: {'token': token, 'device_type': 'mobile'},
    );
  }

  Future<Response> unregisterDevice(String token) {
    return post(
      ApiEndpoints.unregisterDevice,
      data: {'token': token},
    );
  }

  Future<Response> sendOtp(String identifier, {String purpose = 'PHONE_VERIFY'}) {
    return post(
      ApiEndpoints.resendOtp,
      data: {'identifier': identifier, 'purpose': purpose},
    );
  }

  Future<Response> verifyOtp(
    String emailOrPhone,
    String code, {
    String purpose = 'PHONE_VERIFY',
  }) {
    return post(
      ApiEndpoints.verifyOtp,
      data: {'identifier': emailOrPhone, 'otp_code': code, 'purpose': purpose},
    );
  }

  Future<Response> requestPasswordReset(String email) {
    return post(ApiEndpoints.passwordReset, data: {'email': email});
  }

  Future<Response> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) {
    return post(
      ApiEndpoints.passwordResetConfirm,
      data: {'token': token, 'new_password': newPassword},
    );
  }

  Future<Response> getProfile() {
    return get(ApiEndpoints.profile);
  }

  // ── Waste Requests ──
  Future<Response> getWasteCategories() {
    return get(ApiEndpoints.wasteCategories);
  }

  Future<Response> getMyRequests() {
    return get(ApiEndpoints.myWasteRequests);
  }

  Future<Response> createWasteRequest(Map<String, dynamic> data) {
    return post(ApiEndpoints.wasteRequests, data: data);
  }

  Future<Response> getRequestDetail(String id) {
    return get(ApiEndpoints.wasteRequest(id));
  }

  Future<Response> cancelRequest(String id, String reason) {
    return post(ApiEndpoints.cancelWasteRequest(id), data: {'reason': reason});
  }

  // ── Payments ──
  Future<Response> initiatePayment({
    required String wasteRequestId,
    required String phoneNumber,
    required String method,
    required double amount,
  }) {
    return post(
      ApiEndpoints.initiatePayment,
      data: {
        'waste_request_id': wasteRequestId,
        'phone_number': phoneNumber,
        'method': method,
        'amount': amount,
      },
    );
  }

  Future<Response> getMyPayments() {
    return get(ApiEndpoints.myPayments);
  }

  // ── Collector ──
  Future<Response> getCollectorDashboard() {
    return get(ApiEndpoints.collectorDashboard);
  }

  Future<Response> getAssignments({String? status}) {
    return get(
      ApiEndpoints.assignments,
      queryParameters: {'status': ?status},
    );
  }

  Future<Response> startShift() {
    return post(ApiEndpoints.shifts);
  }

  Future<Response> endShift(String shiftId) {
    return post(ApiEndpoints.shiftEnd(shiftId));
  }

  Future<Response> assignmentStartTrip(String assignmentId) {
    return post(ApiEndpoints.assignmentStartTrip(assignmentId));
  }

  Future<Response> assignmentArrive(String assignmentId) {
    return post(ApiEndpoints.assignmentArrive(assignmentId));
  }

  Future<Response> assignmentComplete(
    String assignmentId, {
    double? collectedWeightKg,
    String? notes,
  }) {
    return post(
      ApiEndpoints.assignmentComplete(assignmentId),
      data: {
        'collected_weight_kg': ?collectedWeightKg,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<Response> assignmentReject(String assignmentId, {String? reason}) {
    return post(
      ApiEndpoints.assignmentReject(assignmentId),
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  // ── Rewards ──
  Future<Response> getRewardsStatus() {
    return get(ApiEndpoints.rewardsStatus);
  }

  Future<Response> getRewardsHistory() {
    return get(ApiEndpoints.rewardsHistory);
  }

  Future<Response> getRedemptionItems() {
    return get(ApiEndpoints.redemptionItems);
  }

  Future<Response> redeemItem(String id) {
    return post(ApiEndpoints.redeemItem(id));
  }

  // ── Reports ──
  Future<Response> submitIllegalDumpingReport(Map<String, dynamic> data) {
    return post(ApiEndpoints.reports, data: data);
  }

  Future<Response> uploadReportPhoto(
    String reportId,
    List<int> bytes,
    String filename,
  ) {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return post(
      '${ApiEndpoints.reports}$reportId/upload_photo/',
      data: formData,
    );
  }

  Future<Response> getMyReports() {
    return get(ApiEndpoints.myReports);
  }

  Future<Response> getReports({String? status, String? severity}) {
    return get(
      ApiEndpoints.reports,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
      },
    );
  }

  Future<Response> resolveReport(String id, {String? notes}) {
    return post(
      ApiEndpoints.reportResolve(id),
      data: {
        if (notes != null && notes.trim().isNotEmpty)
          'resolution_notes': notes.trim(),
      },
    );
  }

  // ── Recycling ──
  Future<Response> getRecyclableMaterials() {
    return get(ApiEndpoints.recyclingMaterials);
  }

  Future<Response> getRecyclingCenters() {
    return get(ApiEndpoints.recyclingCenters);
  }

  Future<Response> getMarketplaceListings({String? status}) {
    return get(
      ApiEndpoints.recyclingMarketplace,
      queryParameters: {'status': ?status},
    );
  }

  Future<Response> createMarketplaceListing(Map<String, dynamic> data) {
    return post(ApiEndpoints.recyclingMarketplace, data: data);
  }

  Future<Response> reserveListing(String id) {
    return post(ApiEndpoints.recyclingListingReserve(id));
  }

  Future<Response> markListingSold(String id) {
    return post(ApiEndpoints.recyclingListingSold(id));
  }

  Future<Response> getTradeIns({String? status}) {
    return get(
      ApiEndpoints.recyclingTradeIns,
      queryParameters: {'status': ?status},
    );
  }

  Future<Response> createTradeIn(Map<String, dynamic> data) {
    return post(ApiEndpoints.recyclingTradeIns, data: data);
  }

  Future<Response> verifyTradeIn(String id) {
    return post('${ApiEndpoints.recyclingTradeIns}$id/verify/');
  }

  // ── Notifications ──
  Future<Response> getNotifications() {
    return get(ApiEndpoints.notifications);
  }

  Future<Response> markNotificationRead(String id) {
    return post(ApiEndpoints.markRead(id));
  }

  Future<Response> markAllNotificationsRead() {
    return post(ApiEndpoints.markAllRead);
  }

  // ── Analytics ──
  Future<Response> getAnalyticsOverview() {
    return get(ApiEndpoints.analyticsOverview);
  }

  // ── AI Classification ──
  Future<Response> classifyWasteImage(FormData formData) {
    return post(ApiEndpoints.classify, data: formData);
  }

  // ── Platform Admin ──
  Future<Response> getAdminDashboard() {
    return get(ApiEndpoints.adminDashboard);
  }

  Future<Response> getAdminUsers() {
    return get(ApiEndpoints.adminUsers);
  }

  Future<Response> createAdminUser(Map<String, dynamic> data) {
    return post(ApiEndpoints.adminUsers, data: data);
  }

  Future<Response> getVerifications({String? status}) {
    return get(
      ApiEndpoints.adminVerifications,
      queryParameters: {'status': ?status},
    );
  }

  Future<Response> approveVerification(String id, {String? notes}) {
    return post(
      ApiEndpoints.approveVerification(id),
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
  }

  Future<Response> rejectVerification(String id, {String? notes}) {
    return post(
      ApiEndpoints.rejectVerification(id),
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
  }

  Future<Response> getSystemSettings() {
    return get(ApiEndpoints.adminSettings);
  }

  Future<Response> updateSystemSetting(String id, Map<String, dynamic> data) {
    return patch(ApiEndpoints.adminSetting(id), data: data);
  }

  Future<Response> getPrivacyPolicies() {
    return get(ApiEndpoints.adminPolicies);
  }

  Future<Response> publishPrivacyPolicy(Map<String, dynamic> data) {
    return post(ApiEndpoints.adminPublishPolicy, data: data);
  }

  Future<Response> getNeedsReconsent() {
    return get(ApiEndpoints.adminNeedsReconsent);
  }

  Future<Response> getPayouts({String? status}) {
    return get(
      ApiEndpoints.payouts,
      queryParameters: {'status': ?status},
    );
  }

  // ── Profile ──
  Future<Response> updateProfile(Map<String, dynamic> data) {
    return patch(ApiEndpoints.profileUpdate, data: data);
  }

  // ── Schedules (recurring pickups) ──
  Future<Response> getSchedules() {
    return get(ApiEndpoints.schedules);
  }

  Future<Response> createSchedule(Map<String, dynamic> data) {
    return post(ApiEndpoints.schedules, data: data);
  }

  Future<Response> toggleSchedule(String id, {required bool isActive}) {
    return patch(
      ApiEndpoints.schedule(id),
      data: {'is_active': isActive},
    );
  }

  // ── Invoices / receipts ──
  Future<Response> getInvoices() {
    return get('${ApiEndpoints.payments}invoices/');
  }

  // ── Ratings ──
  Future<Response> submitRating({
    required int toUserId,
    required int score,
    String? review,
    String? wasteRequestId,
  }) {
    return post(
      ApiEndpoints.ratings,
      data: {
        'to_user': toUserId,
        'score': score,
        'review': review,
        'waste_request': ?wasteRequestId,
      },
    );
  }

  Future<Response> getUserRatingSummary(String userId) {
    return get(ApiEndpoints.userRatings(userId));
  }

  Future<Response> lookupCollector({String? email, String? query}) {
    return get(
      ApiEndpoints.lookupCollector,
      queryParameters: {
        'email': ?email,
        'q': ?query,
      },
    );
  }

  // ── Support tickets ──
  Future<Response> getTickets() {
    return get(ApiEndpoints.supportTickets);
  }

  Future<Response> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String message,
  }) {
    return post(
      ApiEndpoints.supportTickets,
      data: {
        'subject': subject,
        'category': category,
        'priority': priority,
        'message': message,
      },
    );
  }

  Future<Response> getTicketDetail(String id) {
    return get(ApiEndpoints.supportTicket(id));
  }

  Future<Response> sendTicketMessage(String ticketId, String message) {
    return post(
      ApiEndpoints.ticketMessages(ticketId),
      data: {'message': message},
    );
  }

  // ── Chat ──
  Future<Response> getChatConversations() {
    return get(ApiEndpoints.chatConversations);
  }

  Future<Response> createConversationForRequest(String wasteRequestId) {
    return post(
      ApiEndpoints.chatCreateForRequest,
      data: {'waste_request': wasteRequestId},
    );
  }

  Future<Response> getConversationForRequest(String wasteRequestId) {
    return get(
      ApiEndpoints.chatForRequest,
      queryParameters: {'waste_request': wasteRequestId},
    );
  }

  Future<Response> sendChatMessage(String conversationId, String content) {
    return post(
      ApiEndpoints.chatSendMessage(conversationId),
      data: {'content': content},
    );
  }

  Future<Response> markChatRead(String conversationId) {
    return post(ApiEndpoints.chatMarkRead(conversationId));
  }

  // ── Analytics ──
  Future<Response> getAnalyticsFinancials() {
    return get(ApiEndpoints.analyticsFinancials);
  }

  Future<Response> getAnalyticsCollections() {
    return get(ApiEndpoints.analyticsCollections);
  }

  Future<Response> getAnalyticsHotspots() {
    return get(ApiEndpoints.analyticsHotspots);
  }

  // ── Zones ──
  Future<Response> getZones() {
    return get(ApiEndpoints.adminZones);
  }

  Future<Response> assignCollectorZone(String zoneId, int userId) {
    return post(
      '${ApiEndpoints.adminZones}$zoneId/assign_collector/',
      data: {'user_id': userId},
    );
  }

  // ── Tracking ──
  Future<Response> getCollectorLiveLocation(String assignmentId) {
    return get(ApiEndpoints.trackingLive(assignmentId));
  }
}

// Provider for API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: ApiConstants.apiBaseUrl,
      ),
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ),
  );

  final storageService = ref.watch(storageServiceProvider);
  return ApiClient(dio, storageService);
});
