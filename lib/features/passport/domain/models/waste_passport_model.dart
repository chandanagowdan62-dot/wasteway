import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Recyclability rating according to global circular economy standards
enum RecyclabilityGrade { A, B, C, D, E }

extension RecyclabilityGradeExt on RecyclabilityGrade {
  String get label {
    switch (this) {
      case RecyclabilityGrade.A:
        return 'Grade A - Highly Recyclable';
      case RecyclabilityGrade.B:
        return 'Grade B - Widely Recycled';
      case RecyclabilityGrade.C:
        return 'Grade C - Moderately Recyclable';
      case RecyclabilityGrade.D:
        return 'Grade D - Low Recyclability';
      case RecyclabilityGrade.E:
        return 'Grade E - Non-Recyclable / Hazardous';
    }
  }

  String get shortDescription {
    switch (this) {
      case RecyclabilityGrade.A:
        return 'High commercial recovery demand; readily reprocessed into new products.';
      case RecyclabilityGrade.B:
        return 'Standard municipal recycling streams accept this material with minimal sorting.';
      case RecyclabilityGrade.C:
        return 'Recyclable only at specialized facilities; requires clean segregation.';
      case RecyclabilityGrade.D:
        return 'Difficult to mechanically reprocess; downcycled or energy-recovered.';
      case RecyclabilityGrade.E:
        return 'Toxic or non-recyclable. Requires hazardous containment or manufacturer take-back.';
    }
  }

  Color get color {
    switch (this) {
      case RecyclabilityGrade.A:
        return AppColors.gradeA;
      case RecyclabilityGrade.B:
        return AppColors.gradeB;
      case RecyclabilityGrade.C:
        return AppColors.gradeC;
      case RecyclabilityGrade.D:
        return AppColors.gradeD;
      case RecyclabilityGrade.E:
        return AppColors.gradeE;
    }
  }
}

/// Digital Waste Passport data model
class WastePassportModel {
  final String id;
  final String itemName;
  final String primaryMaterial;
  final String subType;
  final double confidenceScore;
  final RecyclabilityGrade recyclabilityGrade;
  final String degradationTime;
  final String estimatedCarbonKg;
  final Map<String, int> materialComposition; // e.g. {'PET Body': 85, 'PP Cap': 15}
  final List<String> handlingInstructions;
  final Map<String, String> circularityGuidance; // 7-Rs: reuse, repair, recycle, donate, return, compost, safe_disposal
  final DateTime createdAt;
  final String? imagePath;
  final bool isSimulated;
  final String? simulationNotice;
  final bool isAmbiguous;
  final String? ambiguityReason;
  final List<String> alternativeMaterials;
  final bool isMixedWaste;
  final List<String> detectedItems;
  final String? segregationAdvice;
  final String? visualEvidence;

  const WastePassportModel({
    required this.id,
    required this.itemName,
    required this.primaryMaterial,
    required this.subType,
    required this.confidenceScore,
    required this.recyclabilityGrade,
    required this.degradationTime,
    required this.estimatedCarbonKg,
    required this.materialComposition,
    required this.handlingInstructions,
    required this.circularityGuidance,
    required this.createdAt,
    this.imagePath,
    this.isSimulated = false,
    this.simulationNotice,
    this.isAmbiguous = false,
    this.ambiguityReason,
    this.alternativeMaterials = const [],
    this.isMixedWaste = false,
    this.detectedItems = const [],
    this.segregationAdvice,
    this.visualEvidence,
  });

  /// Identifies whether the item contains hazardous or toxic elements
  bool get isHazardous {
    final lowerMaterial = primaryMaterial.toLowerCase();
    final lowerSub = subType.toLowerCase();
    final lowerName = itemName.toLowerCase();

    // Check for explicit hazardous materials first
    final hasHazardToken = lowerMaterial.contains('hazardous') ||
        lowerMaterial.contains('chemical') ||
        lowerMaterial.contains('e-waste') ||
        lowerMaterial.contains('medical') ||
        lowerMaterial.contains('sanitary') ||
        lowerSub.contains('battery') ||
        lowerSub.contains('lithium') ||
        lowerSub.contains('mercury') ||
        lowerSub.contains('lead') ||
        lowerSub.contains('cadmium') ||
        lowerSub.contains('biohazard') ||
        lowerSub.contains('syringe') ||
        lowerName.contains('battery') ||
        lowerName.contains('lithium');

    if (hasHazardToken) {
      return true;
    }

    // Explicit non-hazardous materials override
    if (lowerMaterial.contains('tissue') ||
        lowerSub.contains('tissue') ||
        lowerMaterial.contains('paper') ||
        lowerMaterial.contains('cardboard') ||
        lowerMaterial.contains('plastic') ||
        lowerMaterial.contains('metal') ||
        lowerMaterial.contains('glass') ||
        lowerMaterial.contains('textile') ||
        lowerMaterial.contains('organic') ||
        lowerMaterial.contains('food') ||
        lowerMaterial.contains('composite') ||
        lowerMaterial.contains('multi-layer') ||
        lowerMaterial.contains('furniture') ||
        lowerMaterial.contains('construction')) {
      return false;
    }

    return recyclabilityGrade == RecyclabilityGrade.E;
  }

  /// Simple household English explanation of environmental impact
  String get simpleEnvironmentalRelevance {
    final lowerMat = primaryMaterial.toLowerCase();
    final lowerSub = subType.toLowerCase();

    if (lowerSub.contains('tissue') || lowerMat.contains('tissue')) {
      return 'Used tissues and napkins decompose naturally in 2 to 4 weeks. If clean or used for food, they can be composted. If used for personal hygiene, place them in regular household trash to prevent sanitary contamination.';
    }
    if (lowerMat.contains('multi-layer') || lowerSub.contains('chips') || lowerSub.contains('snack') || lowerSub.contains('wrapper')) {
      return 'Multi-layer snack packets take many years to break down because plastic and metal foil are pressed together. Keep them dry and hand them over to scrap collectors or municipal recovery centres for energy recovery.';
    }
    if (lowerSub.contains('battery') || lowerMat.contains('battery') || lowerMat.contains('hazardous')) {
      return 'Batteries contain heavy metals and acids. When left in normal trash, they can cause fires or contaminate groundwater. Always deposit them at an authorized e-waste drop-off box.';
    }
    if (lowerMat.contains('medical') || lowerMat.contains('sanitary')) {
      return 'Medical and sanitary waste carries potential biological or pharmaceutical hazards. Never mix with household dry recyclables or garden compost. Secure in leak-proof bags for municipal sanitary collection or hospital drop-off.';
    }
    if (lowerMat.contains('furniture') || lowerMat.contains('bulky')) {
      return 'Bulky household goods and furniture consume substantial landfill volume. Repair loose joints, donate usable furniture to charity drives, or dismantle clean wood and metal scraps for recycling.';
    }
    if (lowerMat.contains('construction') || lowerMat.contains('demolition') || lowerSub.contains('debris')) {
      return 'Construction debris can be crushed and reclaimed into recycled aggregates for road sub-bases. Segregate rubble and haul to an authorized municipal C&D processing yard.';
    }
    if (lowerMat.contains('plastic') || lowerSub.contains('bottle') || lowerSub.contains('pet')) {
      return 'Plastic bottles take decades to break down in nature. Empty, rinse, and crush them before placing them in the dry recycling bin so they can be melted into new clean containers.';
    }
    if (lowerMat.contains('paper') || lowerMat.contains('cardboard')) {
      return 'Clean paper and cardboard are easily recycled into fresh paper or packaging. Flatten boxes to save bin space and keep them away from liquids to preserve fiber quality.';
    }
    if (lowerMat.contains('glass')) {
      return 'Glass can be melted and remolded endlessly without losing strength. Rinse clean and avoid breaking bottles to keep waste handlers safe.';
    }
    if (lowerMat.contains('metal') || lowerMat.contains('can')) {
      return 'Metal cans are infinitely recyclable and save over 90% of the energy needed to make new metal from ore. Rinse and drop into dry recyclables.';
    }
    if (lowerMat.contains('textile') || lowerMat.contains('fabric') || lowerMat.contains('cloth')) {
      return 'Textiles use massive amounts of water and dyes to manufacture. Usable clothes should be donated; damaged scraps can be given to textile recyclers for insulation or wiping cloths.';
    }
    if (lowerMat.contains('food') || lowerMat.contains('organic')) {
      return 'Organic food scraps turn into rich soil nutrients when composted. Keep them separate from plastic and dry waste to prevent foul odors and landfill gas.';
    }
    return 'Segregating this item properly keeps it out of landfills and helps local waste workers recover valuable materials.';
  }

  /// Recommended municipal receptacle stream
  String get recommendedBinStream {
    final lower = primaryMaterial.toLowerCase();
    if (lower.contains('medical') || lower.contains('sanitary')) {
      return 'Yellow/Red Hazardous Biomedical & Sanitary Stream';
    }
    if (lower.contains('furniture') || lower.contains('bulky')) {
      return 'Designated Bulky Goods & Furniture Drop-Off Stream';
    }
    if (lower.contains('construction') || lower.contains('demolition')) {
      return 'Designated C&D Debris Processing Stream';
    }
    if (lower.contains('textile') || lower.contains('fabric') || lower.contains('clothing')) {
      return 'Yellow Segregated Textile / Donation Stream';
    }
    if (lower.contains('multi-layer') || lower.contains('composite') || lower.contains('tetra')) {
      return 'Orange Multi-Layer / Special Recovery Stream';
    }
    if (lower.contains('organic') || lower.contains('biodegradable') || lower.contains('food')) {
      return 'Green Wet-Waste Bin (Compost)';
    }
    if (isHazardous) {
      return 'Red Hazardous / Special E-Waste Bin';
    }
    return 'Blue Dry-Waste Bin (Recyclables)';
  }

  /// Color associated with recommended municipal receptacle
  Color get binColor {
    final lower = primaryMaterial.toLowerCase();
    if (lower.contains('medical') || lower.contains('sanitary')) {
      return const Color(0xFFD32F2F); // Deep Red / Biomedical
    }
    if (lower.contains('furniture') || lower.contains('bulky')) {
      return const Color(0xFF6A1B9A); // Purple / Bulky
    }
    if (lower.contains('construction') || lower.contains('demolition')) {
      return const Color(0xFF607D8B); // Blue Grey / Mineral
    }
    if (lower.contains('textile') || lower.contains('fabric') || lower.contains('clothing')) {
      return const Color(0xFFF57F17); // Amber / Yellow
    }
    if (lower.contains('multi-layer') || lower.contains('composite') || lower.contains('tetra')) {
      return const Color(0xFFE65100); // Deep Orange
    }
    if (lower.contains('organic') || lower.contains('biodegradable') || lower.contains('food')) {
      return const Color(0xFF2E7D32); // Green
    }
    if (isHazardous) {
      return AppColors.alertRed; // Red
    }
    return const Color(0xFF1976D2); // Blue
  }

  /// Verifiable digital passport signature string
  String get passportSignature => 'WASTEWAY:$id:$primaryMaterial:${recyclabilityGrade.name}';

  WastePassportModel copyWith({
    String? id,
    String? itemName,
    String? primaryMaterial,
    String? subType,
    double? confidenceScore,
    RecyclabilityGrade? recyclabilityGrade,
    String? degradationTime,
    String? estimatedCarbonKg,
    Map<String, int>? materialComposition,
    List<String>? handlingInstructions,
    Map<String, String>? circularityGuidance,
    DateTime? createdAt,
    String? imagePath,
    bool? isSimulated,
    String? simulationNotice,
    bool? isAmbiguous,
    String? ambiguityReason,
    List<String>? alternativeMaterials,
    bool? isMixedWaste,
    List<String>? detectedItems,
    String? segregationAdvice,
    String? visualEvidence,
  }) {
    return WastePassportModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      primaryMaterial: primaryMaterial ?? this.primaryMaterial,
      subType: subType ?? this.subType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      recyclabilityGrade: recyclabilityGrade ?? this.recyclabilityGrade,
      degradationTime: degradationTime ?? this.degradationTime,
      estimatedCarbonKg: estimatedCarbonKg ?? this.estimatedCarbonKg,
      materialComposition: materialComposition ?? this.materialComposition,
      handlingInstructions: handlingInstructions ?? this.handlingInstructions,
      circularityGuidance: circularityGuidance ?? this.circularityGuidance,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
      isSimulated: isSimulated ?? this.isSimulated,
      simulationNotice: simulationNotice ?? this.simulationNotice,
      isAmbiguous: isAmbiguous ?? this.isAmbiguous,
      ambiguityReason: ambiguityReason ?? this.ambiguityReason,
      alternativeMaterials: alternativeMaterials ?? this.alternativeMaterials,
      isMixedWaste: isMixedWaste ?? this.isMixedWaste,
      detectedItems: detectedItems ?? this.detectedItems,
      segregationAdvice: segregationAdvice ?? this.segregationAdvice,
      visualEvidence: visualEvidence ?? this.visualEvidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'primaryMaterial': primaryMaterial,
      'subType': subType,
      'confidenceScore': confidenceScore,
      'recyclabilityGrade': recyclabilityGrade.name,
      'degradationTime': degradationTime,
      'estimatedCarbonKg': estimatedCarbonKg,
      'materialComposition': materialComposition,
      'handlingInstructions': handlingInstructions,
      'circularityGuidance': circularityGuidance,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
      'isSimulated': isSimulated,
      'simulationNotice': simulationNotice,
      'isAmbiguous': isAmbiguous,
      'ambiguityReason': ambiguityReason,
      'alternativeMaterials': alternativeMaterials,
      'isMixedWaste': isMixedWaste,
      'detectedItems': detectedItems,
      'segregationAdvice': segregationAdvice,
      'visualEvidence': visualEvidence,
    };
  }

  factory WastePassportModel.fromJson(Map<String, dynamic> json) {
    return WastePassportModel(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      primaryMaterial: json['primaryMaterial'] as String,
      subType: json['subType'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      recyclabilityGrade: RecyclabilityGrade.values.firstWhere(
        (e) => e.name == json['recyclabilityGrade'],
        orElse: () => RecyclabilityGrade.C,
      ),
      degradationTime: json['degradationTime'] as String,
      estimatedCarbonKg: json['estimatedCarbonKg'] as String,
      materialComposition: Map<String, int>.from(json['materialComposition'] as Map),
      handlingInstructions: List<String>.from(json['handlingInstructions'] as List),
      circularityGuidance: Map<String, String>.from(json['circularityGuidance'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePath: json['imagePath'] as String?,
      isSimulated: json['isSimulated'] as bool? ?? false,
      simulationNotice: json['simulationNotice'] as String?,
      isAmbiguous: json['isAmbiguous'] as bool? ?? false,
      ambiguityReason: json['ambiguityReason'] as String?,
      alternativeMaterials: json['alternativeMaterials'] != null
          ? List<String>.from(json['alternativeMaterials'] as List)
          : const [],
      isMixedWaste: json['isMixedWaste'] as bool? ?? false,
      detectedItems: json['detectedItems'] != null
          ? List<String>.from(json['detectedItems'] as List)
          : const [],
      segregationAdvice: json['segregationAdvice'] as String?,
      visualEvidence: json['visualEvidence'] as String?,
    );
  }
}
