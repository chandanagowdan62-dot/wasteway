import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wasteway/core/theme/app_theme.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';
import 'package:wasteway/features/passport/presentation/screens/passport_detail_screen.dart';
import 'package:wasteway/features/circularity/presentation/screens/circularity_screen.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/facilities/presentation/screens/facilities_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module 1: AI Waste Image Classification Accuracy Tests', () {
    late MockAIClassificationService mockService;

    setUp(() {
      mockService = MockAIClassificationService();
    });

    test('Tissue images are classified as Paper & Cardboard tissue, NOT plastic bottle', () async {
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'tissue_paper_sample.jpg',
      );

      expect(passport.itemName, contains('Tissue'));
      expect(passport.primaryMaterial, 'Paper & Cardboard');
      expect(passport.subType, contains('Tissue'));
      expect(passport.isHazardous, isFalse);
      expect(passport.primaryMaterial, isNot('Plastic'));
    });

    test('Chips / snack packets are classified as Multi-Layer packaging, NOT lithium battery', () async {
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'lays_chips_packet.jpg',
      );

      expect(passport.itemName, contains('Chips'));
      expect(passport.primaryMaterial, 'Multi-Layer / Composite Materials');
      expect(passport.subType, contains('multilayer or metallised packaging'));
      expect(passport.isHazardous, isFalse);
      expect(passport.primaryMaterial, isNot('Electronic Waste (E-Waste)'));
      expect(passport.subType, isNot(contains('Lithium')));
    });

    test('Batteries are ONLY predicted with explicit battery evidence', () async {
      final batteryPassport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'lithium_battery_cell.jpg',
      );

      expect(batteryPassport.itemName, contains('Cell'));
      expect(batteryPassport.isHazardous, isTrue);

      // Generic camera capture must NEVER silently predict a battery
      final genericCapture = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'image_picker_12345.jpg',
      );

      expect(genericCapture.isHazardous, isFalse);
      expect(genericCapture.primaryMaterial, isNot('Electronic Waste (E-Waste)'));
      expect(genericCapture.isAmbiguous, isTrue);
    });

    test('Mixed municipal packaging waste returns detected items and segregation advice', () async {
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'mixed_trash_sample.jpg',
      );

      expect(passport.isMixedWaste, isTrue);
      expect(passport.detectedItems.isNotEmpty, isTrue);
      expect(passport.segregationAdvice, isNotNull);
      expect(passport.isHazardous, isFalse);
    });
  });

  group('Module 2: Digital Waste Passport Information Tests', () {
    test('Tissues and bottles do not have cathode/anode in material composition', () {
      final tissuePassport = WastePassportModel(
        id: 'DWP-TEST-01',
        itemName: 'Used Paper Tissue',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Cellulose Tissue Fiber',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.D,
        degradationTime: '2 - 4 weeks',
        estimatedCarbonKg: '0.01 kg CO2e',
        materialComposition: {'Cellulose Wood Pulp': 100},
        handlingInstructions: const ['Compost or trash'],
        circularityGuidance: const {'compost': 'Safe'},
        createdAt: DateTime.now(),
      );

      expect(tissuePassport.materialComposition.containsKey('Cathode & Anode Metals'), isFalse);
      expect(tissuePassport.isHazardous, isFalse);
    });

    test('Hazard indicator clearly marks ordinary non-hazardous vs hazardous', () {
      final nonHazardous = WastePassportModel(
        id: 'DWP-TEST-02',
        itemName: 'Water Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET 1',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg',
        materialComposition: const {'PET': 100},
        handlingInstructions: const ['Rinse'],
        circularityGuidance: const {'recycle': 'Dry bin'},
        createdAt: DateTime.now(),
      );

      final hazardous = WastePassportModel(
        id: 'DWP-TEST-03',
        itemName: 'Lithium Cell',
        primaryMaterial: 'Electronic Waste (E-Waste)',
        subType: 'Lithium Secondary Cell',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.E,
        degradationTime: 'Non-biodegradable',
        estimatedCarbonKg: '1.40 kg',
        materialComposition: const {'Cathode & Anode': 60, 'Casing': 40},
        handlingInstructions: const ['Tape terminals'],
        circularityGuidance: const {'safe_disposal': 'Certified depot'},
        createdAt: DateTime.now(),
      );

      expect(nonHazardous.isHazardous, isFalse);
      expect(hazardous.isHazardous, isTrue);
    });

    test('simpleEnvironmentalRelevance returns household plain English', () {
      final tissue = WastePassportModel(
        id: 'DWP-TEST-04',
        itemName: 'Paper Napkin',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Cellulose Tissue Fiber',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.D,
        degradationTime: '2 weeks',
        estimatedCarbonKg: '0.01 kg',
        materialComposition: const {'Pulp': 100},
        handlingInstructions: const ['Dispose cleanly'],
        circularityGuidance: const {},
        createdAt: DateTime.now(),
      );

      final explanation = tissue.simpleEnvironmentalRelevance;
      expect(explanation.contains('decompose'), isTrue);
      expect(explanation.contains('compost'), isTrue);
      expect(explanation.contains('toxic leaching'), isFalse);
    });

    testWidgets('PassportDetailScreen renders Ordinary Non-Hazardous banner for clean items', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final passportProvider = PassportProvider();
      final cleanBottle = WastePassportModel(
        id: 'DWP-TEST-BOTTLE',
        itemName: 'Drinking Water Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET 1',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg',
        materialComposition: const {'PET': 88, 'PP': 12},
        handlingInstructions: const ['Rinse and crush'],
        circularityGuidance: const {'recycle': 'Blue dry-waste bin'},
        createdAt: DateTime.now(),
      );
      passportProvider.setActivePassport(cleanBottle);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: passportProvider),
            ChangeNotifierProvider(create: (_) => FacilityProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PassportDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ordinary Non-Hazardous Waste'), findsOneWidget);
      expect(find.text('Special Hazardous Handling Required'), findsNothing);
      expect(find.text('Household Environmental Impact'), findsOneWidget);
    });
  });

  group('Module 3: Seven Rs Circularity Guidance Relevant-Only Tests', () {
    testWidgets('CircularityScreen dynamically displays only relevant Rs for tissues', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final passportProvider = PassportProvider();
      final tissuePassport = WastePassportModel(
        id: 'DWP-TISSUE-CIRC',
        itemName: 'Used Paper Tissue / Napkin',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Cellulose Tissue Fiber',
        confidenceScore: 0.94,
        recyclabilityGrade: RecyclabilityGrade.D,
        degradationTime: '2 - 4 weeks',
        estimatedCarbonKg: '0.01 kg',
        materialComposition: const {'Cellulose': 100},
        handlingInstructions: const ['Compost or general trash'],
        circularityGuidance: const {
          'reuse': 'Not reusable',
          'repair': 'Not applicable',
          'recycle': 'Non-recyclable in mills',
          'donate': 'Not applicable',
          'return': 'Not applicable',
          'compost': 'Safe to compost in home or community compost.',
          'safe_disposal': 'Wrap and place in standard household waste bin.',
        },
        createdAt: DateTime.now(),
      );
      passportProvider.setActivePassport(tissuePassport);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: passportProvider),
            ChangeNotifierProvider(create: (_) => FacilityProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CircularityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only Compost and Safe Disposal are relevant for used tissues
      expect(find.text('6. Compost'), findsWidgets);
      expect(find.text('7. Safe Disposal'), findsWidgets);

      // Repair and Donate must NOT be shown as actionable pathways for tissues
      expect(find.text('2. Repair'), findsNothing);
      expect(find.text('4. Donate'), findsNothing);
    });
  });

  group('Module 4: Find Recyclers – Authentic Bengaluru Platforms Tests', () {
    late FacilityProvider provider;

    setUp(() {
      provider = FacilityProvider();
    });

    test('All 8 seeded records are authentic Bengaluru services', () {
      final facilities = provider.allFacilities;
      expect(facilities.length, 8);

      final names = facilities.map((f) => f.name).toList();
      expect(names.any((n) => n.contains('Kabadify')), isTrue);
      expect(names.any((n) => n.contains('KabadCart')), isTrue);
      expect(names.any((n) => n.contains('Ecocrew')), isTrue);
      expect(names.any((n) => n.contains('Dclutter')), isTrue);
      expect(names.any((n) => n.contains('Saahas Zero Waste')), isTrue);
      expect(names.any((n) => n.contains('Enviro-Hub')), isTrue);
      expect(names.any((n) => n.contains('Hasiru Dala')), isTrue);
      expect(names.any((n) => n.contains('Goonj')), isTrue);
    });

    test('Distinguishes doorstep platforms from physical drop-off depots', () {
      final facilities = provider.allFacilities;
      final doorstep = facilities.where((f) => f.isDoorstepPlatform).toList();
      final physical = facilities.where((f) => !f.isDoorstepPlatform).toList();

      expect(doorstep.length, 4);
      expect(physical.length, 4);

      // Doorstep platforms must have coverage areas
      for (final d in doorstep) {
        expect(d.coverageArea, isNotNull);
      }

      // Physical facilities must have valid physical addresses
      for (final p in physical) {
        expect(p.address, isNotNull);
        expect(p.hasLocation, isTrue);
      }
    });

    testWidgets('FacilitiesScreen displays tissue educational notice when tissue passport is active',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final facilityProvider = FacilityProvider();
      final tissuePassport = WastePassportModel(
        id: 'DWP-TISSUE-DIR',
        itemName: 'Used Paper Tissue',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Cellulose Tissue Fiber',
        confidenceScore: 0.94,
        recyclabilityGrade: RecyclabilityGrade.D,
        degradationTime: '2 weeks',
        estimatedCarbonKg: '0.01 kg',
        materialComposition: const {'Cellulose': 100},
        handlingInstructions: const ['Compost'],
        circularityGuidance: const {},
        createdAt: DateTime.now(),
      );
      facilityProvider.setMatchedPassport(tissuePassport);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: facilityProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FacilitiesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must display honest tissue notice
      expect(find.text('No Scrap Dealer Buys Used Tissues'), findsOneWidget);
      expect(find.textContaining('cellulose fibers are too short'), findsOneWidget);
    });
  });
}
