/// All API endpoint paths — ported from api/endpoints.ts
class ApiEndpoints {
  ApiEndpoints._();

  // ── Authentication ──
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String tokenRefresh = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String me = '/auth/me/';
  static const String passwordReset = '/auth/password-reset/';
  static const String passwordResetConfirm = '/auth/password-reset/confirm/';
  static const String verifyOtp = '/auth/otp/verify/';
  static const String resendOtp = '/auth/otp/send/';

  // ── Profile ──
  static const String profile = '/profiles/me/';
  static const String profileUpdate = '/profiles/me/';
  static const String profileAvatar = '/profiles/me/avatar/';
  static String userProfile(String id) => '/profiles/$id/';

  // ── Waste Categories ──
  static const String wasteCategories = '/waste-requests/categories/';
  static String wasteCategory(String id) => '/waste-requests/categories/$id/';

  // ── Waste Requests ──
  static const String wasteRequests = '/waste-requests/';
  static String wasteRequest(String id) => '/waste-requests/$id/';
  static String cancelWasteRequest(String id) => '/waste-requests/$id/cancel/';
  static const String myWasteRequests = '/waste-requests/';
  static const String pendingWasteRequests = '/waste-requests/?status=PENDING';
  static String wasteRequestPhotos(String requestId) =>
      '/waste-requests/$requestId/photos/';

  // ── Schedules ──
  static const String schedules = '/waste-requests/schedules/';
  static String schedule(String id) => '/waste-requests/schedules/$id/';

  // ── Collection Slots ──
  static const String collectionSlots = '/collections/slots/';

  // ── Assignments ──
  static const String assignments = '/collections/assignments/';
  static String assignment(String id) => '/collections/assignments/$id/';
  static String assignmentStartTrip(String id) =>
      '/collections/assignments/$id/start_trip/';
  static String assignmentArrive(String id) =>
      '/collections/assignments/$id/arrive/';
  static String assignmentComplete(String id) =>
      '/collections/assignments/$id/complete/';
  static String assignmentReject(String id) =>
      '/collections/assignments/$id/reject/';

  // ── Shifts ──
  static const String shifts = '/collections/shifts/';
  static String shift(String id) => '/collections/shifts/$id/';
  static String shiftEnd(String id) => '/collections/shifts/$id/end_shift/';

  // ── Collector Dashboard ──
  static const String collectorDashboard = '/collections/dashboard/';

  // ── Routes ──
  static const String routes = '/routing/routes/';
  static String route(String id) => '/routing/$id/';
  static String optimizeRoute(String id) => '/routing/$id/optimize/';

  // ── Payments ──
  static const String payments = '/payments/';
  static String payment(String id) => '/payments/$id/';
  static const String paymentPreview = '/payments/preview/';
  static const String initiatePayment = '/payments/initiate/';
  static String paymentCallback(String id) => '/payments/$id/callback/';
  static const String myPayments = '/payments/';

  // ── Payouts ──
  static const String payouts = '/payments/payouts/';
  static const String myPayouts = '/payments/payouts/';

  // ── Notifications ──
  static const String notifications = '/notifications/';
  static String notification(String id) => '/notifications/$id/';
  static String markRead(String id) => '/notifications/$id/mark_as_read/';
  static const String markAllRead = '/notifications/mark_all_as_read/';
  static const String notificationPreferences = '/notifications/preferences/';
  static const String registerDevice = '/notifications/register_device/';
  static const String unregisterDevice = '/notifications/unregister_device/';

  // ── Rewards ──
  static const String rewardsStatus = '/rewards/wallet/';
  static const String rewardsHistory = '/rewards/redemptions/';
  static const String rewardsTiers = '/rewards/tiers/';
  static const String redemptionItems = '/rewards/items/';
  static String redeemItem(String id) => '/rewards/items/$id/redeem/';
  static const String myRedemptions = '/rewards/redemptions/';

  // ── Reports (Illegal Dumping) ──
  static const String reports = '/reports/';
  static String report(String id) => '/reports/$id/';
  static String reportResolve(String id) => '/reports/$id/resolve/';
  static String reportPhotos(String reportId) => '/reports/$reportId/photos/';
  static const String myReports = '/reports/';

  // ── Tracking ──
  static const String trackingUpdate = '/tracking/live/';
  static String trackingLive(String assignmentId) =>
      '/tracking/collector/$assignmentId/';

  // ── Support ──
  static const String supportTickets = '/support/tickets/';
  static String supportTicket(String id) => '/support/tickets/$id/';
  static String ticketMessages(String ticketId) =>
      '/support/tickets/$ticketId/add_message/';
  static const String myTickets = '/support/tickets/';

  // ── Chat ──
  static const String chatConversations = '/chat/conversations/';
  static String chatConversation(String id) => '/chat/conversations/$id/';
  static const String chatCreateForRequest = '/chat/conversations/create_for_request/';
  static const String chatForRequest = '/chat/conversations/for_request/';
  static String chatSendMessage(String id) =>
      '/chat/conversations/$id/send_message/';
  static String chatMarkRead(String id) => '/chat/conversations/$id/mark_read/';

  // ── Ratings ──
  static const String ratings = '/ratings/reviews/';
  static String rating(String id) => '/ratings/reviews/$id/';
  static String userRatings(String userId) => '/ratings/reviews/user/$userId/';
  static const String lookupCollector = '/ratings/reviews/lookup_collector/';

  // ── Incident Reports ──
  static const String incidents = '/ratings/incidents/';
  static String incident(String id) => '/ratings/incidents/$id/';

  // ── Recycling ──
  static const String recyclingMaterials = '/recycling/materials/';
  static const String recyclingCenters = '/recycling/centers/';
  static const String recyclingMarketplace = '/recycling/marketplace/';
  static String recyclingListing(String id) => '/recycling/marketplace/$id/';
  static String recyclingListingReserve(String id) =>
      '/recycling/marketplace/$id/reserve/';
  static String recyclingListingSold(String id) =>
      '/recycling/marketplace/$id/mark_sold/';
  static const String recyclingTradeIns = '/recycling/trade-ins/';

  // ── AI / Classification ──
  static const String classify = '/ai/classify-waste/';

  // ── Zones ──
  static const String zones = '/profiles/';
  static String zone(String id) => '/profiles/$id/';

  // ── Analytics ──
  static const String analyticsOverview = '/analytics/overview/';
  static const String analyticsCollections = '/analytics/collections/';
  static const String analyticsFinancials = '/analytics/financials/';
  static const String analyticsEnvironmental = '/analytics/environmental/';
  static const String analyticsUsers = '/analytics/users/';
  static const String analyticsHotspots = '/analytics/hotspots/';
  static const String analyticsExport = '/analytics/export/';

  // ── Platform Admin ──
  static const String adminDashboard = '/admin/dashboard/';
  static const String adminUsers = '/admin/users/';
  static const String adminVerifications = '/admin/verifications/';
  static String adminVerification(String id) => '/admin/verifications/$id/';
  static String approveVerification(String id) => '/admin/verifications/$id/approve/';
  static String rejectVerification(String id) => '/admin/verifications/$id/reject/';
  static const String adminZones = '/admin/zones/';
  static String adminZone(String id) => '/admin/zones/$id/';
  static const String adminSettings = '/admin/settings/';
  static String adminSetting(String id) => '/admin/settings/$id/';
  static const String adminPolicies = '/admin/policies/';
  static String adminPolicy(String id) => '/admin/policies/$id/';
  static const String adminPublishPolicy = '/admin/privacy-policy/publish/';
  static const String adminNeedsReconsent = '/admin/privacy-policy/needs-reconsent/';
  static const String adminConsentPolicy = '/admin/privacy-policy/consent/';

  // ── Security ──
  static const String auditLogs = '/security/audit-logs/';
}
