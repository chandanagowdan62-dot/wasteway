// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:wasteway/features/scanner/data/data_sources/waste_taxonomy_data.dart';
import 'package:wasteway/features/scanner/data/repositories/waste_taxonomy_repository.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/facilities/domain/models/recycling_facility_model.dart';
import 'package:wasteway/features/civic_reports/presentation/providers/civic_report_provider.dart';
import 'package:wasteway/features/civic_reports/domain/models/civic_report_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/waste_benchmark_dataset.dart';
import 'evaluation/waste_classification_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module 1A & 1B: Waste Taxonomy & Knowledge Base Integrity (100 Items)', () {
    late WasteTaxonomyRepository repo;

    setUp(() {
      repo = WasteTaxonomyRepository();
    });

    test('Taxonomy contains exactly 100 distinct identifiable waste items', () {
      expect(repo.totalItemCount, equals(100));
    });

    test('All 100 taxonomy items possess unique IDs', () {
      final ids = WasteTaxonomyData.items.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, equals(100), reason: 'Duplicate taxonomy IDs found!');
    });

    test('Taxonomy covers all 10 approved main categories with 10 items each', () {
      final expectedCategories = [
        'Plastic',
        'Paper & Cardboard',
        'Glass',
        'Metals',
        'Electronic Waste (E-Waste)',
        'Batteries',
        'Textiles & Fabrics',
        'Biodegradable / Organic',
        'Hazardous Household Waste',
        'Multi-Layer / Composite Materials',
      ];

      for (final cat in expectedCategories) {
        final itemsInCat = repo.getItemsByCategory(cat);
        expect(itemsInCat.length, equals(10),
            reason: 'Category "$cat" does not contain exactly 10 items!');
      }
    });

    test('Every taxonomy item has valid handling guidance, hazard flag, and 7-Rs pathways', () {
      for (final item in WasteTaxonomyData.items) {
        expect(item.commonNames.isNotEmpty, isTrue, reason: '${item.id} has no common names');
        expect(item.description.trim().isNotEmpty, isTrue, reason: '${item.id} has empty description');
        expect(item.distinguishingCharacteristics.trim().isNotEmpty, isTrue);
        expect(item.handlingGuidance.trim().isNotEmpty, isTrue);
        expect(item.suitableCircularityPathways.isNotEmpty, isTrue);
        expect(item.materialCompositionDescription.trim().isNotEmpty, isTrue);
      }
    });

    test('Distinguishes non-hazardous packaging from genuine hazardous items', () {
      final tissue = repo.findById('PAPR-001')!;
      final bottle = repo.findById('PLAS-001')!;
      final chips = repo.findById('CMPL-001')!;
      final battery = repo.findById('BATT-001')!;
      final cleaner = repo.findById('HAZD-001')!;

      // Packaging/tissues are ordinary non-hazardous
      expect(tissue.isHazardous, isFalse);
      expect(bottle.isHazardous, isFalse);
      expect(chips.isHazardous, isFalse);

      // Batteries/chemical cleaners are hazardous
      expect(battery.isHazardous, isTrue);
      expect(cleaner.isHazardous, isTrue);
    });

    test('Material composition descriptions do NOT contain cathode/anode for non-batteries', () {
      final tissue = repo.findById('PAPR-001')!;
      final bottle = repo.findById('PLAS-001')!;
      final cardboard = repo.findById('PAPR-002')!;

      expect(tissue.materialCompositionDescription.toLowerCase().contains('cathode'), isFalse);
      expect(bottle.materialCompositionDescription.toLowerCase().contains('anode'), isFalse);
      expect(cardboard.materialCompositionDescription.toLowerCase().contains('cathode'), isFalse);
    });
  });

  group('Module 1C & 1F: Empirical Classification Benchmark Evaluation', () {
    late WasteClassificationEvaluator evaluator;

    setUp(() {
      evaluator = WasteClassificationEvaluator();
    });

    test('Runs automated benchmark evaluation on 36 dataset samples', () {
      final metrics = evaluator.evaluate(WasteBenchmarkDataset.samples);
      metrics.printSummary();
      if (metrics.errorLogs.isNotEmpty) {
        print('BENCHMARK ERROR LOGS:');
        for (final err in metrics.errorLogs) {
          print('  * $err');
        }
      }

      expect(metrics.totalTested, equals(36));
      expect(metrics.nonWasteRejectionCount, equals(4),
          reason: 'All 4 negative non-waste samples must be rejected');
      expect(metrics.overallAccuracy, greaterThanOrEqualTo(0.80),
          reason: 'Overall accuracy across benchmark dataset must meet or exceed 80%');
      expect(metrics.macroPrecision, greaterThanOrEqualTo(0.80));
      expect(metrics.macroRecall, greaterThanOrEqualTo(0.75));
      expect(metrics.macroF1, greaterThanOrEqualTo(0.75));
    });

    test('Verifies distractor resilience: Tissues are never classified as plastic bottles', () {
      final tissueSample = WasteBenchmarkDataset.samples.firstWhere((s) => s.id == 'EVAL-001');
      final repo = WasteTaxonomyRepository();
      final match = repo.resolveAmbiguity(
        visualClue: tissueSample.visualDescription,
        hasVisibleTerminals: false,
        hasMetallicFoilInterior: false,
        isFibrousAbsorbent: true,
      );

      expect(match.mainCategory, equals('Paper & Cardboard'));
      expect(match.id, equals('PAPR-001'));
      expect(match.id, isNot(equals('PLAS-001')));
    });

    test('Verifies distractor resilience: Chips packets are never classified as lithium batteries', () {
      final chipsSample = WasteBenchmarkDataset.samples.firstWhere((s) => s.id == 'EVAL-010');
      final repo = WasteTaxonomyRepository();
      final match = repo.resolveAmbiguity(
        visualClue: chipsSample.visualDescription,
        hasVisibleTerminals: false,
        hasMetallicFoilInterior: true,
        isFibrousAbsorbent: false,
      );

      expect(match.mainCategory, equals('Multi-Layer / Composite Materials'));
      expect(match.id, equals('CMPL-001'));
      expect(match.mainCategory, isNot(equals('Batteries')));
    });
  });

  group('Module 4: Recycler Directory & Multi-Material Filtering', () {
    late FacilityProvider facilityProvider;

    setUp(() {
      facilityProvider = FacilityProvider();
    });

    test('Initial state: No multi-material filters selected; all facilities returned', () {
      expect(facilityProvider.selectedMaterialFilters.isEmpty, isTrue);
      expect(facilityProvider.filteredFacilities.length, equals(8));
    });

    test('Multi-material selection: Selecting Plastic returns facilities accepting Plastic', () {
      facilityProvider.toggleMaterialFilter('Plastic');
      expect(facilityProvider.selectedMaterialFilters.contains('Plastic'), isTrue);

      final facilities = facilityProvider.filteredFacilities;
      expect(facilities.isNotEmpty, isTrue);
      for (final f in facilities) {
        expect(f.acceptsMaterial('Plastic'), isTrue);
      }
    });

    test('Multi-material selection: Selecting Plastic AND E-Waste matches facilities accepting EITHER', () {
      facilityProvider.toggleMaterialFilter('Plastic');
      facilityProvider.toggleMaterialFilter('Electronic Waste (E-Waste)');

      expect(facilityProvider.selectedMaterialFilters.length, equals(2));
      final facilities = facilityProvider.filteredFacilities;

      for (final f in facilities) {
        final acceptsEither = f.acceptsMaterial('Plastic') || f.acceptsMaterial('Electronic Waste (E-Waste)');
        expect(acceptsEither, isTrue,
            reason: 'Facility ${f.name} does not accept either Plastic or E-Waste');
      }
    });

    test('getAcceptedSelectedMaterials returns only the materials accepted by that specific facility', () {
      facilityProvider.toggleMaterialFilter('Plastic');
      facilityProvider.toggleMaterialFilter('Electronic Waste (E-Waste)');

      // Enviro-Hub is an e-waste recycler: accepts E-Waste, does not accept Plastic
      final enviroHub = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-06');
      final accepted = facilityProvider.getAcceptedSelectedMaterials(enviroHub);

      expect(accepted.contains('Electronic Waste (E-Waste)'), isTrue);
      expect(accepted.contains('Plastic'), isFalse);
    });

    test('Combined filtering: Multi-material filter AND destination-type filter work together', () {
      facilityProvider.toggleMaterialFilter('Plastic');
      facilityProvider.toggleMaterialFilter('Paper & Cardboard');
      facilityProvider.setTypeFilter(FacilityType.eWasteCollection);

      // No e-waste collection point accepts only plastic/paper
      final results = facilityProvider.filteredFacilities;
      expect(results.isEmpty, isTrue);
    });

    test('Clear material filters resets selection cleanly', () {
      facilityProvider.toggleMaterialFilter('Plastic');
      facilityProvider.toggleMaterialFilter('Metals');
      expect(facilityProvider.selectedMaterialFilters.length, equals(2));

      facilityProvider.clearMaterialFilters();
      expect(facilityProvider.selectedMaterialFilters.isEmpty, isTrue);
      expect(facilityProvider.filteredFacilities.length, equals(8));
    });
  });

  group('Module 6: Civic Alert Public Waste Issue Reporting', () {
    late CivicReportProvider civicProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      civicProvider = CivicReportProvider();
    });

    test('Civic report creation and local on-device persistence', () async {
      final report = await civicProvider.submitReport(
        title: 'Overflowing Civic Waste Bin at Domlur',
        issueCategory: 'Overflowing Bin',
        severity: IssueSeverity.moderate,
        description: 'Municipal green bin overflowing onto pedestrian footpath',
        locationAddress: 'Domlur 2nd Stage, Bengaluru',
      );

      expect(report.id.startsWith('CR-'), isTrue);
      expect(report.status, equals(ReportStatus.submitted));
      expect(civicProvider.reports.any((r) => r.id == report.id), isTrue);
    });

    test('Status filtering on civic reports', () async {
      await civicProvider.submitReport(
        title: 'Illegal Plastic Dumping in Indiranagar',
        issueCategory: 'Illegal Dumping',
        severity: IssueSeverity.high,
        description: 'Open vacant plot used for burning plastics',
        locationAddress: '100ft Road, Indiranagar',
      );

      civicProvider.setStatusFilter('Submitted');
      expect(civicProvider.filteredReports.isNotEmpty, isTrue);

      civicProvider.setStatusFilter('Resolved');
      expect(civicProvider.filteredReports.any((r) => r.title.contains('Indiranagar')), isFalse);
    });
  });
}
