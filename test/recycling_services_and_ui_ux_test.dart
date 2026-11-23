import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wasteway/core/theme/app_theme.dart';
import 'package:wasteway/features/facilities/domain/models/kabadiwala_service_model.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/facilities/presentation/screens/facilities_screen.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 1: KabadiwalaServiceModel Unit Tests', () {
    test('JSON serialization and deserialization preserves all fields', () {
      const service = KabadiwalaServiceModel(
        id: 'SRV-TEST-01',
        name: 'Test Scrap Platform',
        serviceType: 'Doorstep Scrap Pickup Platform',
        description: 'Test platform for household scrap collection',
        acceptedMaterials: ['Plastic', 'Paper & Cardboard', 'Metals'],
        rejectedMaterials: ['Medical Waste', 'Sanitary Waste'],
        geographicCoverage: 'Pan-Bengaluru',
        operatesInBengaluru: true,
        coverageNotes: 'Active across Bengaluru',
        operatingHours: 'Mon-Sat 9AM-6PM',
        websiteUrl: 'https://testscrap.com',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.testscrap.app',
        appStoreUrl: 'https://apps.apple.com/app/testscrap/id123456789',
        bookingUrl: 'https://testscrap.com/book',
        isVerified: true,
        rating: 4.8,
        sourceReference: 'Verified Test Registry',
        pickupInstructions: ['Sort scrap before pickup'],
      );

      final json = service.toJson();
      final revived = KabadiwalaServiceModel.fromJson(json);

      expect(revived.id, service.id);
      expect(revived.name, service.name);
      expect(revived.serviceType, service.serviceType);
      expect(revived.description, service.description);
      expect(revived.acceptedMaterials.length, 3);
      expect(revived.rejectedMaterials.length, 2);
      expect(revived.geographicCoverage, 'Pan-Bengaluru');
      expect(revived.operatesInBengaluru, isTrue);
      expect(revived.websiteUrl, 'https://testscrap.com');
      expect(revived.playStoreUrl, contains('google.com'));
      expect(revived.appStoreUrl, contains('apple.com'));
      expect(revived.bookingUrl, 'https://testscrap.com/book');
      expect(revived.rating, 4.8);
      expect(revived.hasPlayStore, isTrue);
      expect(revived.hasAppStore, isTrue);
      expect(revived.hasWebsite, isTrue);
      expect(revived.hasBooking, isTrue);
    });

    test('acceptsMaterial respects material acceptance and strict rejection rules', () {
      const service = KabadiwalaServiceModel(
        id: 'SRV-TEST-02',
        name: 'Dry Recyclables Hub',
        serviceType: 'Scrap Aggregator',
        description: 'Dry recyclable scrap collection',
        acceptedMaterials: ['Plastic', 'Paper & Cardboard', 'Metals', 'Electronic Waste (E-Waste)'],
        rejectedMaterials: ['Food Waste', 'Medical & Sanitary Waste', 'Biohazard'],
        geographicCoverage: 'Bengaluru Urban',
        operatesInBengaluru: true,
        sourceReference: 'Registry',
      );

      // Accepted streams
      expect(service.acceptsMaterial('Plastic'), isTrue);
      expect(service.acceptsMaterial('Paper & Cardboard'), isTrue);
      expect(service.acceptsMaterial('Metals'), isTrue);
      expect(service.acceptsMaterial('Electronic Waste (E-Waste)'), isTrue);

      // Explicitly rejected streams
      expect(service.acceptsMaterial('Food Waste'), isFalse);
      expect(service.acceptsMaterial('Medical & Sanitary Waste'), isFalse);
      expect(service.acceptsMaterial('Biohazard'), isFalse);

      // Not accepted stream
      expect(service.acceptsMaterial('Construction & Demolition Waste'), isFalse);
    });

    test('matchesSearch matches by name, service type, coverage, and accepted materials', () {
      const service = KabadiwalaServiceModel(
        id: 'SRV-TEST-03',
        name: 'EcoCollect Doorstep',
        serviceType: 'Smart Doorstep Kabadiwala',
        description: 'Instant cash scrap pickup for households',
        acceptedMaterials: ['Corrugated Boxes', 'PET Bottles', 'Aluminium Cans'],
        geographicCoverage: 'Indiranagar, Bengaluru',
        operatesInBengaluru: true,
        sourceReference: 'Registry',
      );

      expect(service.matchesSearch('EcoCollect'), isTrue);
      expect(service.matchesSearch('kabadiwala'), isTrue);
      expect(service.matchesSearch('indiranagar'), isTrue);
      expect(service.matchesSearch('pet bottles'), isTrue);
      expect(service.matchesSearch('aluminium'), isTrue);
      expect(service.matchesSearch('nonexistent_word'), isFalse);
    });
  });

  group('Part 1: FacilityProvider Kabadiwala Services Integration Tests', () {
    late FacilityProvider provider;

    setUp(() {
      provider = FacilityProvider();
    });

    test('Seeded kabadiwala services contain 6 verified platforms', () {
      final services = provider.kabadiwalaServices;
      expect(services.length, equals(6));

      final names = services.map((s) => s.name).toList();
      expect(names.contains('Kabadify'), isTrue);
      expect(names.contains('KabadCart'), isTrue);
      expect(names.contains('Ecocrew'), isTrue);
      expect(names.contains('ScrapUncle'), isTrue);
      expect(names.contains('The Kabadiwala'), isTrue);
      expect(names.any((n) => n.contains('Recykal')), isTrue);
    });

    test('Bengaluru vs. Regional coverage is strictly disclosed', () {
      final services = provider.kabadiwalaServices;

      // Bengaluru operating services
      final bengaluruServices = services.where((s) => s.operatesInBengaluru).toList();
      expect(bengaluruServices.length, equals(4)); // Kabadify, KabadCart, Ecocrew, Recykal

      // Regional services operating outside Bengaluru
      final regionalServices = services.where((s) => !s.operatesInBengaluru).toList();
      expect(regionalServices.length, equals(2)); // ScrapUncle, The Kabadiwala

      final scrapUncle = services.firstWhere((s) => s.name == 'ScrapUncle');
      expect(scrapUncle.geographicCoverage, contains('Delhi NCR'));
      expect(scrapUncle.operatesInBengaluru, isFalse);
      expect(scrapUncle.coverageNotes, contains('does NOT currently service Bengaluru'));

      final theKabadiwala = services.firstWhere((s) => s.name == 'The Kabadiwala');
      expect(theKabadiwala.geographicCoverage, contains('Central & Western India'));
      expect(theKabadiwala.operatesInBengaluru, isFalse);
      expect(theKabadiwala.coverageNotes, contains('Bengaluru not currently covered'));
    });

    test('All seeded kabadiwala services possess valid HTTPS website URLs and verified references', () {
      for (final service in provider.kabadiwalaServices) {
        expect(service.websiteUrl, isNotNull);
        expect(service.websiteUrl!.startsWith('https://'), isTrue);
        expect(service.sourceReference, isNotNull);
        expect(service.isVerified, isTrue);
      }
    });

    test('Mobile apps have valid Play Store and/or App Store URLs', () {
      final kabadify = provider.kabadiwalaServices.firstWhere((s) => s.name == 'Kabadify');
      expect(kabadify.playStoreUrl, contains('play.google.com/store/apps/details?id='));

      final ecocrew = provider.kabadiwalaServices.firstWhere((s) => s.name == 'Ecocrew');
      expect(ecocrew.playStoreUrl, contains('play.google.com'));
      expect(ecocrew.appStoreUrl, contains('apps.apple.com'));

      final scrapUncle = provider.kabadiwalaServices.firstWhere((s) => s.name == 'ScrapUncle');
      expect(scrapUncle.playStoreUrl, contains('play.google.com'));
      expect(scrapUncle.appStoreUrl, contains('apps.apple.com'));

      final theKabadiwala = provider.kabadiwalaServices.firstWhere((s) => s.name == 'The Kabadiwala');
      expect(theKabadiwala.playStoreUrl, contains('play.google.com'));
      expect(theKabadiwala.appStoreUrl, contains('apps.apple.com'));
    });

    test('Filtering kabadiwala services by Multi-Layer / Composite Materials returns Ecocrew and Recykal', () {
      provider.toggleMaterialFilter('Multi-Layer / Composite Materials');
      final filtered = provider.filteredKabadiwalaServices;

      final names = filtered.map((s) => s.name).toList();
      expect(names.contains('Ecocrew'), isTrue);
      expect(names.any((n) => n.contains('Recykal')), isTrue);
      // ScrapUncle does not specialize in multilayer recycling
      expect(names.contains('ScrapUncle'), isFalse);
    });

    test('Search query matches kabadiwala service name and description', () {
      provider.setSearchQuery('ScrapUncle');
      final filtered = provider.filteredKabadiwalaServices;

      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('ScrapUncle'));
    });

    test('Matched passport filters kabadiwala services appropriately', () {
      final passport = WastePassportModel(
        id: 'DWP-TEST-KAB',
        itemName: 'Old Copper Wire Scrap',
        primaryMaterial: 'Metals',
        subType: 'Copper Scrap',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: 'Indefinite',
        estimatedCarbonKg: '0.12 kg CO2e',
        materialComposition: const {'Copper': 100},
        handlingInstructions: const ['Bundle scrap'],
        circularityGuidance: const {'recycle': 'Authorized kabadiwala'},
        createdAt: DateTime.now(),
      );

      provider.setMatchedPassport(passport);
      final filtered = provider.filteredKabadiwalaServices;

      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.every((s) => s.acceptsMaterial('Metals', 'Copper Scrap')), isTrue);
    });
  });

  group('Part 2: FacilitiesScreen Tab Navigation & UI/UX Tests', () {
    testWidgets('Renders segmented tabs for Drop-off Centres and Kabadiwala Apps', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final facilityProvider = FacilityProvider();

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

      // Title & Disclaimer
      expect(find.text('Recycling & Waste Directory'), findsOneWidget);
      expect(find.textContaining('Informational Directory & Navigation only'), findsOneWidget);

      // Segmented tab selectors
      expect(find.textContaining('Drop-off Centres'), findsOneWidget);
      expect(find.textContaining('Kabadiwala Apps'), findsOneWidget);

      // Initial tab (Tab 0) shows physical & municipal directory facilities
      expect(find.text('Doorstep Platform'), findsWidgets);
      expect(find.text('Official Portal'), findsWidgets);

      // Tap on Kabadiwala Apps tab
      await tester.tap(find.textContaining('Kabadiwala Apps'));
      await tester.pumpAndSettle();

      // Tab 1 shows Doorstep Scrap Collection Platforms advisory
      expect(find.text('Doorstep Scrap Collection Platforms'), findsOneWidget);
      expect(find.textContaining('These independent digital apps and platforms'), findsOneWidget);

      // Kabadiwala Apps cards rendered
      expect(find.text('Kabadify'), findsOneWidget);
      expect(find.text('ScrapUncle'), findsOneWidget);
      expect(find.text('The Kabadiwala'), findsOneWidget);

      // Badges
      expect(find.text('Bengaluru Active'), findsWidgets);
      expect(find.text('Regional Coverage'), findsWidgets);

      // Regional disclosure warning for ScrapUncle / The Kabadiwala
      expect(find.textContaining('does NOT currently service Bengaluru'), findsOneWidget);

      // App buttons
      expect(find.text('Visit Website'), findsWidgets);
      expect(find.text('Get Android App'), findsWidgets);
      expect(find.text('Book Doorstep Pickup'), findsWidgets);
    });

    testWidgets('Screen renders cleanly on narrow screen width (320px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final facilityProvider = FacilityProvider();

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

      // Must render without exception
      expect(find.text('Recycling & Waste Directory'), findsOneWidget);

      // Switch to Kabadiwala Apps
      await tester.tap(find.textContaining('Kabadiwala Apps'));
      await tester.pumpAndSettle();

      // Verify services display on narrow screen
      expect(find.text('Kabadify'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
