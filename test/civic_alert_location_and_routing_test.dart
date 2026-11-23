import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_way/features/civic_reports/domain/models/civic_location_model.dart';
import 'package:waste_way/features/civic_reports/domain/models/civic_report_model.dart';
import 'package:waste_way/features/civic_reports/domain/models/municipal_authority_model.dart';
import 'package:waste_way/features/civic_reports/domain/services/civic_authority_registry.dart';
import 'package:waste_way/features/civic_reports/presentation/providers/civic_report_provider.dart';
import 'package:waste_way/features/civic_reports/presentation/screens/new_report_screen.dart';
import 'package:waste_way/features/civic_reports/presentation/screens/civic_report_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CivicLocationModel & MunicipalAuthorityModel Tests', () {
    test('CivicLocationModel formats coordinates and address summary cleanly', () {
      const loc = CivicLocationModel(
        address: '100 Feet Road, 12th Main',
        locality: 'Indiranagar',
        landmark: 'Near Metro Pillar 84',
        postalCode: '560038',
        city: 'Bengaluru',
        state: 'Karnataka',
        latitude: 12.9784,
        longitude: 77.6408,
        isGpsDetected: true,
      );

      expect(loc.hasCoordinates, isTrue);
      expect(loc.formattedCoordinates, '12.9784° N, 77.6408° E');
      expect(loc.fullDisplayLocation, contains('100 Feet Road'));
      expect(loc.fullDisplayLocation, contains('Indiranagar'));
      expect(loc.fullDisplayLocation, contains('Landmark: Near Metro Pillar 84'));
      expect(loc.fullDisplayLocation, contains('PIN: 560038'));

      // JSON serialization roundtrip
      final json = loc.toJson();
      final fromJson = CivicLocationModel.fromJson(json);
      expect(fromJson.address, loc.address);
      expect(fromJson.postalCode, '560038');
      expect(fromJson.latitude, 12.9784);
      expect(fromJson.isGpsDetected, isTrue);
    });

    test('CivicLocationModel handles manual entry without coordinates gracefully', () {
      const loc = CivicLocationModel(
        address: 'Main Bazaar Road',
        landmark: 'Opposite Clock Tower',
        isGpsDetected: false,
      );

      expect(loc.hasCoordinates, isFalse);
      expect(loc.formattedCoordinates, 'Coordinates not attached');
      expect(loc.fullDisplayLocation, 'Main Bazaar Road, Landmark: Opposite Clock Tower');
    });

    test('MunicipalAuthorityModel for BBMP contains verified official links', () {
      final bbmp = MunicipalAuthorityModel.bbmp(ward: 'Ward 112 - Domlur');
      expect(bbmp.id, 'bbmp');
      expect(bbmp.isVerified, isTrue);
      expect(bbmp.name, contains('Bruhat Bengaluru Mahanagara Palike'));
      expect(bbmp.matchedWard, 'Ward 112 - Domlur');
      expect(bbmp.portalUrl, 'https://bbmpsahaaya.karnataka.gov.in');
      expect(bbmp.helplineNumber, '1533');
      expect(bbmp.helplineAlternate, '080-22660000');
      expect(bbmp.bswmlUrl, 'https://bswml.co.in');

      final json = bbmp.toJson();
      final roundtrip = MunicipalAuthorityModel.fromJson(json);
      expect(roundtrip.id, 'bbmp');
      expect(roundtrip.isVerified, isTrue);
      expect(roundtrip.matchedWard, 'Ward 112 - Domlur');
    });

    test('MunicipalAuthorityModel.unverified routes to Swachhata Urban with isVerified = false', () {
      const loc = CivicLocationModel(
        address: 'Village Chowk',
        city: 'Rural Outskirts',
      );
      final unverified = MunicipalAuthorityModel.unverified(loc);

      expect(unverified.id, 'unverified');
      expect(unverified.isVerified, isFalse);
      expect(unverified.name, 'Authority Unverified');
      expect(unverified.portalUrl, 'https://swachhatah-urban.gov.in');
      expect(unverified.helplineNumber, '1969');
      expect(unverified.matchedWard, isNull);
    });
  });

  group('CivicAuthorityRegistry Resolution Tests', () {
    test('Resolves Bengaluru PIN codes to BBMP with exact wards', () {
      final cases = {
        '560001': 'Ward 110',
        '560003': 'Ward 65',
        '560004': 'Ward 142',
        '560034': 'Ward 151',
        '560038': 'Ward 112',
        '560058': 'Ward 40',
        '560066': 'Ward 84',
        '560076': 'Ward 176',
        '560095': 'Ward 151',
      };

      for (final entry in cases.entries) {
        final loc = CivicLocationModel(
          address: 'Test Street',
          postalCode: entry.key,
          city: 'Bengaluru',
        );
        final auth = CivicAuthorityRegistry.resolveAuthority(loc);

        expect(auth.isVerified, isTrue, reason: 'PIN ${entry.key} should be verified BBMP');
        expect(auth.id, 'bbmp');
        expect(auth.matchedWard, contains(entry.value),
            reason: 'PIN ${entry.key} should map to ward containing ${entry.value}');
      }
    });

    test('Resolves Bengaluru localities to BBMP even if PIN is missing', () {
      const loc = CivicLocationModel(
        address: 'Near Forum Mall',
        locality: 'Koramangala',
        city: 'Bengaluru',
      );
      final auth = CivicAuthorityRegistry.resolveAuthority(loc);

      expect(auth.isVerified, isTrue);
      expect(auth.id, 'bbmp');
      expect(auth.matchedWard, contains('Ward 151 - Koramangala'));
    });

    test('Resolves Bengaluru GPS bounding box to BBMP', () {
      const loc = CivicLocationModel(
        address: 'Somewhere in the city center',
        latitude: 12.9716,
        longitude: 77.5946,
        isGpsDetected: true,
      );
      final auth = CivicAuthorityRegistry.resolveAuthority(loc);

      expect(auth.isVerified, isTrue);
      expect(auth.id, 'bbmp');
    });

    test('Does NOT assign BBMP to outside or unmapped locations (returns unverified)', () {
      const locRural = CivicLocationModel(
        address: 'Highway KM 42, Mandya Bypass',
        postalCode: '571401',
        city: 'Mandya District',
      );
      final authRural = CivicAuthorityRegistry.resolveAuthority(locRural);

      expect(authRural.isVerified, isFalse);
      expect(authRural.id, 'unverified');
      expect(authRural.name, 'Authority Unverified');
      expect(authRural.portalUrl, 'https://swachhatah-urban.gov.in');
      expect(authRural.helplineNumber, '1969');

      const locJaipur = CivicLocationModel(
        address: 'MI Road',
        postalCode: '302001',
        city: 'Jaipur',
        state: 'Rajasthan',
      );
      final authJaipur = CivicAuthorityRegistry.resolveAuthority(locJaipur);
      expect(authJaipur.isVerified, isFalse);
      expect(authJaipur.name, 'Authority Unverified');
    });
  });

  group('Standard Categories and Complaint Preparation Tests', () {
    test('Standardized 8 civic issue categories are defined', () {
      expect(CivicIssueCategories.all.length, 8);
      expect(CivicIssueCategories.all, contains('Illegal Dumping'));
      expect(CivicIssueCategories.all, contains('Garbage Accumulation'));
      expect(CivicIssueCategories.all, contains('Overflowing Public Dustbins'));
      expect(CivicIssueCategories.all, contains('Waste Burning'));
      expect(CivicIssueCategories.all, contains('Public-Space Waste Neglect'));
      expect(CivicIssueCategories.all, contains('Hazardous Waste & Chemical Spills'));
      expect(CivicIssueCategories.all, contains('Clogged Drains / Waterway Litter'));
      expect(CivicIssueCategories.all, contains('Other Sanitation / Waste Issues'));
    });

    test('CivicReportModel retains location, authority, and honest status', () {
      const loc = CivicLocationModel(
        address: '5th Cross, Indiranagar',
        postalCode: '560038',
        city: 'Bengaluru',
      );
      final auth = CivicAuthorityRegistry.resolveAuthority(loc);

      final report = CivicReportModel(
        id: 'CR-2026-TEST',
        title: 'Open Debris Near Park',
        issueCategory: CivicIssueCategories.illegalDumping,
        severity: IssueSeverity.high,
        description: 'Large rubble pile left on sidewalk for over a week.',
        locationAddress: loc.fullDisplayLocation,
        civicLocation: loc,
        municipalAuthority: auth,
        status: ReportStatus.prepared,
        createdAt: DateTime(2026, 11, 22),
      );

      expect(report.status, ReportStatus.prepared);
      expect(report.status.label, 'Prepared in WasteWay');
      expect(report.municipalAuthority?.name, contains('BBMP'));
      expect(report.landmark, contains('Indiranagar'));

      // JSON Roundtrip
      final json = report.toJson();
      final roundtrip = CivicReportModel.fromJson(json);
      expect(roundtrip.id, 'CR-2026-TEST');
      expect(roundtrip.civicLocation?.postalCode, '560038');
      expect(roundtrip.municipalAuthority?.isVerified, isTrue);
      expect(roundtrip.municipalAuthority?.matchedWard, contains('Ward 112'));
    });
  });

  group('CivicReportProvider Handoff & Honest Status Tests', () {
    test('submitReport creates report with resolved authority and status prepared', () async {
      final provider = CivicReportProvider();
      final initialCount = provider.totalCount;

      const loc = CivicLocationModel(
        address: 'Near Whitefield Club',
        locality: 'Whitefield',
        postalCode: '560066',
        city: 'Bengaluru',
      );

      final report = await provider.submitReport(
        title: 'Overflowing Bin at Bus Stop',
        issueCategory: CivicIssueCategories.overflowingDustbins,
        severity: IssueSeverity.moderate,
        description: 'Bin has spilled over onto passenger walkway.',
        locationAddress: loc.fullDisplayLocation,
        civicLocation: loc,
      );

      expect(provider.totalCount, initialCount + 1);
      expect(report.status, ReportStatus.prepared);
      expect(report.municipalAuthority?.isVerified, isTrue);
      expect(report.municipalAuthority?.matchedWard, contains('Ward 84'));
      expect(provider.activeReport?.id, report.id);
    });

    test('markHandoffInitiated transitions status honestly without claiming government submission', () async {
      final provider = CivicReportProvider();
      final report = provider.reports.first;

      await provider.markHandoffInitiated(report.id, 'BBMP Sahaaya 2.0 Web Portal');

      final updated = provider.reports.firstWhere((r) => r.id == report.id);
      expect(updated.status, ReportStatus.handoffInitiated);
      expect(updated.status.label, 'Handoff Initiated');
      expect(updated.officialChannelUsed, 'BBMP Sahaaya 2.0 Web Portal');
      expect(updated.handoffInitiatedAt, isNotNull);
      expect(updated.statusNote, contains('Official handoff initiated'));
    });

    test('recordOfficialSubmission tracks citizen official ticket reference', () async {
      final provider = CivicReportProvider();
      final report = provider.reports.first;

      await provider.recordOfficialSubmission(
        report.id,
        officialReferenceNumber: 'BBMP-SAH-2026-99012',
        channelUsed: 'BBMP Sahaaya 2.0 Web Portal',
      );

      final updated = provider.reports.firstWhere((r) => r.id == report.id);
      expect(updated.status, ReportStatus.acknowledged);
      expect(updated.officialReferenceNumber, 'BBMP-SAH-2026-99012');
      expect(updated.statusNote, contains('BBMP-SAH-2026-99012'));
      expect(updated.officiallySubmittedAt, isNotNull);
    });

    test('Search and filter by authority, ward, and status works correctly', () {
      final provider = CivicReportProvider();

      provider.setSearchQuery('BBMP');
      final bbmpResults = provider.filteredReports;
      expect(bbmpResults.isNotEmpty, isTrue);

      provider.setSearchQuery('');
      provider.setStatusFilter('Prepared');
      final preparedResults = provider.filteredReports;
      expect(preparedResults.every((r) => r.status == ReportStatus.prepared || r.status == ReportStatus.submitted), isTrue);

      provider.clearFilters();
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedStatusFilter, 'All');
    });
  });

  group('Civic Alert Widget Integration Tests', () {
    testWidgets('NewReportScreen renders form with live authority identification', (tester) async {
      final provider = CivicReportProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CivicReportProvider>.value(
            value: provider,
            child: const NewReportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civic Alert Complaint'), findsOneWidget);
      expect(find.text('Issue Title *'), findsOneWidget);
      expect(find.text('Sanitation Issue Category *'), findsOneWidget);
      expect(find.text('Location Details *'), findsOneWidget);
      expect(find.text('Review & Prepare Complaint'), findsOneWidget);

      // Verify live authority card is visible
      expect(find.textContaining('Bruhat Bengaluru Mahanagara Palike'), findsWidgets);
    });

    testWidgets('CivicReportDetailScreen displays authority, routing handoff, and ticket tracker', (tester) async {
      final provider = CivicReportProvider();
      final sampleReport = provider.reports.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CivicReportProvider>.value(
            value: provider,
            child: CivicReportDetailScreen(report: sampleReport),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify report title and authority info
      expect(find.text(sampleReport.title), findsOneWidget);
      expect(find.text('Official Grievance Submission Channels'), findsOneWidget);
      expect(find.text('1. Copy Formatted Grievance Text'), findsOneWidget);
      expect(find.text('Honest Grievance Lifecycle'), findsOneWidget);
    });
  });
}
