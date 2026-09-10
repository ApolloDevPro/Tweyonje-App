// ignore_for_file: non_constant_identifier_names

enum UserRole {
  resident('RESIDENT'),
  business('BUSINESS'),
  collector('COLLECTOR'),
  recycler('RECYCLER'),
  authority('AUTHORITY'),
  administrator('ADMINISTRATOR');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => UserRole.resident,
    );
  }
}

class User {
  final int id;
  final String email;
  final String? phone;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final String? preferredLanguage;
  final bool phoneVerified;
  final bool emailVerified;
  final String? dateJoined;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.firstName,
    this.lastName,
    required this.role,
    this.preferredLanguage,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      phone: json['phone'],
      fullName: json['full_name'] ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: UserRole.fromString(json['role'] ?? 'RESIDENT'),
      preferredLanguage: json['preferred_language'],
      phoneVerified: json['phone_verified'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      dateJoined: json['date_joined'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'first_name': firstName,
    'last_name': lastName,
    'role': role.value,
    'preferred_language': preferredLanguage,
    'phone_verified': phoneVerified,
    'email_verified': emailVerified,
    'date_joined': dateJoined,
  };
}

class AuthSession {
  final String access;
  final String refresh;
  final User user;

  AuthSession({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'access': access,
    'refresh': refresh,
    'user': user.toJson(),
  };
}

class WasteCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final bool isHazardous;
  final double defaultPricePerKg;
  final int baseEcoPoints;
  final bool isActive;

  WasteCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon,
    this.isHazardous = false,
    this.defaultPricePerKg = 0.0,
    this.baseEcoPoints = 10,
    this.isActive = true,
  });

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      isHazardous: json['is_hazardous'] ?? false,
      defaultPricePerKg: (json['default_price_per_kg'] != null)
          ? double.tryParse(json['default_price_per_kg'].toString()) ?? 0.0
          : 0.0,
      baseEcoPoints: json['base_eco_points'] is int
          ? json['base_eco_points']
          : int.tryParse(json['base_eco_points']?.toString() ?? '10') ?? 10,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'icon': icon,
    'is_hazardous': isHazardous,
    'default_price_per_kg': defaultPricePerKg,
    'base_eco_points': baseEcoPoints,
    'is_active': isActive,
  };
}

class WasteRequestPhoto {
  final String id;
  final String photo;
  final String? caption;
  final String? photoType;

  WasteRequestPhoto({
    required this.id,
    required this.photo,
    this.caption,
    this.photoType,
  });

  factory WasteRequestPhoto.fromJson(Map<String, dynamic> json) {
    return WasteRequestPhoto(
      id: json['id']?.toString() ?? '',
      photo: json['photo'] ?? '',
      caption: json['caption'],
      photoType: json['photo_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'photo': photo,
    'caption': caption,
    'photo_type': photoType,
  };
}

class WasteRequest {
  final String id;
  final String referenceId;
  final String pickupAddress;
  final double? latitude;
  final double? longitude;
  final double estimatedWeightKg;
  final double? actualWeightKg;
  final String status;
  final String? scheduledDate;
  final String? scheduledTimeSlot;
  final String? specialInstructions;
  final double estimatedPrice;
  final double paidAmount;
  final String paymentStatus;
  final int ecoPointsAwarded;
  final WasteCategory? categoryDetails;
  final List<WasteRequestPhoto> photos;
  final String? createdAt;
  final String? assignedCollectorName;

  WasteRequest({
    required this.id,
    required this.referenceId,
    required this.pickupAddress,
    this.latitude,
    this.longitude,
    this.estimatedWeightKg = 0.0,
    this.actualWeightKg,
    this.status = 'PENDING',
    this.scheduledDate,
    this.scheduledTimeSlot,
    this.specialInstructions,
    this.estimatedPrice = 0.0,
    this.paidAmount = 0.0,
    this.paymentStatus = 'UNPAID',
    this.ecoPointsAwarded = 0,
    this.categoryDetails,
    this.photos = const [],
    this.createdAt,
    this.assignedCollectorName,
  });

  factory WasteRequest.fromJson(Map<String, dynamic> json) {
    return WasteRequest(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      estimatedWeightKg: double.tryParse(json['estimated_weight_kg']?.toString() ?? '0') ?? 0.0,
      actualWeightKg: json['actual_weight_kg'] != null ? double.tryParse(json['actual_weight_kg'].toString()) : null,
      status: json['status'] ?? 'PENDING',
      scheduledDate: json['scheduled_date'],
      scheduledTimeSlot: json['scheduled_time_slot'],
      specialInstructions: json['special_instructions'],
      estimatedPrice: double.tryParse(json['estimated_price']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'UNPAID',
      ecoPointsAwarded: json['eco_points_awarded'] ?? 0,
      categoryDetails: json['category_details'] != null ? WasteCategory.fromJson(json['category_details']) : null,
      photos: (json['photos'] as List? ?? [])
          .map((p) => WasteRequestPhoto.fromJson(p))
          .toList(),
      createdAt: json['created_at'],
      assignedCollectorName: json['assigned_collector_details']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference_id': referenceId,
    'pickup_address': pickupAddress,
    'latitude': latitude,
    'longitude': longitude,
    'estimated_weight_kg': estimatedWeightKg,
    'actual_weight_kg': actualWeightKg,
    'status': status,
    'scheduled_date': scheduledDate,
    'scheduled_time_slot': scheduledTimeSlot,
    'special_instructions': specialInstructions,
    'estimated_price': estimatedPrice,
    'paid_amount': paidAmount,
    'payment_status': paymentStatus,
    'eco_points_awarded': ecoPointsAwarded,
    'category_details': categoryDetails?.toJson(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'created_at': createdAt,
  };
}

class Payment {
  final String id;
  final String referenceId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String phoneNumber;
  final String? transactionId;
  final String? createdAt;

  Payment({
    required this.id,
    required this.referenceId,
    required this.amount,
    this.currency = 'UGX',
    required this.method,
    required this.status,
    required this.phoneNumber,
    this.transactionId,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'UGX',
      method: json['method'] ?? 'MTN_MOMO',
      status: json['status'] ?? 'PENDING',
      phoneNumber: json['phone_number'] ?? '',
      transactionId: json['transaction_id'],
      createdAt: json['created_at'],
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class RewardStatus {
  final int balance;
  final String? tier;
  final String? badge;
  final String? nextTier;
  final double progressToNext;

  RewardStatus({
    required this.balance,
    this.tier,
    this.badge,
    this.nextTier,
    this.progressToNext = 0.0,
  });

  factory RewardStatus.fromJson(Map<String, dynamic> json) {
    return RewardStatus(
      balance: json['balance'] is int ? json['balance'] : int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      tier: json['tier'],
      badge: json['badge'],
      nextTier: json['next_tier'],
      progressToNext: double.tryParse(json['progress_to_next']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CollectorJob {
  final String id;
  final String reference;
  final String status;
  final String address;
  final String? category;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int? etaMinutes;

  CollectorJob({
    required this.id,
    required this.reference,
    required this.status,
    required this.address,
    this.category,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.etaMinutes,
  });

  factory CollectorJob.fromJson(Map<String, dynamic> json) {
    return CollectorJob(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? json['reference_id'] ?? '',
      status: json['status'] ?? 'ASSIGNED',
      address: json['address'] ?? json['pickup_address'] ?? '',
      category: json['category'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      etaMinutes: json['eta_minutes'] is int ? json['eta_minutes'] : int.tryParse(json['eta_minutes']?.toString() ?? ''),
    );
  }
}

class CollectorDashboardData {
  final int todayTotal;
  final int todayCompleted;
  final int todayPending;
  final bool activeShift;
  final double? totalWeightCollectedKg;
  final List<CollectorJob> jobs;

  CollectorDashboardData({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayPending,
    required this.activeShift,
    this.totalWeightCollectedKg,
    this.jobs = const [],
  });

  factory CollectorDashboardData.fromJson(Map<String, dynamic> json) {
    return CollectorDashboardData(
      todayTotal: json['today_total'] ?? 0,
      todayCompleted: json['today_completed'] ?? 0,
      todayPending: json['today_pending'] ?? 0,
      activeShift: json['active_shift'] ?? false,
      totalWeightCollectedKg: json['total_weight_collected_kg'] != null
          ? double.tryParse(json['total_weight_collected_kg'].toString())
          : null,
      jobs: (json['jobs'] as List? ?? []).map((j) => CollectorJob.fromJson(j)).toList(),
    );
  }
}

class IllegalDumpingReport {
  final String id;
  final String referenceId;
  final String address;
  final double? latitude;
  final double? longitude;
  final String description;
  final String severity;
  final String status;
  final List<Map<String, dynamic>> photos;
  final String? createdAt;

  IllegalDumpingReport({
    required this.id,
    required this.referenceId,
    required this.address,
    this.latitude,
    this.longitude,
    required this.description,
    this.severity = 'MEDIUM',
    this.status = 'PENDING',
    this.photos = const [],
    this.createdAt,
  });

  factory IllegalDumpingReport.fromJson(Map<String, dynamic> json) {
    return IllegalDumpingReport(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      status: json['status'] ?? 'PENDING',
      photos: (json['photos'] as List? ?? []).cast<Map<String, dynamic>>(),
      createdAt: json['created_at'],
    );
  }
}

class AdminDashboardData {
  final UserMetrics users;
  final WasteRequestMetrics wasteRequests;
  final CollectionMetrics collections;
  final ReportMetrics reports;
  final VerificationMetrics verifications;
  final FinancialMetrics financials;
  final RewardsMetrics rewards;
  final ZoneMetrics zones;
  final RecentActivity recentActivity;

  AdminDashboardData({
    required this.users,
    required this.wasteRequests,
    required this.collections,
    required this.reports,
    required this.verifications,
    required this.financials,
    required this.rewards,
    required this.zones,
    required this.recentActivity,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      users: UserMetrics.fromJson(json['users'] ?? {}),
      wasteRequests: WasteRequestMetrics.fromJson(json['waste_requests'] ?? {}),
      collections: CollectionMetrics.fromJson(json['collections'] ?? {}),
      reports: ReportMetrics.fromJson(json['reports'] ?? {}),
      verifications: VerificationMetrics.fromJson(json['verifications'] ?? {}),
      financials: FinancialMetrics.fromJson(json['financials'] ?? {}),
      rewards: RewardsMetrics.fromJson(json['rewards'] ?? {}),
      zones: ZoneMetrics.fromJson(json['zones'] ?? {}),
      recentActivity: RecentActivity.fromJson(json['recent_activity'] ?? {}),
    );
  }
}

class UserMetrics {
  final int total;
  final int active;
  final int verified;
  final Map<String, int> byRole;
  final int newThisWeek;

  UserMetrics({
    required this.total,
    required this.active,
    required this.verified,
    required this.byRole,
    required this.newThisWeek,
  });

  factory UserMetrics.fromJson(Map<String, dynamic> json) {
    return UserMetrics(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      verified: json['verified'] ?? 0,
      byRole: Map<String, int>.from(json['by_role'] ?? {}),
      newThisWeek: json['new_this_week'] ?? 0,
    );
  }
}

class WasteRequestMetrics {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final double totalWeightKg;
  final int newThisWeek;

  WasteRequestMetrics({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.totalWeightKg,
    required this.newThisWeek,
  });

  factory WasteRequestMetrics.fromJson(Map<String, dynamic> json) {
    return WasteRequestMetrics(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
      totalWeightKg: (json['total_weight_kg'] != null) ? double.tryParse(json['total_weight_kg'].toString()) ?? 0.0 : 0.0,
      newThisWeek: json['new_this_week'] ?? 0,
    );
  }
}

class CollectionMetrics {
  final int activeAssignments;
  final int completedAssignments;

  CollectionMetrics({
    required this.activeAssignments,
    required this.completedAssignments,
  });

  factory CollectionMetrics.fromJson(Map<String, dynamic> json) {
    return CollectionMetrics(
      activeAssignments: json['active_assignments'] ?? 0,
      completedAssignments: json['completed_assignments'] ?? 0,
    );
  }
}

class ReportMetrics {
  final int total;
  final int pending;
  final int resolved;
  final double resolutionRate;
  final int newThisWeek;

  ReportMetrics({
    required this.total,
    required this.pending,
    required this.resolved,
    required this.resolutionRate,
    required this.newThisWeek,
  });

  factory ReportMetrics.fromJson(Map<String, dynamic> json) {
    return ReportMetrics(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      resolved: json['resolved'] ?? 0,
      resolutionRate: (json['resolution_rate'] != null) ? double.tryParse(json['resolution_rate'].toString()) ?? 0.0 : 0.0,
      newThisWeek: json['new_this_week'] ?? 0,
    );
  }
}

class VerificationMetrics {
  final int pending;
  final int approved;
  final int rejected;

  VerificationMetrics({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory VerificationMetrics.fromJson(Map<String, dynamic> json) {
    return VerificationMetrics(
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }
}

class FinancialMetrics {
  final double totalRevenueUgx;
  final double totalPayoutsUgx;
  final double netMarginUgx;
  final int pendingPayouts;
  final String currency;

  FinancialMetrics({
    required this.totalRevenueUgx,
    required this.totalPayoutsUgx,
    required this.netMarginUgx,
    required this.pendingPayouts,
    required this.currency,
  });

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      totalRevenueUgx: (json['total_revenue_ugx'] != null) ? double.tryParse(json['total_revenue_ugx'].toString()) ?? 0.0 : 0.0,
      totalPayoutsUgx: (json['total_payouts_ugx'] != null) ? double.tryParse(json['total_payouts_ugx'].toString()) ?? 0.0 : 0.0,
      netMarginUgx: (json['net_margin_ugx'] != null) ? double.tryParse(json['net_margin_ugx'].toString()) ?? 0.0 : 0.0,
      pendingPayouts: json['pending_payouts'] ?? 0,
      currency: json['currency'] ?? 'UGX',
    );
  }
}

class RewardsMetrics {
  final int totalPointsAwarded;
  final int totalPointsRedeemed;

  RewardsMetrics({
    required this.totalPointsAwarded,
    required this.totalPointsRedeemed,
  });

  factory RewardsMetrics.fromJson(Map<String, dynamic> json) {
    return RewardsMetrics(
      totalPointsAwarded: json['total_points_awarded'] ?? 0,
      totalPointsRedeemed: json['total_points_redeemed'] ?? 0,
    );
  }
}

class ZoneMetrics {
  final int total;
  final int active;

  ZoneMetrics({
    required this.total,
    required this.active,
  });

  factory ZoneMetrics.fromJson(Map<String, dynamic> json) {
    return ZoneMetrics(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
    );
  }
}

class RecentActivity {
  final List<RecentUser> recentUsers;
  final List<PendingVerification> pendingVerifications;

  RecentActivity({
    required this.recentUsers,
    required this.pendingVerifications,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      recentUsers: (json['recent_users'] as List? ?? []).map((u) => RecentUser.fromJson(u)).toList(),
      pendingVerifications: (json['pending_verifications'] as List? ?? []).map((v) => PendingVerification.fromJson(v)).toList(),
    );
  }
}

class RecentUser {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String createdAt;

  RecentUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PendingVerification {
  final String id;
  final int collectorId;
  final String collectorEmail;
  final String collectorName;
  final String createdAt;

  PendingVerification({
    required this.id,
    required this.collectorId,
    required this.collectorEmail,
    required this.collectorName,
    required this.createdAt,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    return PendingVerification(
      id: json['id']?.toString() ?? '',
      collectorId: json['collector_id'] ?? 0,
      collectorEmail: json['collector_email'] ?? '',
      collectorName: json['collector_name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Zone {
  final String id;
  final String name;
  final String code;
  final String? region;
  final String? description;
  final bool isActive;

  Zone({
    required this.id,
    required this.name,
    required this.code,
    this.region,
    this.description,
    this.isActive = true,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      region: json['region'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class Profile {
  final String id;
  final UserRole role;
  final String? bio;
  final String? address;
  final double? latitude;
  final double? longitude;
  final Zone? zone;

  Profile({
    required this.id,
    required this.role,
    this.bio,
    this.address,
    this.latitude,
    this.longitude,
    this.zone,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final zoneJson = json['zone_details'] ?? json['zone'];
    return Profile(
      id: json['user']?.toString() ?? json['id']?.toString() ?? '',
      role: UserRole.fromString(json['role'] ?? 'RESIDENT'),
      bio: json['bio'],
      address: json['address'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      zone: zoneJson is Map
          ? Zone.fromJson(Map<String, dynamic>.from(zoneJson))
          : null,
    );
  }
}

class RecurringSchedule {
  final String id;
  final String category;
  final String? categoryName;
  final String frequency;
  final int? preferredWeekday;
  final String? preferredTime;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? zone;
  final bool isActive;
  final String? nextRun;
  final String? createdAt;

  RecurringSchedule({
    required this.id,
    required this.category,
    this.categoryName,
    required this.frequency,
    this.preferredWeekday,
    this.preferredTime,
    required this.address,
    this.latitude,
    this.longitude,
    this.zone,
    this.isActive = true,
    this.nextRun,
    this.createdAt,
  });

  factory RecurringSchedule.fromJson(Map<String, dynamic> json) {
    return RecurringSchedule(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      categoryName: json['category_details']?['name'] ?? json['category_name'],
      frequency: json['frequency'] ?? 'WEEKLY',
      preferredWeekday: json['preferred_weekday'],
      preferredTime: json['preferred_time'],
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      zone: json['zone']?.toString(),
      isActive: json['is_active'] ?? true,
      nextRun: json['next_run'],
      createdAt: json['created_at'],
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String paymentId;
  final double amount;
  final String currency;
  final bool isPaid;
  final List<dynamic> items;
  final String? issuedDate;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.paymentId,
    required this.amount,
    this.currency = 'UGX',
    this.isPaid = false,
    this.items = const [],
    this.issuedDate,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      paymentId: json['payment']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'UGX',
      isPaid: json['is_paid'] ?? false,
      items: json['items_json'] as List? ?? [],
      issuedDate: json['issued_date'],
    );
  }
}

class RatingReview {
  final String id;
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final int score;
  final String? review;
  final bool isPublic;
  final String? createdAt;

  RatingReview({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.score,
    this.review,
    this.isPublic = true,
    this.createdAt,
  });

  factory RatingReview.fromJson(Map<String, dynamic> json) {
    return RatingReview(
      id: json['id']?.toString() ?? '',
      fromUserId: int.tryParse(json['from_user']?.toString() ?? '0') ?? 0,
      fromUserName: json['from_user_details']?['full_name'] ?? '',
      toUserId: int.tryParse(json['to_user']?.toString() ?? '0') ?? 0,
      toUserName: json['to_user_details']?['full_name'] ?? '',
      score: json['score'] ?? 0,
      review: json['review'],
      isPublic: json['is_public'] ?? true,
      createdAt: json['created_at'],
    );
  }
}

class RatingSummary {
  final int userId;
  final double averageRating;
  final int totalReviews;
  final List<RatingReview> recentReviews;

  RatingSummary({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    this.recentReviews = const [],
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      recentReviews: (json['recent_reviews'] as List? ?? [])
          .map((r) => RatingReview.fromJson(r))
          .toList(),
    );
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    this.category = 'OTHER',
    this.priority = 'MEDIUM',
    this.status = 'OPEN',
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'OTHER',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messages: (json['messages'] as List? ?? [])
          .map((m) => TicketMessage.fromJson(m))
          .toList(),
    );
  }
}

class TicketMessage {
  final String id;
  final String content;
  final int senderId;
  final String senderName;
  final bool isInternal;
  final String? createdAt;

  TicketMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.isInternal = false,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id']?.toString() ?? '',
      content: json['message'] ?? '',
      senderId: int.tryParse(json['sender']?.toString() ?? '0') ?? 0,
      senderName: json['sender_details']?['full_name'] ?? 'Support Team',
      isInternal: json['is_internal'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class ChatConversation {
  final String id;
  final String wasteRequestId;
  final String referenceId;
  final String otherUserName;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.wasteRequestId,
    required this.referenceId,
    required this.otherUserName,
    this.messages = const [],
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final resident = json['resident_details'] as Map<String, dynamic>? ?? {};
    final collector = json['collector_details'] as Map<String, dynamic>? ?? {};
    final requestDetails = json['waste_request_details'] as Map<String, dynamic>? ?? {};
    final int residentId = int.tryParse(resident['id']?.toString() ?? '') ?? 0;
    final otherName = (currentUserId != null && currentUserId == residentId)
        ? (collector['full_name'] ?? 'Collector')
        : (resident['full_name'] ?? 'Resident');
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      wasteRequestId: json['waste_request']?.toString() ?? '',
      referenceId: requestDetails['reference_id'] ?? '',
      otherUserName: otherName,
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }
}

class ChatMessage {
  final String id;
  final int senderId;
  final String senderName;
  final String content;
  final bool isRead;
  final String? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.isRead = false,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: int.tryParse(json['sender']?.toString() ?? '0') ?? 0,
      senderName: json['sender_details']?['full_name'] ?? '',
      content: json['content'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class LiveLocation {
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final int? etaMinutes;
  final String? status;
  final String? lastUpdated;

  LiveLocation({
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.etaMinutes,
    this.status,
    this.lastUpdated,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    final loc = json['collector_location'] is Map
        ? json['collector_location'] as Map<String, dynamic>
        : json;
    return LiveLocation(
      latitude: double.tryParse(loc['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(loc['longitude']?.toString() ?? '0') ?? 0.0,
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      etaMinutes: json['eta_minutes'] is int ? json['eta_minutes'] : int.tryParse(json['eta_minutes']?.toString() ?? ''),
      status: json['status'],
      lastUpdated: json['last_updated'],
    );
  }
}

class AnalyticsOverview {
  final int totalUsers;
  final int residents;
  final int collectors;
  final int recyclers;
  final int totalRequests;
  final int completedRequests;
  final int pendingRequests;
  final double totalWeightKg;
  final int reportsTotal;
  final int reportsResolved;
  final double reportsResolutionRate;
  final int totalPointsAwarded;

  AnalyticsOverview({
    required this.totalUsers,
    required this.residents,
    required this.collectors,
    required this.recyclers,
    required this.totalRequests,
    required this.completedRequests,
    required this.pendingRequests,
    required this.totalWeightKg,
    required this.reportsTotal,
    required this.reportsResolved,
    required this.reportsResolutionRate,
    required this.totalPointsAwarded,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final users = json['users'] ?? {};
    final collections = json['collections'] ?? {};
    final env = json['environmental_reports'] ?? {};
    return AnalyticsOverview(
      totalUsers: users['total'] ?? 0,
      residents: users['residents'] ?? 0,
      collectors: users['collectors'] ?? 0,
      recyclers: users['recyclers'] ?? 0,
      totalRequests: collections['total_requests'] ?? 0,
      completedRequests: collections['completed'] ?? 0,
      pendingRequests: collections['pending'] ?? 0,
      totalWeightKg: double.tryParse(collections['total_weight_kg']?.toString() ?? '0') ?? 0.0,
      reportsTotal: env['total'] ?? 0,
      reportsResolved: env['resolved'] ?? 0,
      reportsResolutionRate: double.tryParse(env['resolution_rate']?.toString() ?? '0') ?? 0.0,
      totalPointsAwarded: json['rewards']?['total_points_distributed'] ?? 0,
    );
  }
}

class AnalyticsFinancials {
  final double grossRevenueUgx;
  final double totalPayoutsUgx;
  final double netMarginUgx;
  final Map<String, dynamic> paymentMethods;

  AnalyticsFinancials({
    required this.grossRevenueUgx,
    required this.totalPayoutsUgx,
    required this.netMarginUgx,
    this.paymentMethods = const {},
  });

  factory AnalyticsFinancials.fromJson(Map<String, dynamic> json) {
    return AnalyticsFinancials(
      grossRevenueUgx: double.tryParse(json['gross_revenue_ugx']?.toString() ?? '0') ?? 0.0,
      totalPayoutsUgx: double.tryParse(json['total_collector_payouts_ugx']?.toString() ?? '0') ?? 0.0,
      netMarginUgx: double.tryParse(json['net_margin_ugx']?.toString() ?? '0') ?? 0.0,
      paymentMethods: Map<String, dynamic>.from(json['payment_methods_breakdown'] ?? {}),
    );
  }
}

class AnalyticsHotspot {
  final String zoneId;
  final String zoneName;
  final String zoneCode;
  final int illegalDumpingTotal;
  final int illegalDumpingOpen;
  final int totalWasteRequests;
  final double severityScore;

  AnalyticsHotspot({
    required this.zoneId,
    required this.zoneName,
    required this.zoneCode,
    required this.illegalDumpingTotal,
    required this.illegalDumpingOpen,
    required this.totalWasteRequests,
    required this.severityScore,
  });

  factory AnalyticsHotspot.fromJson(Map<String, dynamic> json) {
    return AnalyticsHotspot(
      zoneId: json['zone_id']?.toString() ?? '',
      zoneName: json['zone_name'] ?? '',
      zoneCode: json['zone_code'] ?? '',
      illegalDumpingTotal: json['illegal_dumping_total'] ?? 0,
      illegalDumpingOpen: json['illegal_dumping_open'] ?? 0,
      totalWasteRequests: json['total_waste_requests'] ?? 0,
      severityScore: double.tryParse(json['severity_score']?.toString() ?? '0') ?? 0.0,
    );
  }
}
