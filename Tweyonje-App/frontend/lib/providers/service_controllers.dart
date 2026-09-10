import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_client.dart';
import '../models/models.dart';
import 'auth_provider.dart';

String _errorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      return data['detail'] ??
          (data['error'] is String ? data['error'] : null) ??
          (data['message'] is String ? data['message'] : null) ??
          'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

// ─────────────────────────── Recurring scheduled pickups ───────────────────────────

class ScheduleState {
  final List<RecurringSchedule> schedules;
  final bool isLoading;
  final bool isCreating;
  final String? message;
  final bool isError;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.message,
    this.isError = false,
  });

  ScheduleState copyWith({
    List<RecurringSchedule>? schedules,
    bool? isLoading,
    bool? isCreating,
    String? message,
    bool? isError,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class ScheduleController extends StateNotifier<ScheduleState> {
  final ApiClient _api;

  ScheduleController(this._api) : super(const ScheduleState());

  Future<void> fetch({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getSchedules();
      if (res.statusCode == 200) {
        final List results =
            res.data is List ? res.data : (res.data['results'] ?? []);
        state = state.copyWith(
          schedules: results
              .map((s) => RecurringSchedule.fromJson(Map<String, dynamic>.from(s)))
              .toList(),
          isLoading: false,
        );
        return;
      }
    } catch (_) {}
    if (!silent) state = state.copyWith(isLoading: false);
  }

  Future<bool> create(Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, message: null, isError: false);
    try {
      final res = await _api.createSchedule(data);
      if (res.statusCode == 201 || res.statusCode == 200) {
        final schedule = RecurringSchedule.fromJson(
          Map<String, dynamic>.from(res.data),
        );
        state = state.copyWith(
          schedules: [...state.schedules, schedule],
          isCreating: false,
          message: 'Scheduled pickup created successfully.',
          isError: false,
        );
        return true;
      }
      state = state.copyWith(
        isCreating: false,
        message: 'Failed to create scheduled pickup.',
        isError: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        message: _errorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> toggle(String id) async {
    try {
      await _api.toggleSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.map((s) {
          if (s.id == id) {
            return RecurringSchedule(
              id: s.id,
              category: s.category,
              categoryName: s.categoryName,
              frequency: s.frequency,
              preferredWeekday: s.preferredWeekday,
              preferredTime: s.preferredTime,
              address: s.address,
              latitude: s.latitude,
              longitude: s.longitude,
              zone: s.zone,
              isActive: !s.isActive,
              nextRun: s.nextRun,
              createdAt: s.createdAt,
            );
          }
          return s;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleController, ScheduleState>((ref) {
  return ScheduleController(ref.watch(apiClientProvider));
});

// ─────────────────────────── Payment history & receipts ───────────────────────────

class PaymentHistoryState {
  final List<Payment> payments;
  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;

  const PaymentHistoryState({
    this.payments = const [],
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  PaymentHistoryState copyWith({
    List<Payment>? payments,
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
  }) {
    return PaymentHistoryState(
      payments: payments ?? this.payments,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaymentHistoryController extends StateNotifier<PaymentHistoryState> {
  final ApiClient _api;

  PaymentHistoryController(this._api) : super(const PaymentHistoryState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payRes = await _api.getMyPayments();
      List<Payment> payments = state.payments;
      if (payRes.statusCode == 200) {
        final List results =
            payRes.data is List ? payRes.data : (payRes.data['results'] ?? []);
        payments = results
            .map((p) => Payment.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }

      List<Invoice> invoices = state.invoices;
      try {
        final invRes = await _api.getInvoices();
        if (invRes.statusCode == 200) {
          final List results =
              invRes.data is List ? invRes.data : (invRes.data['results'] ?? []);
          invoices = results
              .map((i) => Invoice.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        }
      } catch (_) {}

      state = state.copyWith(
        payments: payments,
        invoices: invoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }
}

final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryController, PaymentHistoryState>((ref) {
  return PaymentHistoryController(ref.watch(apiClientProvider));
});

// ─────────────────────────── Ratings ───────────────────────────

class RatingState {
  final bool isSubmitting;
  final String? message;
  final bool isError;

  const RatingState({
    this.isSubmitting = false,
    this.message,
    this.isError = false,
  });

  RatingState copyWith({
    bool? isSubmitting,
    String? message,
    bool? isError,
  }) {
    return RatingState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class RatingController extends StateNotifier<RatingState> {
  final ApiClient _api;

  RatingController(this._api) : super(const RatingState());

  Future<bool> submit({
    required int toUserId,
    required int score,
    String? review,
    String? wasteRequestId,
  }) async {
    state = state.copyWith(isSubmitting: true, message: null, isError: false);
    try {
      final res = await _api.submitRating(
        toUserId: toUserId,
        score: score,
        review: review,
        wasteRequestId: wasteRequestId,
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        state = state.copyWith(
          isSubmitting: false,
          message: 'Thank you! Your review has been submitted.',
          isError: false,
        );
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        message: 'Failed to submit review.',
        isError: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        message: _errorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  void clearMessage() {
    state = state.copyWith(message: null, isError: false);
  }
}

final ratingControllerProvider =
    StateNotifierProvider<RatingController, RatingState>((ref) {
  return RatingController(ref.watch(apiClientProvider));
});

final ratingSummaryProvider =
    FutureProvider.family<RatingSummary?, String>((ref, userId) async {
  final res = await ref.watch(apiClientProvider).getUserRatingSummary(userId);
  if (res.statusCode == 200 && res.data is Map) {
    return RatingSummary.fromJson(Map<String, dynamic>.from(res.data));
  }
  return null;
});

// ─────────────────────────── Support tickets ───────────────────────────

class SupportState {
  final List<SupportTicket> tickets;
  final bool isLoading;
  final bool isCreating;
  final bool isSending;
  final String? message;
  final bool isError;

  const SupportState({
    this.tickets = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isSending = false,
    this.message,
    this.isError = false,
  });

  SupportState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    bool? isCreating,
    bool? isSending,
    String? message,
    bool? isError,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isSending: isSending ?? this.isSending,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class SupportController extends StateNotifier<SupportState> {
  final ApiClient _api;

  SupportController(this._api) : super(const SupportState());

  Future<void> fetchTickets({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getTickets();
      if (res.statusCode == 200) {
        final List results =
            res.data is List ? res.data : (res.data['results'] ?? []);
        state = state.copyWith(
          tickets: results
              .map((t) => SupportTicket.fromJson(Map<String, dynamic>.from(t)))
              .toList(),
          isLoading: false,
        );
        return;
      }
    } catch (_) {}
    if (!silent) state = state.copyWith(isLoading: false);
  }

  Future<bool> create({
    required String subject,
    required String category,
    required String priority,
    required String message,
  }) async {
    state = state.copyWith(isCreating: true, message: null, isError: false);
    try {
      final res = await _api.createTicket(
        subject: subject,
        category: category,
        priority: priority,
        message: message,
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final ticket =
            SupportTicket.fromJson(Map<String, dynamic>.from(res.data));
        state = state.copyWith(
          tickets: [ticket, ...state.tickets],
          isCreating: false,
          message: 'Ticket #${ticket.ticketNumber} created successfully.',
          isError: false,
        );
        return true;
      }
      state = state.copyWith(
        isCreating: false,
        message: 'Failed to create ticket.',
        isError: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        message: _errorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> sendMessage(
    String ticketId,
    String content, {
    bool announce = true,
  }) async {
    state = state.copyWith(isSending: true);
    try {
      final res = await _api.sendTicketMessage(ticketId, content);
      if (res.statusCode == 201 || res.statusCode == 200) {
        final msg = TicketMessage.fromJson(Map<String, dynamic>.from(res.data));
        state = state.copyWith(
          tickets: state.tickets.map((t) {
            if (t.id == ticketId) {
              return SupportTicket(
                id: t.id,
                ticketNumber: t.ticketNumber,
                subject: t.subject,
                category: t.category,
                priority: t.priority,
                status: res.data['ticket'] != null ? t.status : t.status,
                createdAt: t.createdAt,
                updatedAt: t.updatedAt,
                messages: [...t.messages, msg],
              );
            }
            return t;
          }).toList(),
          isSending: false,
          isError: false,
          message: announce ? 'Message sent.' : null,
        );
        return true;
      }
      state = state.copyWith(
        isSending: false,
        isError: true,
        message: 'Failed to send message.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        isError: true,
        message: _errorMessage(e),
      );
      return false;
    }
  }
}

final supportProvider = StateNotifierProvider<SupportController, SupportState>((ref) {
  return SupportController(ref.watch(apiClientProvider));
});

// ─────────────────────────── Chat ───────────────────────────

class ChatState {
  final List<ChatConversation> conversations;
  final List<ChatMessage>? openMessages;
  final String? openConversationId;
  final bool isLoading;
  final bool isSending;
  final String? message;
  final bool isError;

  const ChatState({
    this.conversations = const [],
    this.openMessages,
    this.openConversationId,
    this.isLoading = false,
    this.isSending = false,
    this.message,
    this.isError = false,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    List<ChatMessage>? openMessages,
    String? openConversationId,
    bool? isLoading,
    bool? isSending,
    String? message,
    bool? isError,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      openMessages: openMessages ?? this.openMessages,
      openConversationId: openConversationId ?? this.openConversationId,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ApiClient _api;
  final Ref _ref;

  ChatController(this._api, this._ref) : super(const ChatState());

  int get _currentUserId => _ref.read(authProvider).user?.id ?? 0;

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getChatConversations();
      if (res.statusCode == 200) {
        final List results =
            res.data is List ? res.data : (res.data['results'] ?? []);
        if (res.data is Map && res.data['results'] == null && results.isEmpty) {
          results.add(res.data);
        }
        final sessions = results
            .map((c) => ChatConversation.fromJson(
                  Map<String, dynamic>.from(c),
                  currentUserId: _currentUserId,
                ))
            .toList();
        state = state.copyWith(conversations: sessions, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<ChatConversation?> openForRequest(String wasteRequestId) async {
    ChatConversation? existing;
    try {
      final res = await _api.getConversationForRequest(wasteRequestId);
      if (res.statusCode == 200 && res.data is Map) {
        existing = ChatConversation.fromJson(
          Map<String, dynamic>.from(res.data),
          currentUserId: _currentUserId,
        );
      }
    } catch (_) {}

    if (existing == null) {
      try {
        final res = await _api.createConversationForRequest(wasteRequestId);
        if (res.statusCode == 200 && res.data is Map) {
          existing = ChatConversation.fromJson(
            Map<String, dynamic>.from(res.data),
            currentUserId: _currentUserId,
          );
        }
      } catch (e) {
        state = state.copyWith(
          message: _errorMessage(e),
          isError: true,
        );
        return null;
      }
    }

    if (existing == null) return null;
    _prepareOpen(existing);
    return existing;
  }

  Future<void> openConversation(ChatConversation conversation) async {
    _prepareOpen(conversation);
  }

  void _prepareOpen(ChatConversation conversation) {
    state = state.copyWith(
      openMessages: conversation.messages,
      openConversationId: conversation.id,
      message: null,
      isError: false,
    );
  }

  Future<bool> send(String conversationId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return false;
    state = state.copyWith(isSending: true);
    try {
      final res = await _api.sendChatMessage(conversationId, text);
      if (res.statusCode == 201 || res.statusCode == 200) {
        final msg = ChatMessage.fromJson(Map<String, dynamic>.from(res.data));
        state = state.copyWith(
          openMessages: [...?state.openMessages, msg],
          isSending: false,
          message: null,
          isError: false,
        );
        await markRead(conversationId);
        return true;
      }
      state = state.copyWith(
        isSending: false,
        message: 'Failed to send message.',
        isError: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        message: _errorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _api.markChatRead(conversationId);
    } catch (_) {}
  }

  Future<void> refreshForRequest(String wasteRequestId) async {
    try {
      final res = await _api.getConversationForRequest(wasteRequestId);
      if (res.statusCode == 200 && res.data is Map) {
        final conversation = ChatConversation.fromJson(
          Map<String, dynamic>.from(res.data),
          currentUserId: _currentUserId,
        );
        state = state.copyWith(
          openMessages: conversation.messages,
          openConversationId: conversation.id,
        );
      }
    } catch (_) {}
  }
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(apiClientProvider), ref);
});

// ─────────────────────────── Live tracking ───────────────────────────

class TrackingState {
  final LiveLocation? location;
  final bool isLoading;
  final bool isLive;
  final String? error;

  const TrackingState({
    this.location,
    this.isLoading = false,
    this.isLive = false,
    this.error,
  });

  TrackingState copyWith({
    LiveLocation? location,
    bool? isLoading,
    bool? isLive,
    String? error,
  }) {
    return TrackingState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      isLive: isLive ?? this.isLive,
      error: error,
    );
  }
}

class TrackingController extends StateNotifier<TrackingState> {
  final ApiClient _api;
  final String requestId;
  Timer? _timer;

  TrackingController(this._api, this.requestId) : super(const TrackingState());

  void start() {
    fetch();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetch(silent: true));
  }

  Future<void> fetch({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getCollectorLiveLocation(requestId);
      if (res.statusCode == 200 && res.data is Map) {
        state = state.copyWith(
          location: LiveLocation.fromJson(Map<String, dynamic>.from(res.data)),
          isLoading: false,
          isLive: true,
          error: null,
        );
        return;
      }
    } catch (_) {}
    if (!silent) state = state.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final trackingProvider =
    StateNotifierProvider.family<TrackingController, TrackingState, String>(
        (ref, requestId) {
  return TrackingController(ref.watch(apiClientProvider), requestId);
});

// ─────────────────────────── Analytics ───────────────────────────

class AnalyticsState {
  final AnalyticsOverview? overview;
  final AnalyticsFinancials? financials;
  final List<AnalyticsHotspot> hotspots;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.overview,
    this.financials,
    this.hotspots = const [],
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    AnalyticsOverview? overview,
    AnalyticsFinancials? financials,
    List<AnalyticsHotspot>? hotspots,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      overview: overview ?? this.overview,
      financials: financials ?? this.financials,
      hotspots: hotspots ?? this.hotspots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  final ApiClient _api;

  AnalyticsController(this._api) : super(const AnalyticsState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overviewRes = await _api.getAnalyticsOverview();
      AnalyticsOverview? overview = state.overview;
      if (overviewRes.statusCode == 200 && overviewRes.data is Map) {
        overview = AnalyticsOverview.fromJson(
          Map<String, dynamic>.from(overviewRes.data),
        );
      }

      AnalyticsFinancials? financials = state.financials;
      try {
        final finRes = await _api.getAnalyticsFinancials();
        if (finRes.statusCode == 200 && finRes.data is Map) {
          financials = AnalyticsFinancials.fromJson(
            Map<String, dynamic>.from(finRes.data),
          );
        }
      } catch (_) {}

      List<AnalyticsHotspot> hotspots = state.hotspots;
      try {
        final hotspotRes = await _api.getAnalyticsHotspots();
        if (hotspotRes.statusCode == 200 &&
            (hotspotRes.data is List || hotspotRes.data['results'] is List)) {
          final List results = hotspotRes.data is List
              ? hotspotRes.data
              : hotspotRes.data['results'];
          hotspots = results
              .map((h) =>
                  AnalyticsHotspot.fromJson(Map<String, dynamic>.from(h)))
              .toList();
        }
      } catch (_) {}

      state = state.copyWith(
        overview: overview,
        financials: financials,
        hotspots: hotspots,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  return AnalyticsController(ref.watch(apiClientProvider));
});

// ─────────────────────────── Zone assignment (admin) ───────────────────────────

class ZoneAssignmentState {
  final List<Zone> zones;
  final bool isLoading;
  final bool isAssigning;
  final String? message;
  final bool isError;

  const ZoneAssignmentState({
    this.zones = const [],
    this.isLoading = false,
    this.isAssigning = false,
    this.message,
    this.isError = false,
  });

  ZoneAssignmentState copyWith({
    List<Zone>? zones,
    bool? isLoading,
    bool? isAssigning,
    String? message,
    bool? isError,
  }) {
    return ZoneAssignmentState(
      zones: zones ?? this.zones,
      isLoading: isLoading ?? this.isLoading,
      isAssigning: isAssigning ?? this.isAssigning,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class ZoneAssignmentController extends StateNotifier<ZoneAssignmentState> {
  final ApiClient _api;

  ZoneAssignmentController(this._api) : super(const ZoneAssignmentState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, message: null);
    try {
      final res = await _api.getZones();
      if (res.statusCode == 200) {
        final List results =
            res.data is List ? res.data : (res.data['results'] ?? []);
        state = state.copyWith(
          zones: results
              .map((z) => Zone.fromJson(Map<String, dynamic>.from(z)))
              .toList(),
          isLoading: false,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<bool> assignCollector(String zoneId, int userId) async {
    state = state.copyWith(isAssigning: true, message: null, isError: false);
    try {
      final res = await _api.assignCollectorZone(zoneId, userId);
      if (res.statusCode == 200) {
        state = state.copyWith(
          isAssigning: false,
          message: res.data['detail'] ?? 'Collector assigned to zone.',
          isError: false,
        );
        return true;
      }
      state = state.copyWith(
        isAssigning: false,
        message: _errorMessage(res),
        isError: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAssigning: false,
        message: _errorMessage(e),
        isError: true,
      );
      return false;
    }
  }
}

final zoneAssignmentProvider =
    StateNotifierProvider<ZoneAssignmentController, ZoneAssignmentState>((ref) {
  return ZoneAssignmentController(ref.watch(apiClientProvider));
});

// ─────────────────────────── App event bus (FCM-driven refresh) ───────────────────────────

enum AppEventType {
  requestUpdated,
  assignmentUpdated,
  collectionCompleted,
  paymentCompleted,
  notificationAdded,
  conversationUpdated,
  shiftChanged,
}

class AppEvent {
  final AppEventType type;
  final String? id;
  final String? message;

  const AppEvent(this.type, {this.id, this.message});
}

class AppEventBus extends ChangeNotifier {
  AppEvent? _last;

  void publish(AppEventType type, {String? id, String? message}) {
    _last = AppEvent(type, id: id, message: message);
    notifyListeners();
  }

  void consume() {
    _last = null;
  }

  AppEvent? get last => _last;
}

final appEventBusProvider = ChangeNotifierProvider<AppEventBus>((ref) {
  return AppEventBus();
});