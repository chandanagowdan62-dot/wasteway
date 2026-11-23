import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../domain/services/ai_classification_service.dart';
import '../../../passport/domain/models/waste_passport_model.dart';

/// Offline mock classification engine for demonstrations without internet or API key
class MockAIClassificationService implements IAIClassificationService {
  @override
  String get providerName => 'Offline Simulation Engine';

  @override
  bool get isOnlineService => false;

  @override
  Future<WastePassportModel> classifyWasteImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    // Simulate real-world AI processing latency (800ms)
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedName = fileName.toLowerCase();
    final catalog = _getMockCatalog();

    // Select based on filename keyword
    WastePassportModel template;
    if (normalizedName.contains('tissue') ||
        normalizedName.contains('napkin') ||
        normalizedName.contains('wipe') ||
        normalizedName.contains('toilet') ||
        normalizedName.contains('kleenex') ||
        normalizedName.contains('paper_t')) {
      template = catalog[0]; // Tissue
    } else if (normalizedName.contains('chip') ||
        normalizedName.contains('snack') ||
        normalizedName.contains('lays') ||
        normalizedName.contains('kurkure') ||
        normalizedName.contains('biscuit') ||
        normalizedName.contains('wrapper') ||
        normalizedName.contains('packet') ||
        normalizedName.contains('pouch')) {
      template = catalog[1]; // Chips / Snack packet
    } else if (normalizedName.contains('bottle') ||
        normalizedName.contains('water') ||
        normalizedName.contains('beverage') ||
        normalizedName.contains('pet') ||
        normalizedName.contains('coke') ||
        normalizedName.contains('pepsi')) {
      template = catalog[2]; // Water bottle
    } else if (normalizedName.contains('battery') ||
        normalizedName.contains('lithium') ||
        normalizedName.contains('cell') ||
        normalizedName.contains('accumulator')) {
      template = catalog[3]; // Battery (only with explicit keyword)
    } else if (normalizedName.contains('can') ||
        normalizedName.contains('metal') ||
        normalizedName.contains('tin') ||
        normalizedName.contains('aluminium') ||
        normalizedName.contains('soda')) {
      template = catalog[4]; // Aluminium Can
    } else if (normalizedName.contains('box') ||
        normalizedName.contains('cardboard') ||
        normalizedName.contains('carton') ||
        normalizedName.contains('kraft')) {
      template = catalog[5]; // Cardboard
    } else if (normalizedName.contains('glass') || normalizedName.contains('jar')) {
      template = catalog[6]; // Glass
    } else if (normalizedName.contains('food') ||
        normalizedName.contains('peel') ||
        normalizedName.contains('banana') ||
        normalizedName.contains('fruit') ||
        normalizedName.contains('vegetable') ||
        normalizedName.contains('organic')) {
      template = catalog[7]; // Organic
    } else if (normalizedName.contains('cloth') ||
        normalizedName.contains('textile') ||
        normalizedName.contains('shirt') ||
        normalizedName.contains('fabric') ||
        normalizedName.contains('cotton')) {
      template = catalog[8]; // Textiles
    } else if (normalizedName.contains('mix') ||
        normalizedName.contains('garbage') ||
        normalizedName.contains('trash') ||
        normalizedName.contains('segregat')) {
      template = catalog[9]; // Mixed waste
    } else {
      // Generic filename (e.g. image_picker_xxx, camera_xxx, upload.jpg) without metadata keywords.
      // Perform lightweight pixel sampling to check for predominant organic food/vegetal color signatures.
      bool likelyOrganic = false;
      if (imageBytes.isNotEmpty) {
        try {
          final decoded = img.decodeImage(imageBytes);
          if (decoded != null) {
            int organicToneCount = 0;
            int totalSampled = 0;
            final stepX = max(1, decoded.width ~/ 8);
            final stepY = max(1, decoded.height ~/ 8);
            for (int y = 0; y < decoded.height; y += stepY) {
              for (int x = 0; x < decoded.width; x += stepX) {
                final pixel = decoded.getPixel(x, y);
                final r = pixel.r.toInt();
                final g = pixel.g.toInt();
                final b = pixel.b.toInt();
                // Vegetal green (peel/leaves) or warm brown/orange organic tones
                if ((g > r && g > b && g > 40) || (r > 80 && g > 50 && b < 70)) {
                  organicToneCount++;
                }
                totalSampled++;
              }
            }
            if (totalSampled > 0 && (organicToneCount / totalSampled) >= 0.25) {
              likelyOrganic = true;
            }
          }
        } catch (_) {
          // If decode fails, fallback to unconfirmed template safely
        }
      }

      if (likelyOrganic) {
        template = catalog[7]; // Organic / Food Waste
      } else {
        template = WastePassportModel(
          id: 'DWP-MOCK-GENERIC',
          itemName: 'Unconfirmed Waste Item (Offline Simulation)',
          primaryMaterial: 'Uncertain / Pending Confirmation',
          subType: 'Material Not Confirmed (Demo)',
          confidenceScore: 0.50,
          recyclabilityGrade: RecyclabilityGrade.C,
          degradationTime: 'Varies by material stream',
          estimatedCarbonKg: 'Carbon estimate pending confirmation',
          materialComposition: {'Material composition not confirmed': 100},
          handlingInstructions: [
            'Examine the item to determine whether it is organic food waste, dry packaging, or hazardous waste.',
            'Segregate wet kitchen waste into the green bin and dry recyclables into the blue bin.',
            'Do not mix unverified waste with clean dry paper or plastic recyclables.'
          ],
          circularityGuidance: {
            'compost': 'Safe for compost only if confirmed 100% organic/food scraps.',
            'recycle': 'Deposit in the blue dry-waste bin if verified clean plastic, paper, or metal.',
            'safe_disposal': 'Ensure item is clean and segregated before collection.'
          },
          visualEvidence: 'Offline demo capture without live AI computer vision.',
          createdAt: DateTime.now(),
          isAmbiguous: true,
          ambiguityReason:
              'Offline simulation cannot inspect image pixels with live AI. Please select the correct category below (e.g. Food Scraps, Plastic Packaging, Paper, or Metal) to view tailored circularity pathways.',
          alternativeMaterials: [
            'Fresh Fruit Scrap / Food Waste',
            'Multi-Layer Chips & Snack Wrapper',
            'Single-Use PET Beverage Bottle',
            'Used Paper Tissue / Napkin',
            'Corrugated Shipping Box',
            'Aluminium Beverage Can'
          ],
        );
      }
    }

    final uniqueSuffix = Random().nextInt(9000) + 1000;
    return WastePassportModel(
      id: 'DWP-SIM-$uniqueSuffix',
      itemName: template.itemName,
      primaryMaterial: template.primaryMaterial,
      subType: template.subType,
      confidenceScore: template.confidenceScore,
      recyclabilityGrade: template.recyclabilityGrade,
      degradationTime: template.degradationTime,
      estimatedCarbonKg: template.estimatedCarbonKg,
      materialComposition: template.materialComposition,
      handlingInstructions: template.handlingInstructions,
      circularityGuidance: template.circularityGuidance,
      createdAt: DateTime.now(),
      isSimulated: true,
      simulationNotice:
          'Demonstration Record (Offline Simulation) — Generated from local sample catalog. Not classified by live AI.',
      isAmbiguous: template.isAmbiguous,
      ambiguityReason: template.ambiguityReason,
      alternativeMaterials: template.alternativeMaterials,
      isMixedWaste: template.isMixedWaste,
      detectedItems: template.detectedItems,
      segregationAdvice: template.segregationAdvice,
      visualEvidence: template.visualEvidence,
    );
  }

  List<WastePassportModel> _getMockCatalog() {
    return [
      // 0: Used Paper Tissue / Napkin
      WastePassportModel(
        id: 'DWP-MOCK-TISSUE',
        itemName: 'Used Paper Tissue / Napkin',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Cellulose Tissue Fiber',
        confidenceScore: 0.94,
        recyclabilityGrade: RecyclabilityGrade.D,
        degradationTime: '2 - 4 weeks in soil / compost',
        estimatedCarbonKg: '0.01 kg CO2e',
        materialComposition: {'Cellulose Wood Pulp': 100},
        handlingInstructions: [
          'If soiled with food or liquids, place in home compost or green wet-waste bin.',
          'If contaminated with personal hygiene, cosmetics, or medicine, discard in regular waste.',
          'Never place soiled tissues in clean paper recycling bins.'
        ],
        circularityGuidance: {
          'reuse': 'Not reusable due to sanitary hygiene.',
          'repair': 'Not applicable for single-use paper items.',
          'recycle': 'Non-recyclable in paper mills because cellulose fibers are too short and soiled.',
          'donate': 'Not applicable for used personal items.',
          'return': 'Not applicable for sanitary paper waste.',
          'compost': 'Safe to compost in aerobic garden composters if free of chemical cleaners.',
          'safe_disposal': 'Wrap hygiene tissues and place in standard household waste bin.',
        },
        visualEvidence: 'Soft fibrous texture, visible cellulose wood fiber grain, absence of plastic sheen.',
        createdAt: DateTime.now(),
      ),

      // 1: Multi-Layer Snack / Chips Pouch
      WastePassportModel(
        id: 'DWP-MOCK-CHIPS',
        itemName: 'Multi-Layer Chips & Snack Wrapper',
        primaryMaterial: 'Multi-Layer / Composite Materials',
        subType: 'Likely multilayer or metallised packaging. Exact material composition not confirmed.',
        confidenceScore: 0.93,
        recyclabilityGrade: RecyclabilityGrade.C,
        degradationTime: 'Estimated degradation time unavailable from photograph',
        estimatedCarbonKg: 'Embodied carbon estimate unavailable',
        materialComposition: {
          'Likely multilayer or metallised packaging. Exact material composition not confirmed': 100,
        },
        handlingInstructions: [
          'Shake out all residual food crumbs and wipe dry.',
          'Do not mix with wet kitchen waste.',
          'Hand over to municipal Dry Waste Collection Centres (DWCC) for coprocessing.'
        ],
        circularityGuidance: {
          'reuse': 'Can be tightly stuffed into plastic bottles to create DIY eco-bricks.',
          'repair': 'Not applicable for single-use flexible packaging.',
          'recycle': 'Co-processing in industrial cement kilns for energy and mineral recovery; standard mechanical recycling cannot separate laminated plastic/aluminium foils.',
          'donate': 'Collect clean wrappers for municipal dry waste recovery drives.',
          'return': 'Drop off at brand packaging collection drives if available.',
          'compost': 'Strictly non-compostable due to plastic and aluminium laminates.',
          'safe_disposal': 'Deposit clean and dry in the dry-waste stream; never burn in open air.'
        },
        visualEvidence: 'Flexible sealed snack pouch with metallic interior foil reflection and heat-sealed crimped edges.',
        createdAt: DateTime.now(),
      ),

      // 2: Single-Use PET Water Bottle
      WastePassportModel(
        id: 'DWP-MOCK-BOTTLE',
        itemName: 'Single-Use Water Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET (Type 1)',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years in landfill',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'PET Body': 88, 'PP Cap': 12},
        handlingInstructions: [
          'Unscrew cap and empty all residual liquid.',
          'Rinse bottle to eliminate sugars or drink residues.',
          'Crush vertically to minimize storage volume.'
        ],
        circularityGuidance: {
          'reuse': 'Repurpose as seedling planters, drip irrigators, or DIY organizers.',
          'repair': 'Not applicable for single-use containers.',
          'recycle': 'Highly recyclable. Deposit in Blue Dry-Waste bin for flake pelletization.',
          'donate': 'Accumulate clean, crushed bottles in bulk for informal scrap collector livelihoods.',
          'return': 'Accepted in scrap buyback centres and retail reverse vending kiosks.',
          'compost': 'Strictly non-compostable.',
          'safe_disposal': 'Ensure containment to avoid breakdown into microplastics.'
        },
        visualEvidence: 'Clear cylindrical bottle body, injection gate dimple on bottom, threaded neck for cap, visible PET #1 resin symbol.',
        createdAt: DateTime.now(),
      ),

      // 3: Lithium-Ion Battery (Strictly for explicit battery keywords)
      WastePassportModel(
        id: 'DWP-MOCK-BATTERY',
        itemName: 'Lithium-Ion Rechargeable Cell',
        primaryMaterial: 'Electronic Waste (E-Waste)',
        subType: 'Lithium-Cobalt Secondary Cell',
        confidenceScore: 0.93,
        recyclabilityGrade: RecyclabilityGrade.E,
        degradationTime: 'Non-biodegradable (Hazardous Chemical)',
        estimatedCarbonKg: '1.40 kg CO2e',
        materialComposition: {'Cathode & Anode Metals': 60, 'Steel & Aluminium Casing': 40},
        handlingInstructions: [
          'DANGER: Do not crush, puncture, or expose to high temperatures.',
          'Insulate positive and negative terminals using electrical tape.',
          'Never discard in curbside municipal bins.'
        ],
        circularityGuidance: {
          'reuse': 'Test cell voltage for secondary low-current energy circuits.',
          'repair': 'Professional BMS circuit refurbishment only.',
          'recycle': 'Take strictly to authorized hydrometallurgical e-waste recovery centers.',
          'donate': 'Not recommended due to fire hazards.',
          'return': 'Drop off at consumer electronics brand service collection bins.',
          'compost': 'STRICTLY FORBIDDEN. Releases toxic heavy metals into soil and groundwater.',
          'safe_disposal': 'Store in a cool, fire-retardant container until authorized handover.'
        },
        visualEvidence: 'Rigid cylindrical casing, distinct positive (+) terminal button and negative (-) flat base, printed voltage and chemistry warning.',
        createdAt: DateTime.now(),
      ),

      // 4: Aluminium Beverage Can
      WastePassportModel(
        id: 'DWP-MOCK-CAN',
        itemName: 'Aluminium Beverage Can',
        primaryMaterial: 'Metals',
        subType: 'Aluminium Alloy 3004',
        confidenceScore: 0.98,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '200 - 500 years',
        estimatedCarbonKg: '0.04 kg CO2e (Recycled)',
        materialComposition: {'Aluminium Alloy': 98, 'Internal Coating': 2},
        handlingInstructions: [
          'Rinse cleanly with water to remove beverage sugars.',
          'Crush can flat to reduce logistical bulk.',
          'Keep pull-tab intact with can body.'
        ],
        circularityGuidance: {
          'reuse': 'Upcycle into desk accessories or candle holders.',
          'recycle': 'High commercial value! Route to scrap dealers or dry-waste centers.',
          'return': 'Accepted in metal buyback centers and reverse vending kiosks.',
          'safe_disposal': 'Store clean and dry.'
        },
        visualEvidence: 'Cylindrical aluminium body, concave base, stay-on tab opening, ALU 41 stamp.',
        createdAt: DateTime.now(),
      ),

      // 5: Corrugated Shipping Box
      WastePassportModel(
        id: 'DWP-MOCK-BOX',
        itemName: 'Corrugated Shipping Box',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Unbleached Kraft Pulp',
        confidenceScore: 0.96,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '2 - 3 months in soil',
        estimatedCarbonKg: '0.15 kg CO2e',
        materialComposition: {'Kraft Paper Fiber': 96, 'Adhesives': 4},
        handlingInstructions: [
          'Remove synthetic plastic packaging tape and labels.',
          'Flatten box completely to save volume.',
          'Keep dry; oil-stained or wet cardboard must not enter paper recycling.'
        ],
        circularityGuidance: {
          'reuse': 'Ideal for household storage, shipping, or garden sheet mulching.',
          'recycle': 'Place in dry paper stream for mechanical repulping.',
          'compost': 'Shred clean unprinted cardboard into garden compost as brown carbon layer.',
          'safe_disposal': 'Ensure no hazardous chemical saturation.'
        },
        visualEvidence: 'Corrugated inner fluting between linerboards, kraft brown pulp texture, printed PAP 20 symbol.',
        createdAt: DateTime.now(),
      ),

      // 6: Preserve Glass Jam Jar
      WastePassportModel(
        id: 'DWP-MOCK-GLASS',
        itemName: 'Preserve Glass Jam Jar',
        primaryMaterial: 'Glass',
        subType: 'Soda-Lime Container Glass',
        confidenceScore: 0.97,
        recyclabilityGrade: RecyclabilityGrade.B,
        degradationTime: '1,000,000+ years',
        estimatedCarbonKg: '0.18 kg CO2e',
        materialComposition: {'Soda-Lime Glass': 90, 'Steel Lid': 10},
        handlingInstructions: [
          'Wash with soap and water to clear food residue.',
          'Separate steel twist-off lid from the glass jar body.',
          'Do not break; broken glass endangers waste handlers.'
        ],
        circularityGuidance: {
          'reuse': 'Exceptional longevity for kitchen bulk storage or drinking containers.',
          'recycle': '100% infinitely recyclable without quality loss.',
          'return': 'Accepted in container return depots.',
          'safe_disposal': 'Wrap in paper if chipped to protect collection workers.'
        },
        visualEvidence: 'Transparent soda-lime container glass, mold seams, rigid non-porous structure.',
        createdAt: DateTime.now(),
      ),

      // 7: Fresh Fruit Scrap / Banana Peel
      WastePassportModel(
        id: 'DWP-MOCK-ORGANIC',
        itemName: 'Fresh Fruit Scrap / Food Waste',
        primaryMaterial: 'Biodegradable / Organic',
        subType: 'Cellulosic Organic Biomass',
        confidenceScore: 0.99,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '2 - 4 weeks',
        estimatedCarbonKg: '0.01 kg CO2e (Composted)',
        materialComposition: {'Organic Moisture & Fiber': 100},
        handlingInstructions: [
          'Remove plastic brand stickers or twist ties completely.',
          'Deposit directly in the Green Wet-Waste or compost bin.',
          'Do not mix with dry recyclables or plastic packaging.'
        ],
        circularityGuidance: {
          'compost': 'Ideal green nitrogen source for home composters and community vermicompost.',
          'reuse': 'Fruit peels can be soaked in water for natural plant fertilizer.',
          'safe_disposal': 'Compost to avoid methane generation in anaerobic landfills.'
        },
        visualEvidence: 'Organic food residue, moisture, cellular plant tissue, peel skins.',
        createdAt: DateTime.now(),
      ),

      // 8: Worn Cotton Garment / Scraps
      WastePassportModel(
        id: 'DWP-MOCK-TEXTILE',
        itemName: 'Worn Cotton Garment / T-Shirt',
        primaryMaterial: 'Textiles & Fabrics',
        subType: '100% Spun Cotton Fiber',
        confidenceScore: 0.92,
        recyclabilityGrade: RecyclabilityGrade.B,
        degradationTime: '5 - 6 months (Natural Fibers)',
        estimatedCarbonKg: '2.10 kg CO2e',
        materialComposition: {'Natural Cotton': 98, 'Thread & Tag': 2},
        handlingInstructions: [
          'Wash and dry completely before segregation.',
          'Keep dry and protected from mildew.',
          'Remove metallic buttons or heavy zippers if separating for shredding.'
        ],
        circularityGuidance: {
          'donate': 'Donate wearable garments to NGO clothing drives like Goonj.',
          'repair': 'Mend seams or patch worn areas to extend wearable lifecycle.',
          'reuse': 'Cut into washable household cleaning rags or tote bags.',
          'recycle': 'Deposit in dedicated textile banks for shoddy yarn spinning.',
          'safe_disposal': 'Never burn textiles; synthetic dyes emit volatile pollutants.'
        },
        visualEvidence: 'Woven fabric texture, hemmed stitching, garment label.',
        createdAt: DateTime.now(),
      ),

      // 9: Mixed Municipal Packaging Waste
      WastePassportModel(
        id: 'DWP-MOCK-MIXED',
        itemName: 'Mixed Municipal Packaging Waste',
        primaryMaterial: 'Multi-Layer / Composite Materials',
        subType: 'Mixed Dry Packaging',
        confidenceScore: 0.85,
        recyclabilityGrade: RecyclabilityGrade.C,
        degradationTime: 'Varies by component (20 - 450 years)',
        estimatedCarbonKg: '0.22 kg CO2e',
        materialComposition: {
          'Flexible Plastic Film': 45,
          'Cardboard Packaging': 35,
          'Rigid PET': 20
        },
        handlingInstructions: [
          'Segregate mixed dry packaging into individual material categories.',
          'Rinse rigid containers and flatten cardboard boxes.',
          'Keep dry materials separate from kitchen wet waste.'
        ],
        circularityGuidance: {
          'recycle': 'Route separated rigid items to scrap dealers and flexible films to DWCCs.',
          'safe_disposal': 'Deposit into municipal blue dry-waste bin only after segregation.'
        },
        visualEvidence: 'Multiple disparate items visible in field: flexible wrapper and paper sheet.',
        createdAt: DateTime.now(),
        isMixedWaste: true,
        detectedItems: ['Flexible Snack Wrapper', 'Cardboard Scrap', 'Rigid Plastic Cup'],
        segregationAdvice:
            'Separate rigid plastics from flexible wrappers and cardboard boxes before placing them in the municipal dry-waste bin.',
      ),
    ];
  }
}
