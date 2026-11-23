/// Structured model representing external doorstep scrap collection, kabadiwala apps,
/// and digital waste-commerce platforms.
class KabadiwalaServiceModel {
  final String id;
  final String name;
  final String serviceType;
  final String description;
  final List<String> acceptedMaterials;
  final List<String> rejectedMaterials;
  final String geographicCoverage;
  final bool operatesInBengaluru;
  final String? coverageNotes;
  final String? operatingHours;
  final String? websiteUrl;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String? bookingUrl;
  final bool isVerified;
  final double rating;
  final String sourceReference;
  final List<String> pickupInstructions;

  const KabadiwalaServiceModel({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.description,
    this.acceptedMaterials = const [],
    this.rejectedMaterials = const [],
    required this.geographicCoverage,
    required this.operatesInBengaluru,
    this.coverageNotes,
    this.operatingHours,
    this.websiteUrl,
    this.playStoreUrl,
    this.appStoreUrl,
    this.bookingUrl,
    this.isVerified = true,
    this.rating = 4.5,
    required this.sourceReference,
    this.pickupInstructions = const [],
  });

  bool get hasPlayStore => playStoreUrl != null && playStoreUrl!.isNotEmpty;
  bool get hasAppStore => appStoreUrl != null && appStoreUrl!.isNotEmpty;
  bool get hasWebsite => websiteUrl != null && websiteUrl!.isNotEmpty;
  bool get hasBooking => bookingUrl != null && bookingUrl!.isNotEmpty;

  /// Helper to check symmetric token matching between waste descriptor and service rules
  static bool _matchesMaterialToken(String target, String rule) {
    final t = target.toLowerCase().trim();
    final r = rule.toLowerCase().trim();
    if (t.isEmpty || r.isEmpty) return false;
    if (t == r) return true;
    if (t.contains(r) || r.contains(t)) return true;

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
      'plastic',
      'paper',
      'cardboard',
      'metal',
      'metals',
      'iron',
      'steel',
      'aluminium',
      'copper',
      'brass',
      'ewaste',
      'e-waste',
      'electronic',
      'electronics',
      'battery',
      'batteries',
      'glass',
      'textile',
      'textiles',
      'fabric',
      'clothes',
      'composite',
      'tetra',
      'carton',
      'multilayer',
      'multi-layer',
      'medical',
      'sanitary',
      'furniture',
      'bulky',
      'construction',
      'debris',
    };
    if (intersection.any((token) => keyMaterialTokens.contains(token))) {
      return true;
    }
    return false;
  }

  /// Evaluates whether this service accepts a specific material and sub-type.
  /// Rejection rules strictly take precedence over acceptance rules.
  bool acceptsMaterial(String materialName, [String? subType]) {
    final mat = materialName.trim();
    final sub = subType?.trim() ?? '';

    // 1. Strict rejection check
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

  /// Search keyword matching across name, serviceType, description, coverage, and accepted materials
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();

    if (name.toLowerCase().contains(q)) return true;
    if (serviceType.toLowerCase().contains(q)) return true;
    if (description.toLowerCase().contains(q)) return true;
    if (geographicCoverage.toLowerCase().contains(q)) return true;
    if (coverageNotes != null && coverageNotes!.toLowerCase().contains(q)) return true;
    if (acceptedMaterials.any((m) => m.toLowerCase().contains(q))) return true;

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serviceType': serviceType,
      'description': description,
      'acceptedMaterials': acceptedMaterials,
      'rejectedMaterials': rejectedMaterials,
      'geographicCoverage': geographicCoverage,
      'operatesInBengaluru': operatesInBengaluru,
      'coverageNotes': coverageNotes,
      'operatingHours': operatingHours,
      'websiteUrl': websiteUrl,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'bookingUrl': bookingUrl,
      'isVerified': isVerified,
      'rating': rating,
      'sourceReference': sourceReference,
      'pickupInstructions': pickupInstructions,
    };
  }

  factory KabadiwalaServiceModel.fromJson(Map<String, dynamic> json) {
    return KabadiwalaServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceType: json['serviceType'] as String,
      description: json['description'] as String,
      acceptedMaterials: List<String>.from(json['acceptedMaterials'] as List? ?? []),
      rejectedMaterials: List<String>.from(json['rejectedMaterials'] as List? ?? []),
      geographicCoverage: json['geographicCoverage'] as String,
      operatesInBengaluru: json['operatesInBengaluru'] as bool? ?? true,
      coverageNotes: json['coverageNotes'] as String?,
      operatingHours: json['operatingHours'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      playStoreUrl: json['playStoreUrl'] as String?,
      appStoreUrl: json['appStoreUrl'] as String?,
      bookingUrl: json['bookingUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      sourceReference: json['sourceReference'] as String? ?? 'Verified Service Registry',
      pickupInstructions: List<String>.from(json['pickupInstructions'] as List? ?? []),
    );
  }
}
