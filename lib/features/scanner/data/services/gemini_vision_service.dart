import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/services/ai_classification_service.dart';
import '../../../passport/domain/models/waste_passport_model.dart';
import '../../../../core/config/ai_config.dart';

/// Result of querying the Google Gemini Models API to verify key permissions and model availability.
class ModelValidationResult {
  final bool isValid;
  final String? activeModel;
  final List<String> availableModels;
  final List<String> supportedMethods;
  final String? errorMessage;
  final int? httpStatusCode;

  const ModelValidationResult({
    required this.isValid,
    this.activeModel,
    this.availableModels = const [],
    this.supportedMethods = const [],
    this.errorMessage,
    this.httpStatusCode,
  });
}

/// Live Gemini Multimodal Vision API service for waste classification and passport generation.
/// Uses the official Google Gemini Multimodal Flash model (defaults to gemini-3.8-flash)
/// with structured JSON schema.
class GeminiVisionService implements IAIClassificationService {
  final String? _configuredModelName;
  final http.Client? client;

  GeminiVisionService({
    String? modelName,
    this.client,
  }) : _configuredModelName = modelName;

  String get modelName => _configuredModelName ?? AIConfig.modelName;

  @override
  String get providerName => 'Google Gemini Vision ($modelName)';

  @override
  bool get isOnlineService => true;

  /// Sanitizes sensitive API keys from error messages and logs
  static String _sanitizeError(String text, String apiKey) {
    if (apiKey.trim().isEmpty) return text;
    return text.replaceAll(apiKey.trim(), '[REDACTED_API_KEY]');
  }

  /// Queries Google's Models API to verify that the configured key has access to the model
  /// and that the model supports the required 'generateContent' method.
  Future<ModelValidationResult> validateModelAccess({
    required String apiKey,
    String? targetModel,
    http.Client? testClient,
  }) async {
    final clientToUse = testClient ?? client ?? http.Client();
    final requestedModel = targetModel ?? modelName;

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final response = await clientToUse.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        String msg;
        if (response.statusCode == 400) {
          msg = 'Invalid Gemini API key (HTTP 400). Please check your key from Google AI Studio.';
        } else if (response.statusCode == 403) {
          msg = 'Permission denied (HTTP 403). The provided API key does not have access to the Gemini Models API.';
        } else if (response.statusCode == 429) {
          msg = 'Gemini API quota exceeded (HTTP 429). Rate limit reached.';
        } else {
          msg = 'Google Gemini Models API returned HTTP ${response.statusCode}: ${_sanitizeError(response.body, apiKey)}';
        }
        return ModelValidationResult(
          isValid: false,
          httpStatusCode: response.statusCode,
          errorMessage: msg,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final modelsList = data['models'] as List? ?? [];
      final availableModelIds = <String>[];
      final modelSupportedMethods = <String, List<String>>{};

      for (final m in modelsList) {
        if (m is Map<String, dynamic>) {
          final rawName = m['name'] as String? ?? '';
          final modelId = rawName.replaceFirst('models/', '');
          final methods = (m['supportedGenerationMethods'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          availableModelIds.add(modelId);
          modelSupportedMethods[modelId] = methods;
        }
      }

      // Check if requested model is present in the account's accessible models
      if (availableModelIds.contains(requestedModel)) {
        final methods = modelSupportedMethods[requestedModel] ?? const [];
        final hasGenerateContent = methods.contains('generateContent');
        if (hasGenerateContent) {
          return ModelValidationResult(
            isValid: true,
            activeModel: requestedModel,
            availableModels: availableModelIds,
            supportedMethods: methods,
          );
        }
      }

      // Priority list of stable multimodal Flash models to match against available models
      final candidatePriorities = [
        requestedModel,
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-3.8-flash',
        'gemini-3.5-flash-lite',
        'gemini-2.0-flash-001',
        'gemini-1.5-flash-002',
        'gemini-flash-latest',
        ...AIConfig.supportedModels,
      ];

      for (final candidate in candidatePriorities) {
        if (availableModelIds.contains(candidate)) {
          final methods = modelSupportedMethods[candidate] ?? const [];
          if (methods.contains('generateContent')) {
            return ModelValidationResult(
              isValid: true,
              activeModel: candidate,
              availableModels: availableModelIds,
              supportedMethods: methods,
            );
          }
        }
      }

      // If exact candidate IDs not matched, find ANY available model containing 'flash' with generateContent
      for (final modelId in availableModelIds) {
        if (modelId.toLowerCase().contains('flash')) {
          final methods = modelSupportedMethods[modelId] ?? const [];
          if (methods.contains('generateContent')) {
            return ModelValidationResult(
              isValid: true,
              activeModel: modelId,
              availableModels: availableModelIds,
              supportedMethods: methods,
            );
          }
        }
      }

      // Final fallback: any model with generateContent
      for (final modelId in availableModelIds) {
        final methods = modelSupportedMethods[modelId] ?? const [];
        if (methods.contains('generateContent')) {
          return ModelValidationResult(
            isValid: true,
            activeModel: modelId,
            availableModels: availableModelIds,
            supportedMethods: methods,
          );
        }
      }

      return ModelValidationResult(
        isValid: false,
        activeModel: null,
        availableModels: availableModelIds,
        errorMessage: 'Configured model ($requestedModel) is not available to this API key.',
      );
    } catch (e) {
      return ModelValidationResult(
        isValid: false,
        errorMessage: 'Network error checking Gemini Models API: ${_sanitizeError(e.toString(), apiKey)}',
      );
    } finally {
      if (testClient == null && client == null) {
        clientToUse.close();
      }
    }
  }

  @override
  Future<WastePassportModel> classifyWasteImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError('Image payload cannot be empty.');
    }

    final apiKey = AIConfig.apiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is not configured. Provide it via `--dart-define=GEMINI_API_KEY=...` or app settings.',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    // Detect image MIME type dynamically from header bytes
    final String imageMimeType;
    if (imageBytes.length >= 3 && imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) {
      imageMimeType = 'image/jpeg';
    } else if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      imageMimeType = 'image/png';
    } else if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      imageMimeType = 'image/webp';
    } else {
      imageMimeType = 'image/jpeg';
    }

    final base64Image = base64Encode(imageBytes);

    const promptText = '''
You are an expert materials scientist and circular economy analyst for WasteWay.
Analyze the provided image. Carefully inspect the object for visible recycling markings, Resin Identification Codes (RIC 1-7: PET 1, HDPE 2, PVC 3, LDPE 4, PP 5, PS 6, OTHER 7), paper recycling codes (PAP 20/21/22), aluminum/metal stamps, or textile composition tags.

Return a STRICT JSON object conforming to this schema:
{
  "isIdentifiedWaste": true or false,
  "nonWasteReason": "Explanation if isIdentifiedWaste is false",
  "itemName": "Specific recognizable item name (e.g. Single-Use PET Beverage Bottle, Used Paper Tissue / Napkin, Multi-Layer Snack Pouch, Plastic Grocery Bag)",
  "primaryMaterial": "One of: Plastic, Paper & Cardboard, Metals, Glass, Electronic Waste (E-Waste), Biodegradable / Organic, Hazardous / Chemical, Textiles & Fabrics, Multi-Layer / Composite Materials, Medical & Sanitary Waste, Furniture & Bulky Goods, Construction & Demolition Waste, Uncertain / Unknown",
  "subType": "Detailed polymer or material sub-type. If visible Resin Identification Code or label is present, state it explicitly. For metallized snack wrappers where internal layers cannot be determined from external appearance alone, state: 'Likely multilayer or metallised packaging. Exact material composition not confirmed.' If unsure, mark as Unverified or Mixed.",
  "confidenceScore": Float between 0.00 and 1.00 reflecting TRUE confidence. Do NOT artificially inflate confidence. Use 0.85-1.00 only when distinct branding, shape, or recycling symbol confirms identity; 0.40-0.70 for ambiguous visually generic objects.,
  "isAmbiguous": true or false,
  "ambiguityReason": "Detailed explanation if the material cannot be determined with certainty from visual appearance alone",
  "alternativeMaterials": ["Alternative candidate material 1", "Alternative candidate material 2"],
  "visualEvidence": "Observable visual features supporting classification (e.g. 'Clear PET container with triangular resin code #1 visible on underside', 'Aluminium tear-notch with metallic interior reflection', 'Corrugated brown fiber layers', 'No visible stamps; generic packaging appearance')",
  "isMixedWaste": true or false,
  "detectedItems": ["Item 1", "Item 2"],
  "segregationAdvice": "Actionable instructions on how the user must segregate the mixed components before disposal",
  "recyclabilityGrade": "A or B or C or D or E (A=highly recyclable, B=widely recycled, C=moderate, D=low, E=non-recyclable/hazardous)",
  "degradationTime": "Estimated natural degradation time (e.g. 2 - 4 weeks for tissue, estimated degradation time unavailable from photograph for unconfirmed composites, 450 years for plastic bottle)",
  "estimatedCarbonKg": "Estimated embodied carbon footprint (e.g. 0.08 kg CO2e, or Embodied carbon estimate unavailable)",
  "materialComposition": {
    "Observable Part Name": integer_percentage
  },
  "handlingInstructions": [
    "Step 1 preparation (Actionable: empty, clean, dry, separate)",
    "Step 2 specific facility type recommendation (e.g. Authorized Dry Waste Collection Centre, Scrap Aggregator, E-waste Dismantler)",
    "Step 3 what to do if no facility exists locally",
    "Step 4 safe handling precautions and explicit 'What NOT to do' warning"
  ],
  "circularityGuidance": {
    "reuse": "Practical idea to reuse or upcycle, or 'Not applicable' if unhygienic/hazardous",
    "repair": "Repairability guidance or 'Not applicable'",
    "recycle": "Specific bin color (Blue/Green/Yellow/Red/Orange) and recycling stream instruction",
    "donate": "Eligibility for donation, or 'Not recommended'",
    "return": "Manufacturer return or drop-box advice",
    "compost": "Whether safe for composting, or 'Not compostable'",
    "safe_disposal": "Precautionary instructions to prevent environmental contamination"
  }
}

CRITICAL ACCURACY RULES:
1. TISSUES AND NAPKINS: If the image shows a paper tissue, napkin, paper towel, or facial wipe, classify it as primaryMaterial: "Paper & Cardboard", itemName: "Used Paper Tissue / Napkin", subType: "Cellulose Tissue Fiber", recyclabilityGrade: "D" (tissues are non-recyclable in standard dry paper streams; compostable if clean/food-contact, general trash if personal hygiene). NEVER identify a tissue as a plastic water bottle!
2. CHIPS PACKETS & SNACK WRAPPERS: If the image shows a potato chips packet, biscuit wrapper, or flexible snack pouch, classify it as primaryMaterial: "Multi-Layer / Composite Materials", itemName: "Multi-Layer Snack / Chips Pouch". Do NOT invent exact polymer percentages or vacuum aluminium layer thicknesses (e.g. do NOT fabricate 85% BOPP / 15% Al). A photograph alone cannot verify internal multi-layer barrier thickness. State subType as: "Likely multilayer or metallised packaging. Exact material composition not confirmed." Recyclability is Grade C (non-recyclable in standard mechanical recycling; route to industrial cement kilns or authorized DWCC for co-processing). Instruct to empty crumbs, wipe dry, and segregate dry. NEVER classify a chips wrapper as a lithium battery or rigid bottle!
3. PLASTIC COVERS & FILM BAGS: If the image shows a thin plastic shopping bag, grocery cover, cling film, or packaging polybag, classify it as primaryMaterial: "Plastic", itemName: "Plastic Carry Bag / Packaging Film", subType: "Low-Density Polyethylene (LDPE #4)", recyclabilityGrade: "B" or "C".
4. RIGID PLASTIC BOTTLES & CONTAINERS: Classify clear water/soda bottles as primaryMaterial: "Plastic", itemName: "Clear Plastic Beverage Bottle", subType: "Polyethylene Terephthalate (PET #1)", recyclabilityGrade: "A". Classify shampoo/milk jugs as HDPE #2.
5. CARDBOARD BOXES: Classify corrugated brown shipping boxes as primaryMaterial: "Paper & Cardboard", itemName: "Corrugated Shipping Box", subType: "Unbleached Kraft Pulp (PAP 20)", recyclabilityGrade: "A".
6. ALUMINIUM CANS: Classify soda/beverage cans as primaryMaterial: "Metals", itemName: "Aluminium Beverage Can", subType: "Aluminium Alloy (ALU 41)", recyclabilityGrade: "A".
7. GLASS BOTTLES & JARS: Classify glass bottles as primaryMaterial: "Glass", itemName: "Glass Container / Bottle", subType: "Soda-Lime Container Glass", recyclabilityGrade: "A" or "B".
8. FOOD SCRAPS & ORGANIC MATTER: If the image shows food waste, kitchen scraps, produce trimmings, or organic material, classify as primaryMaterial: "Biodegradable / Organic".
   - Raw kitchen produce scraps (banana peels, vegetable trimmings, fruit rinds, apple cores): itemName: "Raw Kitchen Produce Scraps", subType: "Raw Plant Biomass", recyclabilityGrade: "A", 100% compostable, green wet-waste bin.
   - Cooked household leftovers (plate scrapings, rice, bread, curries, oily food residue): itemName: "Cooked Household Food Leftovers", subType: "Cooked Organic Food Waste", recyclabilityGrade: "B", route to municipal green wet-waste biomethanation collection.
   - Spent tea leaves & coffee grounds: itemName: "Spent Coffee Grounds / Tea Leaves", subType: "Cellulosic Beverage Biomass", recyclabilityGrade: "A", superb garden soil amendment and home compost feedstock.
   - Bread, bakery, & grain scraps: itemName: "Stale Bakery & Bread Scraps", subType: "Baked Organic Biomass", recyclabilityGrade: "A", green wet-waste bin.
   - Crushed eggshells & nut shells: itemName: "Eggshells / Nut Shells Waste", subType: "Mineralized Organic Waste", recyclabilityGrade: "A".
   - Meat, poultry bones, & seafood trimmings: itemName: "Meat, Bone & Fish Scraps", subType: "Animal Protein Biomass", recyclabilityGrade: "C", non-compostable in home bins (pest attraction); route to municipal high-temperature biomethanation.
   - Ambiguous food waste: itemName: "Kitchen Food & Organic Scraps", subType: "Uncertain Organic Biomass", isAmbiguous: true, ambiguityReason: "Visual appearance indicates organic or kitchen food waste, but exact ingredients or preparation state cannot be determined with certainty from the photograph alone."
   - Handling instructions: Always instruct green wet-waste bin collection, never wrap in polythene or non-biodegradable plastic bags, drain excess liquids, and route to municipal biomethanation or home composting.
9. TEXTILES & CLOTHING: Classify garments and cloth as primaryMaterial: "Textiles & Fabrics", itemName: "Garment / Textile Fabric", subType: "Cotton / Synthetic Fiber", recyclabilityGrade: "B".
10. STRICT BATTERY / E-WASTE RESTRICTION: NEVER classify an object as a battery, lithium cell, or hazardous electronic item UNLESS distinct electrical terminals (+/-), cylindrical/prismatic battery casing, battery warning text, or electronic circuit boards are clearly visible. Do NOT guess battery for snack wrappers, papers, plastic cups, or generic trash.
11. MEDICAL & SANITARY WASTE: If the image shows medical blister packs, medicine packaging, face masks, latex gloves, cotton swabs, bandages, or sanitary items: classify as primaryMaterial: "Medical & Sanitary Waste", itemName: "Medical / Sanitary Waste Item", recyclabilityGrade: "E" or "D", isHazardous: true. Instruct safe disposal in leak-proof biohazard/sanitary bag; NEVER place in clean dry paper recycling or compost!
12. FURNITURE & BULKY GOODS: If the image shows wooden chairs, desks, broken household furniture, or bulky home goods: classify as primaryMaterial: "Furniture & Bulky Goods", itemName: "Furniture / Bulky Household Item", recyclabilityGrade: "B" or "C". Recommend repair, reuse, donation, or municipal bulky waste drop-off.
13. CONSTRUCTION & DEMOLITION WASTE: If the image shows ceramic tiles, concrete rubble, bricks, drywall, or masonry scraps: classify as primaryMaterial: "Construction & Demolition Waste", itemName: "Construction / Demolition Debris", subType: "Inert Mineral Aggregate", recyclabilityGrade: "D". Route to authorized municipal C&D processing facilities.
14. MIXED WASTE: If the image depicts multiple disparate waste objects (e.g. a plastic bottle with a wrapper and paper), set "isMixedWaste": true, list all detected items in "detectedItems", and explain how to segregate them in "segregationAdvice".
15. MATERIAL COMPOSITION: Do NOT fabricate unverified polymer fractions or chemical layer percentages. If the internal composition is uncertain from exterior appearance alone, set materialComposition to {"Likely multilayer or metallised packaging. Exact material composition not confirmed": 100} or realistic observable parts. Do NOT invent cathode/anode or battery components for non-batteries!
16. NON-WASTE OBJECTS: If the image does NOT depict municipal solid waste, packaging, scrap, or compostable goods (e.g. human face, live animal, scenic landscape, building), set "isIdentifiedWaste": false, "itemName": "Non-Waste Subject", "confidenceScore": 0.0, and explain in "nonWasteReason".
17. UNRECOGNIZABLE / BLURRY: If the photo is completely blurry or unreadable, set "isIdentifiedWaste": false, "itemName": "Unrecognized Object", "confidenceScore": 0.0.
18. Respond ONLY with valid JSON.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inlineData': {
                'mimeType': imageMimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    });

    final httpClient = client ?? http.Client();
    http.Response response;
    try {
      response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Gemini API request timed out after 30 seconds. Please check your internet connection and try again.',
        ),
      );
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      final safeMsg = _sanitizeError(e.toString(), apiKey);
      throw Exception(
        'Network connection error: Unable to reach Gemini API ($safeMsg). Please check your internet connection.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        throw Exception(
          'Gemini API quota rate limit exceeded (429). Please try again shortly or check your Google AI Studio quota.',
        );
      } else if (response.statusCode == 400) {
        throw Exception(
          'Gemini API request rejected (400). Please verify your API key or image payload in AI Settings.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Gemini API key is invalid or unauthorized (403). Please verify your key in AI Settings.',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'Gemini model ($modelName) not found (HTTP 404). Please verify model ID in AI Settings or regional availability.',
        );
      } else {
        final safeBody = _sanitizeError(response.body, apiKey);
        throw Exception(
          'Gemini API returned error HTTP ${response.statusCode}: $safeBody',
        );
      }
    }

    final responseData = jsonDecode(response.body);
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini API returned no classification candidates.');
    }

    final content = candidates[0]['content'];
    final parts = content['parts'] as List;
    final rawText = parts[0]['text'] as String;

    final parsedJson = _cleanAndParseJson(rawText);

    // Validate waste identification
    final isIdentifiedWaste = parsedJson['isIdentifiedWaste'] as bool? ?? true;
    final confidence = (parsedJson['confidenceScore'] as num?)?.toDouble() ?? 0.0;
    final nonWasteReason = parsedJson['nonWasteReason'] as String?;

    if (!isIdentifiedWaste || confidence < 0.25) {
      final reason = nonWasteReason ??
          'The provided image does not clearly depict a recognized waste, recyclable, or compostable item.';
      throw UnrecognizedWasteException(
        'Unable to classify item: $reason Please capture a clear photo of an actual waste or recyclable object with good lighting.',
        reason: reason,
      );
    }

    // Validate required fields without silent defaults
    final itemName = parsedJson['itemName'] as String?;
    final primaryMaterial = parsedJson['primaryMaterial'] as String?;
    final subTypeRaw = parsedJson['subType'] as String?;
    final gradeRaw = parsedJson['recyclabilityGrade'];

    if (itemName == null || itemName.trim().isEmpty) {
      throw const FormatException('Gemini classification response is missing a valid "itemName".');
    }
    if (primaryMaterial == null ||
        primaryMaterial.trim().isEmpty ||
        primaryMaterial == 'Uncertain / Unknown') {
      throw const FormatException('Gemini classification response could not determine a valid "primaryMaterial".');
    }
    if (subTypeRaw == null || subTypeRaw.trim().isEmpty) {
      throw const FormatException('Gemini classification response is missing a valid "subType".');
    }
    if (gradeRaw == null) {
      throw const FormatException('Gemini classification response is missing a valid "recyclabilityGrade".');
    }

    final recyclabilityGrade = _parseGrade(gradeRaw);
    final isAmbiguous = parsedJson['isAmbiguous'] as bool? ?? (confidence < 0.65);
    final ambiguityReason = parsedJson['ambiguityReason'] as String?;
    final altList = (parsedJson['alternativeMaterials'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final isMixedWaste = parsedJson['isMixedWaste'] as bool? ?? false;
    final detectedItems = (parsedJson['detectedItems'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final segregationAdvice = parsedJson['segregationAdvice'] as String?;
    final visualEvidence = parsedJson['visualEvidence'] as String?;

    // Scientific accuracy guard: For multilayer packaging where internal structure cannot be known from exterior photo
    final String cleanSubType;
    if (primaryMaterial == 'Multi-Layer / Composite Materials') {
      if (subTypeRaw.contains('Exact material composition not confirmed') ||
          subTypeRaw.toLowerCase().contains('metallized') ||
          subTypeRaw.toLowerCase().contains('composite') ||
          subTypeRaw.toLowerCase().contains('layer') ||
          isAmbiguous) {
        cleanSubType = 'Likely multilayer or metallised packaging. Exact material composition not confirmed.';
      } else {
        cleanSubType = subTypeRaw.trim();
      }
    } else {
      cleanSubType = subTypeRaw.trim();
    }

    // Sanitize composition: do not allow unconfirmed fabricated chemical percentages for composite packaging
    final Map<String, int> cleanComposition;
    if (primaryMaterial == 'Multi-Layer / Composite Materials') {
      cleanComposition = {
        'Likely multilayer or metallised packaging. Exact material composition not confirmed': 100,
      };
    } else {
      cleanComposition = (parsedJson['materialComposition'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {primaryMaterial: 100};
    }

    // Safety guard: ensure no battery or lithium chemistry leaks into food packaging guidance,
    // while ensuring genuine batteries retain their essential fire and terminal precautions.
    final isActualBattery = primaryMaterial.contains('E-Waste') ||
        primaryMaterial.contains('Hazardous') ||
        subTypeRaw.toLowerCase().contains('battery') ||
        subTypeRaw.toLowerCase().contains('lithium') ||
        itemName.toLowerCase().contains('battery');

    final rawHandling = (parsedJson['handlingInstructions'] as List?)
            ?.map((e) => e.toString())
            .where((s) {
              if (!isActualBattery) {
                final lower = s.toLowerCase();
                return !lower.contains('battery') && !lower.contains('lithium');
              }
              return true;
            })
            .toList() ??
        <String>[];
    if (rawHandling.isEmpty) {
      rawHandling.addAll(['Clean and empty dry waste', 'Deposit in designated dry recyclables collection']);
    }

    final uniqueSuffix = Random().nextInt(9000) + 1000;
    return WastePassportModel(
      id: 'DWP-2026-$uniqueSuffix',
      itemName: itemName.trim(),
      primaryMaterial: primaryMaterial.trim(),
      subType: cleanSubType,
      confidenceScore: confidence,
      recyclabilityGrade: recyclabilityGrade,
      degradationTime: parsedJson['degradationTime'] as String? ?? 'Estimated degradation time unavailable',
      estimatedCarbonKg: parsedJson['estimatedCarbonKg'] as String? ?? 'Embodied carbon estimate unavailable',
      materialComposition: cleanComposition,
      handlingInstructions: rawHandling,
      circularityGuidance: (parsedJson['circularityGuidance'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {
            'recycle': 'Deposit in dry-waste bin',
            'safe_disposal': 'Do not litter in natural environments',
          },
      createdAt: DateTime.now(),
      isSimulated: false,
      isAmbiguous: isAmbiguous,
      ambiguityReason: ambiguityReason,
      alternativeMaterials: altList,
      isMixedWaste: isMixedWaste,
      detectedItems: detectedItems,
      segregationAdvice: segregationAdvice,
      visualEvidence: visualEvidence,
    );
  }

  Map<String, dynamic> _cleanAndParseJson(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  RecyclabilityGrade _parseGrade(dynamic gradeValue) {
    if (gradeValue == null) {
      throw const FormatException('Missing recyclabilityGrade in Gemini response');
    }
    final str = gradeValue.toString().toUpperCase().trim();
    switch (str) {
      case 'A':
        return RecyclabilityGrade.A;
      case 'B':
        return RecyclabilityGrade.B;
      case 'C':
        return RecyclabilityGrade.C;
      case 'D':
        return RecyclabilityGrade.D;
      case 'E':
        return RecyclabilityGrade.E;
      default:
        throw FormatException(
          'Invalid recyclabilityGrade "$gradeValue" in Gemini response. Expected A, B, C, D, or E.',
        );
    }
  }
}
