import 'package:flutter/material.dart';

/// Supported types of waste-handling facilities
enum FacilityType {
  recyclingCentre,
  eWasteCollection,
  scrapDealer,
  donationCentre,
  compostingFacility,
  hazardousWaste,
  governmentAuthority,
}

extension FacilityTypeExt on FacilityType {
  String get label {
    switch (this) {
      case FacilityType.recyclingCentre:
        return 'Recycling Centre';
      case FacilityType.eWasteCollection:
        return 'E-Waste Collection Point';
      case FacilityType.scrapDealer:
        return 'Authorized Scrap Dealer';
      case FacilityType.donationCentre:
        return 'Donation / Reuse Hub';
      case FacilityType.compostingFacility:
        return 'Composting / Biomass Facility';
      case FacilityType.hazardousWaste:
        return 'Hazardous Waste Collection Depot';
      case FacilityType.governmentAuthority:
        return 'Government Waste-Management Authority';
    }
  }

  IconData get icon {
    switch (this) {
      case FacilityType.recyclingCentre:
        return Icons.recycling;
      case FacilityType.eWasteCollection:
        return Icons.electrical_services;
      case FacilityType.scrapDealer:
        return Icons.scale;
      case FacilityType.donationCentre:
        return Icons.volunteer_activism;
      case FacilityType.compostingFacility:
        return Icons.park;
      case FacilityType.hazardousWaste:
        return Icons.warning_amber;
      case FacilityType.governmentAuthority:
        return Icons.account_balance;
    }
  }

  Color get color {
    switch (this) {
      case FacilityType.recyclingCentre:
        return const Color(0xFF1E7E34);
      case FacilityType.eWasteCollection:
        return const Color(0xFF1565C0);
      case FacilityType.scrapDealer:
        return const Color(0xFF5D4037);
      case FacilityType.donationCentre:
        return const Color(0xFF6A1B9A);
      case FacilityType.compostingFacility:
        return const Color(0xFF558B2F);
      case FacilityType.hazardousWaste:
        return const Color(0xFFD32F2F);
      case FacilityType.governmentAuthority:
        return const Color(0xFF1565C0);
    }
  }
}

/// Structured facility model representing recycling centres, scrap aggregators, and drop-off points
class RecyclingFacilityModel {
  final String id;
  final String name;
  final FacilityType facilityType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String? operatingHours;
  final List<String> acceptedMaterials;
  final List<String> rejectedMaterials;
  final List<String> dropOffInstructions;
  final bool isVerified;
  final bool isSampleData;
  final String? sourceReference;
  final double? rating;
  final bool isDoorstepPlatform;
  final String? bookingUrl;
  final String? portalUrl;
  final String? coverageArea;

  const RecyclingFacilityModel({
    required this.id,
    required this.name,
    required this.facilityType,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.operatingHours,
    this.acceptedMaterials = const [],
    this.rejectedMaterials = const [],
    this.dropOffInstructions = const [],
    this.isVerified = false,
    this.isSampleData = false,
    this.sourceReference,
    this.rating,
    this.isDoorstepPlatform = false,
    this.bookingUrl,
    this.portalUrl,
    this.coverageArea,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasContact => (phone != null && phone!.isNotEmpty) || (email != null && email!.isNotEmpty);

  /// Helper to check symmetric token matching between waste descriptor and facility rule
  static bool _matchesMaterialToken(String target, String rule) {
    final t = target.toLowerCase().trim();
    final r = rule.toLowerCase().trim();
    if (t.isEmpty || r.isEmpty) return false;
    if (t == r) return true;
    if (t.contains(r) || r.contains(t)) return true;

    // Tokenized keyword matching for abbreviations (e.g. 'pvc', 'pet', 'hdpe', 'li-ion')
    final tTokens = t.split(RegExp(r'[^a-zA-Z0-9]+')).where((s) => s.isNotEmpty).toSet();
    final rTokens = r.split(RegExp(r'[^a-zA-Z0-9]+')).where((s) => s.isNotEmpty).toSet();
    final intersection = tTokens.intersection(rTokens);
    const keyMaterialTokens = {
      'pvc',
      'pet',
      'hdpe',
      'ldpe',
      'pp',
      'ps',
      'pla',
      'tetra',
      'carton',
      'lithium',
      'battery',
      'lead',
      'mercury',
      'cadmium',
      'biohazard',
      'chemical',
      'cotton',
      'textile',
      'fabric',
      'composite',
      'medical',
      'sanitary',
      'biomedical',
      'furniture',
      'bulky',
      'construction',
      'debris',
      'rubble',
    };
    if (intersection.any((token) => keyMaterialTokens.contains(token))) {
      return true;
    }
    return false;
  }

  /// Evaluates whether this facility accepts a specific material and sub-type.
  /// Rejection rules strictly take precedence over acceptance rules.
  bool acceptsMaterial(String materialName, [String? subType]) {
    final mat = materialName.trim();
    final sub = subType?.trim() ?? '';

    // 1. Strict rejection check: Rejected materials strictly override accepted materials
    final isExplicitlyRejected = rejectedMaterials.any((r) {
      return _matchesMaterialToken(mat, r) || (sub.isNotEmpty && _matchesMaterialToken(sub, r));
    });

    if (isExplicitlyRejected) {
      return false;
    }

    // 2. Acceptance check
    return acceptedMaterials.any((a) {
      return _matchesMaterialToken(mat, a) || (sub.isNotEmpty && _matchesMaterialToken(sub, a));
    });
  }

  /// Search keyword matching across name, address, category and materials
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();

    if (name.toLowerCase().contains(q)) return true;
    if (facilityType.label.toLowerCase().contains(q)) return true;
    if (address != null && address!.toLowerCase().contains(q)) return true;
    if (acceptedMaterials.any((m) => m.toLowerCase().contains(q))) return true;

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'facilityType': facilityType.name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'operatingHours': operatingHours,
      'acceptedMaterials': acceptedMaterials,
      'rejectedMaterials': rejectedMaterials,
      'dropOffInstructions': dropOffInstructions,
      'isVerified': isVerified,
      'isSampleData': isSampleData,
      'sourceReference': sourceReference,
      'rating': rating,
      'isDoorstepPlatform': isDoorstepPlatform,
      'bookingUrl': bookingUrl,
      'portalUrl': portalUrl,
      'coverageArea': coverageArea,
    };
  }

  factory RecyclingFacilityModel.fromJson(Map<String, dynamic> json) {
    return RecyclingFacilityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      facilityType: FacilityType.values.firstWhere(
        (e) => e.name == json['facilityType'],
        orElse: () => FacilityType.recyclingCentre,
      ),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      operatingHours: json['operatingHours'] as String?,
      acceptedMaterials: List<String>.from(json['acceptedMaterials'] as List? ?? []),
      rejectedMaterials: List<String>.from(json['rejectedMaterials'] as List? ?? []),
      dropOffInstructions: List<String>.from(json['dropOffInstructions'] as List? ?? []),
      isVerified: json['isVerified'] as bool? ?? false,
      isSampleData: json['isSampleData'] as bool? ?? false,
      sourceReference: json['sourceReference'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isDoorstepPlatform: json['isDoorstepPlatform'] as bool? ?? false,
      bookingUrl: json['bookingUrl'] as String?,
      portalUrl: json['portalUrl'] as String?,
      coverageArea: json['coverageArea'] as String?,
    );
  }
}
