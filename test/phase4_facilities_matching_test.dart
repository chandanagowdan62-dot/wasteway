import 'package:flutter_test/flutter_test.dart';
import 'package:wasteway/features/facilities/domain/models/recycling_facility_model.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';

void main() {
  group('Phase 4: RecyclingFacilityModel Unit Tests', () {
    test('JSON serialization round-trip preservation', () {
      const facility = RecyclingFacilityModel(
        id: 'FAC-TEST-01',
        name: 'Test Polymer Recycling Hub',
        facilityType: FacilityType.recyclingCentre,
        address: '123 Circular Lane',
        latitude: 12.98,
        longitude: 77.60,
        phone: '+91 80 1234 5678',
        email: 'contact@testpoly.org',
        operatingHours: 'Mon-Sat 9AM-6PM',
        acceptedMaterials: ['Plastic', 'PET (Type 1)', 'HDPE (Type 2)'],
        rejectedMaterials: ['PVC', 'Hazardous Waste'],
        dropOffInstructions: ['Rinse before drop-off'],
        isVerified: true,
        isSampleData: true,
        sourceReference: 'Academic Test Registry',
        rating: 4.8,
      );

      final json = facility.toJson();
      final revived = RecyclingFacilityModel.fromJson(json);

      expect(revived.id, facility.id);
      expect(revived.name, facility.name);
      expect(revived.facilityType, FacilityType.recyclingCentre);
      expect(revived.acceptedMaterials.length, 3);
      expect(revived.isSampleData, isTrue);
      expect(revived.sourceReference, 'Academic Test Registry');
    });

    test('acceptsMaterial returns true for accepted and false for rejected materials', () {
      const facility = RecyclingFacilityModel(
        id: 'FAC-TEST-02',
        name: 'Metal & Glass Hub',
        facilityType: FacilityType.scrapDealer,
        acceptedMaterials: ['Metals', 'Aluminium Cans', 'Glass'],
        rejectedMaterials: ['Batteries', 'Hazardous Waste'],
      );

      expect(facility.acceptsMaterial('Metals'), isTrue);
      expect(facility.acceptsMaterial('Aluminium Cans'), isTrue);
      expect(facility.acceptsMaterial('Glass'), isTrue);

      // Explicitly rejected
      expect(facility.acceptsMaterial('Batteries'), isFalse);
      expect(facility.acceptsMaterial('Hazardous Waste'), isFalse);

      // Not in accepted materials
      expect(facility.acceptsMaterial('Plastic'), isFalse);
    });

    test('matchesSearch performs case-insensitive keyword lookup', () {
      const facility = RecyclingFacilityModel(
        id: 'FAC-TEST-03',
        name: 'Eco-System E-Waste Centre',
        facilityType: FacilityType.eWasteCollection,
        address: 'Electronics City Phase 2',
        acceptedMaterials: ['Batteries', 'Circuit Boards'],
      );

      expect(facility.matchesSearch('eco-system'), isTrue);
      expect(facility.matchesSearch('electronics'), isTrue);
      expect(facility.matchesSearch('batteries'), isTrue);
      expect(facility.matchesSearch('nonexistent_word'), isFalse);
    });
  });

  group('Phase 4: FacilityProvider Material Matching & Filtering Tests', () {
    late FacilityProvider provider;

    setUp(() {
      provider = FacilityProvider();
    });

    test('Matches facilities specifically accepting PET Plastic Bottle passport', () {
      final plasticPassport = WastePassportModel(
        id: 'DWP-MATCH-01',
        itemName: 'PET Water Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET (Type 1)',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'PET': 100},
        handlingInstructions: ['Rinse'],
        circularityGuidance: {'recycle': 'Dry bin'},
        createdAt: DateTime.now(),
      );

      provider.setMatchedPassport(plasticPassport);
      final matched = provider.filteredFacilities;

      expect(matched.isNotEmpty, isTrue);
      // All matched facilities must accept Plastic or PET
      expect(
        matched.every((f) => f.acceptsMaterial('Plastic', 'PET (Type 1)')),
        isTrue,
      );
    });

    test('Matches certified E-Waste collection facilities for Li-Ion battery', () {
      final batteryPassport = WastePassportModel(
        id: 'DWP-MATCH-02',
        itemName: 'Lithium Battery Pack',
        primaryMaterial: 'Electronic Waste (E-Waste)',
        subType: 'Lithium-Ion Cell',
        confidenceScore: 0.94,
        recyclabilityGrade: RecyclabilityGrade.E,
        degradationTime: 'Indefinite',
        estimatedCarbonKg: '1.40 kg CO2e',
        materialComposition: {'Lithium': 60, 'Steel': 40},
        handlingInstructions: ['Tape terminals'],
        circularityGuidance: {'safe_disposal': 'Certified depot only'},
        createdAt: DateTime.now(),
      );

      provider.setMatchedPassport(batteryPassport);
      final matched = provider.filteredFacilities;

      expect(matched.isNotEmpty, isTrue);
      expect(
        matched.any((f) => f.facilityType == FacilityType.eWasteCollection),
        isTrue,
      );
      // Ensure organic composting or paper pulping hubs are not recommended for batteries
      expect(
        matched.any((f) => f.facilityType == FacilityType.compostingFacility),
        isFalse,
      );
    });

    test('Returns empty result when filtering by an unhandled or nonexistent material', () {
      provider.setMaterialFilter('Exotic Nonexistent Material 9000');
      final results = provider.filteredFacilities;

      expect(results.isEmpty, isTrue);
    });

    test('Filters by facility type correctly', () {
      provider.setTypeFilter(FacilityType.compostingFacility);
      final compostHubs = provider.filteredFacilities;

      expect(compostHubs.isNotEmpty, isTrue);
      expect(
        compostHubs.every((f) => f.facilityType == FacilityType.compostingFacility),
        isTrue,
      );
    });

    test('Haversine distance calculation is accurate between coordinates', () {
      // Distance between Bangalore center (12.9716, 77.5946) and Electronics City (12.8450, 77.6630)
      final distanceKm = provider.calculateDistanceKm(12.9716, 77.5946, 12.8450, 77.6630);

      // Actual distance is approx 15.8 km
      expect(distanceKm, greaterThan(14.0));
      expect(distanceKm, lessThan(18.0));
    });
  });
}
