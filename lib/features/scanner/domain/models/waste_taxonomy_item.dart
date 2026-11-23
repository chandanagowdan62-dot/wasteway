import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';

/// Structured taxonomy model representing a distinct identifiable waste type
/// in the WasteWay knowledge base (~100 items across 10 main categories).
class WasteTaxonomyItem {
  final String id;
  final String mainCategory;
  final String subCategory;
  final List<String> commonNames;
  final String description;
  final String distinguishingCharacteristics;
  final String typicalAppearance;
  final List<String> similarCategoriesToAvoidConfusingWith;
  final String handlingGuidance;
  final String hazardLevel; // "Ordinary Non-Hazardous" or "Hazardous / Special Handling Required"
  final bool isHazardous;
  final String materialCompositionDescription;
  final List<String> suitableCircularityPathways; // 7-Rs: Reuse, Repair, Recycle, Donate, Return, Compost, Responsible disposal
  final RecyclabilityGrade defaultRecyclabilityGrade;
  final String estimatedDegradationTime;
  final String estimatedCarbonKg;

  const WasteTaxonomyItem({
    required this.id,
    required this.mainCategory,
    required this.subCategory,
    required this.commonNames,
    required this.description,
    required this.distinguishingCharacteristics,
    required this.typicalAppearance,
    required this.similarCategoriesToAvoidConfusingWith,
    required this.handlingGuidance,
    required this.hazardLevel,
    required this.isHazardous,
    required this.materialCompositionDescription,
    required this.suitableCircularityPathways,
    required this.defaultRecyclabilityGrade,
    required this.estimatedDegradationTime,
    required this.estimatedCarbonKg,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
        'commonNames': commonNames,
        'description': description,
        'distinguishingCharacteristics': distinguishingCharacteristics,
        'typicalAppearance': typicalAppearance,
        'similarCategoriesToAvoidConfusingWith': similarCategoriesToAvoidConfusingWith,
        'handlingGuidance': handlingGuidance,
        'hazardLevel': hazardLevel,
        'isHazardous': isHazardous,
        'materialCompositionDescription': materialCompositionDescription,
        'suitableCircularityPathways': suitableCircularityPathways,
        'defaultRecyclabilityGrade': defaultRecyclabilityGrade.name,
        'estimatedDegradationTime': estimatedDegradationTime,
        'estimatedCarbonKg': estimatedCarbonKg,
      };

  factory WasteTaxonomyItem.fromJson(Map<String, dynamic> json) {
    RecyclabilityGrade grade;
    switch (json['defaultRecyclabilityGrade']) {
      case 'A':
        grade = RecyclabilityGrade.A;
        break;
      case 'B':
        grade = RecyclabilityGrade.B;
        break;
      case 'C':
        grade = RecyclabilityGrade.C;
        break;
      case 'D':
        grade = RecyclabilityGrade.D;
        break;
      case 'E':
      default:
        grade = RecyclabilityGrade.E;
        break;
    }

    return WasteTaxonomyItem(
      id: json['id'] as String,
      mainCategory: json['mainCategory'] as String,
      subCategory: json['subCategory'] as String,
      commonNames: List<String>.from(json['commonNames'] as List),
      description: json['description'] as String,
      distinguishingCharacteristics: json['distinguishingCharacteristics'] as String,
      typicalAppearance: json['typicalAppearance'] as String,
      similarCategoriesToAvoidConfusingWith:
          List<String>.from(json['similarCategoriesToAvoidConfusingWith'] as List),
      handlingGuidance: json['handlingGuidance'] as String,
      hazardLevel: json['hazardLevel'] as String,
      isHazardous: json['isHazardous'] as bool? ?? false,
      materialCompositionDescription: json['materialCompositionDescription'] as String,
      suitableCircularityPathways:
          List<String>.from(json['suitableCircularityPathways'] as List),
      defaultRecyclabilityGrade: grade,
      estimatedDegradationTime: json['estimatedDegradationTime'] as String,
      estimatedCarbonKg: json['estimatedCarbonKg'] as String,
    );
  }
}
