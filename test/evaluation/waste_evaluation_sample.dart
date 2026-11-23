/// Data model representing an annotated image evaluation sample
/// in the WasteWay Empirical Evaluation Dataset.
class WasteEvaluationSample {
  final String id;
  final String sampleName;
  final String groundTruthCategory;
  final String groundTruthItemId;
  final String groundTruthItemName;
  final bool isWaste;
  final bool isMixed;
  final String visualDescription;
  final String lightingCondition;
  final String viewingAngle;
  final String backgroundType;
  final String itemCondition; // e.g. "Clean", "Used / Crushed", "Food-Soiled"
  final bool isSimilarMaterialDistractor;
  final String? distractorTarget; // e.g. "Single-Use Plastic Bottle" for a tissue
  final String datasetSplit; // "evaluation_independent" or "reference_fewshot"

  const WasteEvaluationSample({
    required this.id,
    required this.sampleName,
    required this.groundTruthCategory,
    required this.groundTruthItemId,
    required this.groundTruthItemName,
    required this.isWaste,
    this.isMixed = false,
    required this.visualDescription,
    required this.lightingCondition,
    required this.viewingAngle,
    required this.backgroundType,
    required this.itemCondition,
    this.isSimilarMaterialDistractor = false,
    this.distractorTarget,
    this.datasetSplit = 'evaluation_independent',
  });
}
