import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipTier {
  free,
  basic,
  premium,
  ultimate,
}

enum MembershipStatus {
  active,
  expired,
  cancelled,
  trial,
}

class MembershipDetails {
  final MembershipTier tier;
  final MembershipStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool autoRenewal;
  final Map<String, dynamic> benefits;
  final List<String> unlockedItems;
  final int monthlySkinsClaimedThisMonth;
  final DateTime? lastSkinClaimDate;
  final Map<String, dynamic> metadata;

  const MembershipDetails({
    this.tier = MembershipTier.free,
    this.status = MembershipStatus.active,
    this.startDate,
    this.endDate,
    this.trialEndDate,
    this.autoRenewal = false,
    this.benefits = const {},
    this.unlockedItems = const [],
    this.monthlySkinsClaimedThisMonth = 0,
    this.lastSkinClaimDate,
    this.metadata = const {},
  });

  // Helper getters
  bool get isActive => status == MembershipStatus.active && 
      (endDate == null || endDate!.isAfter(DateTime.now()));
  
  bool get isTrial => status == MembershipStatus.trial && 
      (trialEndDate == null || trialEndDate!.isAfter(DateTime.now()));
  
  bool get isPremium => tier != MembershipTier.free && (isActive || isTrial);
  
  bool get canClaimMonthlySkins {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final maxSkins = getMembershipBenefits(tier)['monthlyFreeSkins'] as int? ?? 0;
    
    // Reset counter if it's a new month
    if (lastSkinClaimDate == null || 
        '${lastSkinClaimDate!.year}-${lastSkinClaimDate!.month.toString().padLeft(2, '0')}' != currentMonth) {
      return maxSkins > 0;
    }
    
    return monthlySkinsClaimedThisMonth < maxSkins;
  }

  int get remainingMonthlySkins {
    final maxSkins = getMembershipBenefits(tier)['monthlyFreeSkins'] as int? ?? 0;
    return maxSkins - monthlySkinsClaimedThisMonth;
  }

  DateTime? get nextSkinDropDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1); // First day of next month
  }

  int get daysUntilNextDrop {
    final next = nextSkinDropDate;
    if (next == null) return 0;
    return next.difference(DateTime.now()).inDays;
  }

  factory MembershipDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipDetails.fromJson(data);
  }

  factory MembershipDetails.fromJson(Map<String, dynamic> json) {
    return MembershipDetails(
      tier: MembershipTier.values.firstWhere(
        (e) => e.toString().split('.').last == json['tier'],
        orElse: () => MembershipTier.free,
      ),
      status: MembershipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MembershipStatus.active,
      ),
      startDate: json['startDate'] != null
          ? (json['startDate'] as Timestamp).toDate()
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? (json['trialEndDate'] as Timestamp).toDate()
          : null,
      autoRenewal: json['autoRenewal'] as bool? ?? false,
      benefits: Map<String, dynamic>.from(json['benefits'] ?? {}),
      unlockedItems: List<String>.from(json['unlockedItems'] ?? []),
      monthlySkinsClaimedThisMonth: json['monthlySkinsClaimedThisMonth'] as int? ?? 0,
      lastSkinClaimDate: json['lastSkinClaimDate'] != null
          ? (json['lastSkinClaimDate'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'trialEndDate': trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'autoRenewal': autoRenewal,
      'benefits': benefits,
      'unlockedItems': unlockedItems,
      'monthlySkinsClaimedThisMonth': monthlySkinsClaimedThisMonth,
      'lastSkinClaimDate': lastSkinClaimDate != null 
          ? Timestamp.fromDate(lastSkinClaimDate!) : null,
      'metadata': metadata,
    };
  }

  MembershipDetails copyWith({
    MembershipTier? tier,
    MembershipStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    bool? autoRenewal,
    Map<String, dynamic>? benefits,
    List<String>? unlockedItems,
    int? monthlySkinsClaimedThisMonth,
    DateTime? lastSkinClaimDate,
    Map<String, dynamic>? metadata,
  }) {
    return MembershipDetails(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      benefits: benefits ?? this.benefits,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      monthlySkinsClaimedThisMonth: monthlySkinsClaimedThisMonth ?? this.monthlySkinsClaimedThisMonth,
      lastSkinClaimDate: lastSkinClaimDate ?? this.lastSkinClaimDate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'MembershipDetails(tier: $tier, status: $status)';
}

// Membership benefits configuration
Map<String, dynamic> getMembershipBenefits(MembershipTier tier) {
  const benefits = {
    MembershipTier.free: {
      'monthlyFreeSkins': 0,
      'coinBonusMultiplier': 1.0,
      'earlyAccess': false,
      'exclusiveContent': false,
      'prioritySupport': false,
      'adFree': false,
    },
    MembershipTier.basic: {
      'monthlyFreeSkins': 1,
      'coinBonusMultiplier': 1.25,
      'earlyAccess': true,
      'exclusiveContent': false,
      'prioritySupport': false,
      'adFree': true,
    },
    MembershipTier.premium: {
      'monthlyFreeSkins': 2,
      'coinBonusMultiplier': 1.5,
      'earlyAccess': true,
      'exclusiveContent': true,
      'prioritySupport': true,
      'adFree': true,
    },
    MembershipTier.ultimate: {
      'monthlyFreeSkins': 4,
      'coinBonusMultiplier': 2.0,
      'earlyAccess': true,
      'exclusiveContent': true,
      'prioritySupport': true,
      'adFree': true,
      'unlimitedStorage': true,
      'personalCoach': true,
    },
  };

  return benefits[tier] ?? benefits[MembershipTier.free]!;
}

// Membership pricing (in local currency or subscription platform IDs)
class MembershipPricing {
  final MembershipTier tier;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final String subscriptionId;
  final Map<String, String> localizedPrices;

  const MembershipPricing({
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.subscriptionId,
    this.localizedPrices = const {},
  });

  double get yearlyDiscount => (monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12);
  String get discountPercentage => '${(yearlyDiscount * 100).toInt()}%';
}

// Predefined pricing
const membershipPricing = {
  MembershipTier.basic: MembershipPricing(
    tier: MembershipTier.basic,
    monthlyPrice: 4.99,
    yearlyPrice: 49.99,
    currency: 'USD',
    subscriptionId: 'fit_basic_monthly',
  ),
  MembershipTier.premium: MembershipPricing(
    tier: MembershipTier.premium,
    monthlyPrice: 9.99,
    yearlyPrice: 99.99,
    currency: 'USD',
    subscriptionId: 'fit_premium_monthly',
  ),
  MembershipTier.ultimate: MembershipPricing(
    tier: MembershipTier.ultimate,
    monthlyPrice: 19.99,
    yearlyPrice: 199.99,
    currency: 'USD',
    subscriptionId: 'fit_ultimate_monthly',
  ),
};