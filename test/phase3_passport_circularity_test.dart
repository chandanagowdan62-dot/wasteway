import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('Phase 3: WastePassportModel Domain Logic Tests', () {
    test('Accurately detects hazardous materials and assigns appropriate bin stream', () {
      final batteryPassport = WastePassportModel(
        id: 'DWP-TEST-01',
        itemName: 'Lithium Battery Cell',
        primaryMaterial: 'Electronic Waste (E-Waste)',
        subType: 'Lithium-Ion 18650',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.E,
        degradationTime: '100+ years',
        estimatedCarbonKg: '1.2 kg CO2e',
        materialComposition: {'Lithium & Cobalt': 50, 'Steel': 50},
        handlingInstructions: ['Tape terminals'],
        circularityGuidance: {
          'reuse': 'Check cell voltage',
          'repair': 'BMS refurbishment',
          'recycle': 'Hydrometallurgical extraction',
          'donate': 'Not recommended',
          'return': 'Retail kiosk drop-off',
          'compost': 'Strictly forbidden',
          'safe_disposal': 'Store in fireproof container'
        },
        createdAt: DateTime.now(),
      );

      expect(batteryPassport.isHazardous, isTrue);
      expect(batteryPassport.recommendedBinStream, contains('Red'));

      final bottlePassport = WastePassportModel(
        id: 'DWP-TEST-02',
        itemName: 'Plastic Water Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET (Type 1)',
        confidenceScore: 0.98,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'PET': 90, 'PP': 10},
        handlingInstructions: ['Rinse and crush'],
        circularityGuidance: {
          'reuse': 'Indoor planter',
          'repair': 'Single-use',
          'recycle': 'Mechanical flake pelletization',
          'donate': 'Scrap collector batches',
          'return': 'Reverse vending machines',
          'compost': 'Not compostable',
          'safe_disposal': 'Contain in dry-waste stream'
        },
        createdAt: DateTime.now(),
      );

      expect(bottlePassport.isHazardous, isFalse);
      expect(bottlePassport.recommendedBinStream, contains('Blue'));

      final organicPassport = WastePassportModel(
        id: 'DWP-TEST-03',
        itemName: 'Apple Core Scrap',
        primaryMaterial: 'Biodegradable / Organic',
        subType: 'Organic Biomass',
        confidenceScore: 0.99,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '2 weeks',
        estimatedCarbonKg: '0.01 kg CO2e',
        materialComposition: {'Moisture & Fiber': 100},
        handlingInstructions: ['Remove packaging stickers'],
        circularityGuidance: {
          'reuse': 'Infused water fertilizer',
          'repair': 'N/A',
          'recycle': 'Microbial processing',
          'donate': 'Animal feed',
          'return': 'N/A',
          'compost': 'Home compost bin green nitrogen layer',
          'safe_disposal': 'Compost to avert landfill methane'
        },
        createdAt: DateTime.now(),
      );

      expect(organicPassport.isHazardous, isFalse);
      expect(organicPassport.recommendedBinStream, contains('Green'));
    });

    test('Validates complete coverage of all 7-Rs circularity pathways', () {
      final sample = WastePassportModel(
        id: 'DWP-TEST-04',
        itemName: 'Aluminium Beverage Can',
        primaryMaterial: 'Metals',
        subType: 'Aluminium 3004',
        confidenceScore: 0.97,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '300 years',
        estimatedCarbonKg: '0.04 kg CO2e',
        materialComposition: {'Aluminium': 98, 'Epoxy': 2},
        handlingInstructions: ['Rinse and crush flat'],
        circularityGuidance: {
          'reuse': 'Pencil stand',
          'repair': 'Infinitely recyclable',
          'recycle': 'Blue dry-waste bin',
          'donate': 'Scrap drives',
          'return': 'Buyback depots',
          'compost': 'Not compostable',
          'safe_disposal': 'Dry storage'
        },
        createdAt: DateTime.now(),
      );

      const requiredRKeys = [
        'reuse',
        'repair',
        'recycle',
        'donate',
        'return',
        'compost',
        'safe_disposal'
      ];

      for (final rKey in requiredRKeys) {
        expect(sample.circularityGuidance.containsKey(rKey), isTrue);
        expect(sample.circularityGuidance[rKey]!.isNotEmpty, isTrue);
      }
    });

    test('JSON serialization round-trip preservation', () {
      final original = WastePassportModel(
        id: 'DWP-ROUNDTRIP-01',
        itemName: 'Cardboard Box',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Kraft Corrugated',
        confidenceScore: 0.92,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '2 months',
        estimatedCarbonKg: '0.12 kg CO2e',
        materialComposition: {'Paper': 95, 'Adhesive': 5},
        handlingInstructions: ['Remove tape', 'Flatten'],
        circularityGuidance: {
          'reuse': 'Moving box',
          'repair': 'Tape reinforcement',
          'recycle': 'Repulping mill',
          'donate': 'Book vendors',
          'return': 'Courier centers',
          'compost': 'Brown carbon compost layer',
          'safe_disposal': 'Keep free of oil'
        },
        createdAt: DateTime.now(),
      );

      final json = original.toJson();
      final revived = WastePassportModel.fromJson(json);

      expect(revived.id, original.id);
      expect(revived.itemName, original.itemName);
      expect(revived.recyclabilityGrade, original.recyclabilityGrade);
      expect(revived.materialComposition['Paper'], 95);
      expect(revived.handlingInstructions.length, 2);
    });
  });

  group('Phase 3: PassportProvider Search and Filter Tests', () {
    late PassportProvider provider;

    setUp(() {
      provider = PassportProvider();
    });

    test('Filters passports by search text and material category', () {
      expect(provider.passports.isNotEmpty, isTrue);

      // Search for 'bottle'
      provider.setSearchQuery('bottle');
      final searchResults = provider.filteredPassports;
      expect(searchResults.isNotEmpty, isTrue);
      expect(
        searchResults.every((p) =>
            p.itemName.toLowerCase().contains('bottle') ||
            p.primaryMaterial.toLowerCase().contains('bottle') ||
            p.subType.toLowerCase().contains('bottle')),
        isTrue,
      );

      provider.clearFilters();

      // Filter by Grade E
      provider.setGradeFilter(RecyclabilityGrade.E);
      final gradeEResults = provider.filteredPassports;
      expect(gradeEResults.every((p) => p.recyclabilityGrade == RecyclabilityGrade.E), isTrue);

      // Filter by Material 'Plastic'
      provider.clearFilters();
      provider.setMaterialFilter('Plastic');
      final plasticResults = provider.filteredPassports;
      expect(plasticResults.every((p) => p.primaryMaterial.contains('Plastic')), isTrue);
    });

    test('Add and delete passport operations update list and active passport', () async {
      final newPassport = WastePassportModel(
        id: 'DWP-TEST-DELETE-01',
        itemName: 'Test Delete Item',
        primaryMaterial: 'Glass',
        subType: 'Amber Glass',
        confidenceScore: 0.91,
        recyclabilityGrade: RecyclabilityGrade.B,
        degradationTime: '1M years',
        estimatedCarbonKg: '0.18 kg CO2e',
        materialComposition: {'Glass': 100},
        handlingInstructions: ['Wash clean'],
        circularityGuidance: {
          'reuse': 'Vase',
          'repair': 'N/A',
          'recycle': 'Cullet melting',
          'donate': 'Food bank',
          'return': 'Bottler depot',
          'compost': 'No',
          'safe_disposal': 'Wrap if broken'
        },
        createdAt: DateTime.now(),
      );

      await provider.addPassport(newPassport);
      expect(provider.passports.first.id, 'DWP-TEST-DELETE-01');
      expect(provider.activePassport?.id, 'DWP-TEST-DELETE-01');

      await provider.deletePassport('DWP-TEST-DELETE-01');
      expect(provider.passports.any((p) => p.id == 'DWP-TEST-DELETE-01'), isFalse);
    });
  });
}
