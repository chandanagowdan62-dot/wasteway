import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/features/civic_reports/domain/models/civic_report_model.dart';
import 'package:wasteway/features/civic_reports/presentation/providers/civic_report_provider.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_reports_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_report_review_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_report_detail_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/new_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6: CivicReportModel Domain & Serialization Tests', () {
    test('Creates model with all required and optional fields', () {
      final report = CivicReportModel(
        id: 'CR-2026-1099',
        title: 'Commercial Construction Debris on Footpath',
        issueCategory: 'Illegal Dumping',
        severity: IssueSeverity.high,
        description: 'Large pile of broken concrete, tiles, and plaster blocking pedestrian passage.',
        locationAddress: '5th Main, 8th Cross, Rajajinagar',
        latitude: 12.9850,
        longitude: 77.5530,
        status: ReportStatus.submitted,
        statusNote: 'Awaiting volunteer verification.',
        createdAt: DateTime(2026, 4, 15, 10, 30),
        imageBase64: 'dGVzdA==',
        isSampleData: false,
      );

      expect(report.id, 'CR-2026-1099');
      expect(report.title, 'Commercial Construction Debris on Footpath');
      expect(report.issueCategory, 'Illegal Dumping');
      expect(report.severity, IssueSeverity.high);
      expect(report.locationAddress, '5th Main, 8th Cross, Rajajinagar');
      expect(report.landmark, '5th Main, 8th Cross, Rajajinagar'); // Backward compatible alias
      expect(report.latitude, 12.9850);
      expect(report.longitude, 77.5530);
      expect(report.status, ReportStatus.submitted);
      expect(report.statusNote, 'Awaiting volunteer verification.');
      expect(report.isSampleData, isFalse);
    });

    test('Serializes to and from JSON without loss of data', () {
      final original = CivicReportModel(
        id: 'CR-2026-2001',
        title: 'Overflowing Municipal Steel Bin',
        issueCategory: 'Overflowing Public Bins',
        severity: IssueSeverity.moderate,
        description: 'Trash spilling onto street causing foul odor.',
        locationAddress: 'Opposite Metro Pillar 140, Indiranagar',
        latitude: 12.9780,
        longitude: 77.6400,
        status: ReportStatus.underReview,
        statusNote: 'Inspection scheduled with ward health inspector.',
        createdAt: DateTime(2026, 5, 1, 14, 0),
        imageBase64: 'c2FtcGxl',
        isSampleData: true,
      );

      final jsonMap = original.toJson();
      final reconstructed = CivicReportModel.fromJson(jsonMap);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.issueCategory, original.issueCategory);
      expect(reconstructed.severity, original.severity);
      expect(reconstructed.description, original.description);
      expect(reconstructed.locationAddress, original.locationAddress);
      expect(reconstructed.latitude, original.latitude);
      expect(reconstructed.longitude, original.longitude);
      expect(reconstructed.status, original.status);
      expect(reconstructed.statusNote, original.statusNote);
      expect(reconstructed.isSampleData, isTrue);
    });

    test('Handles backward compatible JSON with landmark key', () {
      final legacyJson = {
        'id': 'CR-LEGACY-01',
        'issueCategory': 'Littered Public Spaces',
        'severity': 'low',
        'description': 'Plastic bottles on lawn',
        'landmark': 'Cubbon Park Bamboo Grove',
        'status': 'submitted',
        'createdAt': '2026-03-01T08:00:00.000',
      };

      final parsed = CivicReportModel.fromJson(legacyJson);
      expect(parsed.id, 'CR-LEGACY-01');
      expect(parsed.locationAddress, 'Cubbon Park Bamboo Grove');
      expect(parsed.landmark, 'Cubbon Park Bamboo Grove');
      expect(parsed.title, 'Littered Public Spaces'); // Fallback title
      expect(parsed.severity, IssueSeverity.low);
      expect(parsed.status, ReportStatus.submitted);
    });

    test('copyWith correctly updates specified properties', () {
      final base = CivicReportModel(
        id: 'CR-2026-0001',
        title: 'Initial Title',
        issueCategory: 'Illegal Dumping',
        severity: IssueSeverity.moderate,
        description: 'Initial description',
        locationAddress: 'Initial address',
        status: ReportStatus.submitted,
        createdAt: DateTime.now(),
      );

      final updated = base.copyWith(
        status: ReportStatus.resolved,
        statusNote: 'Cleared by municipal truck.',
      );

      expect(updated.id, base.id);
      expect(updated.title, base.title);
      expect(updated.status, ReportStatus.resolved);
      expect(updated.statusNote, 'Cleared by municipal truck.');
    });

    test('IssueSeverity and ReportStatus extensions provide human-friendly labels and colors', () {
      expect(IssueSeverity.low.label, contains('Low'));
      expect(IssueSeverity.critical.label, contains('Critical'));
      expect(ReportStatus.submitted.label, 'Submitted');
      expect(ReportStatus.underReview.label, 'Under Review');
      expect(ReportStatus.resolved.label, 'Resolved');
      expect(ReportStatus.rejected.label, 'Rejected');
    });
  });

  group('Phase 6: CivicReportProvider State & Lifecycle Tests', () {
    late CivicReportProvider provider;

    setUp(() {
      provider = CivicReportProvider();
    });

    test('Initializes with seeded demo civic reports', () {
      expect(provider.reports.length, greaterThanOrEqualTo(3));
      expect(provider.activeReport, isNotNull);
      expect(provider.totalCount, provider.reports.length);
      expect(provider.submittedCount, greaterThanOrEqualTo(1));
    });

    test('submitReport assigns unique ID, prepends report, and updates activeReport', () async {
      final initialCount = provider.reports.length;

      final newReport = await provider.submitReport(
        title: 'Discarded Chemical Drums',
        issueCategory: 'Hazardous Waste & Chemical Spills',
        severity: IssueSeverity.critical,
        description: 'Two rusted barrels leaking blue chemical dye into storm drain.',
        locationAddress: 'Near Industrial Ring Road Bridge, Peenya',
        latitude: 13.0300,
        longitude: 77.5100,
      );

      expect(newReport.id, startsWith('CR-2026-'));
      expect(provider.reports.length, initialCount + 1);
      expect(provider.reports.first.id, newReport.id);
      expect(provider.activeReport?.id, newReport.id);
      expect(newReport.status, ReportStatus.submitted);
      expect(newReport.isSampleData, isFalse);
    });

    test('updateReportStatus transitions status and updates note', () async {
      final targetReport = provider.reports.first;

      await provider.updateReportStatus(
        targetReport.id,
        ReportStatus.underReview,
        statusNote: 'Verified by community volunteers. Awaiting municipal dispatch.',
      );

      final updated = provider.reports.firstWhere((r) => r.id == targetReport.id);
      expect(updated.status, ReportStatus.underReview);
      expect(updated.statusNote, 'Verified by community volunteers. Awaiting municipal dispatch.');
    });

    test('Search query matches ID, title, category, and location', () {
      provider.clearFilters();
      final initialCount = provider.filteredReports.length;

      // Search by partial ID
      provider.setSearchQuery('1048');
      expect(provider.filteredReports.length, 1);
      expect(provider.filteredReports.first.id, 'CR-2026-1048');

      // Search by category
      provider.setSearchQuery('Overflowing');
      expect(provider.filteredReports.any((r) => r.issueCategory.contains('Overflowing')), isTrue);

      // Search by location landmark
      provider.setSearchQuery('Metro');
      expect(provider.filteredReports.any((r) => r.locationAddress.contains('Metro')), isTrue);

      // Clear search restores all
      provider.setSearchQuery('');
      expect(provider.filteredReports.length, initialCount);
    });

    test('Status filtering filters reports appropriately', () {
      provider.clearFilters();

      provider.setStatusFilter('Resolved');
      for (final report in provider.filteredReports) {
        expect(report.status, ReportStatus.resolved);
      }

      provider.setStatusFilter('Under Review');
      for (final report in provider.filteredReports) {
        expect(report.status, ReportStatus.underReview);
      }

      provider.setStatusFilter('Rejected');
      for (final report in provider.filteredReports) {
        expect(report.status, ReportStatus.rejected);
      }

      provider.setStatusFilter('All');
      expect(provider.filteredReports.length, provider.reports.length);
    });

    test('deleteReport removes report by ID', () async {
      final targetId = provider.reports.first.id;
      final initialCount = provider.reports.length;

      await provider.deleteReport(targetId);

      expect(provider.reports.length, initialCount - 1);
      expect(provider.reports.any((r) => r.id == targetId), isFalse);
    });
  });

  group('Phase 6: Civic Reporting Widget Tests', () {
    testWidgets('CivicReportsScreen renders search bar, filters, list, and guidance', (tester) async {
      final provider = CivicReportProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CivicReportProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CivicReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Explainer banner
      expect(find.textContaining('Public Space Neglect Hub'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Status Filter Chips & Status Badges
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Under Review'), findsWidgets);
      expect(find.text('Resolved'), findsWidgets);
      expect(find.text('Rejected'), findsWidgets);

      // Authority guidance card
      expect(find.textContaining('Municipal Authority Guidance'), findsOneWidget);

      // FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('NewReportScreen renders form fields and validates inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NewReportScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('File a Public Space Neglect Notice'), findsOneWidget);
      expect(find.text('Issue Title *'), findsOneWidget);
      expect(find.text('Issue Category *'), findsOneWidget);
      expect(find.text('Estimated Severity Level *'), findsOneWidget);
      expect(find.text('Location / Landmark / Street Address *'), findsOneWidget);
      expect(find.text('Attach Device GPS Location'), findsOneWidget);
      expect(find.text('Detailed Description *'), findsOneWidget);

      // Tap submit without filling fields
      await tester.ensureVisible(find.text('Review Report Details'));
      await tester.tap(find.text('Review Report Details'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter a descriptive issue title'), findsOneWidget);
      expect(find.text('Please enter the specific location or landmark'), findsOneWidget);
    });

    testWidgets('CivicReportReviewScreen displays draft details and disclaimer', (tester) async {
      final provider = CivicReportProvider();
      const testArgs = CivicReportReviewArgs(
        title: 'Overflowing Park Dumpster',
        issueCategory: 'Overflowing Public Bins',
        severity: IssueSeverity.moderate,
        description: 'Garbage spilling onto lawn near playground area.',
        locationAddress: 'Lalbagh Botanical Gardens West Gate',
        latitude: 12.9500,
        longitude: 77.5850,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CivicReportProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CivicReportReviewScreen(args: testArgs),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Review Your Civic Notice'), findsOneWidget);
      expect(find.text('Overflowing Park Dumpster'), findsOneWidget);
      expect(find.text('Lalbagh Botanical Gardens West Gate'), findsOneWidget);
      expect(find.textContaining('Citizen Guidance & Disclaimer'), findsOneWidget);
      expect(find.text('Confirm & Submit Report'), findsOneWidget);
      expect(find.text('Back to Edit Details'), findsOneWidget);
    });

    testWidgets('CivicReportDetailScreen renders full report, escalation guide, and copy button', (tester) async {
      final provider = CivicReportProvider();
      final sampleReport = provider.reports.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<CivicReportProvider>.value(
          value: provider,
          child: MaterialApp(
            home: CivicReportDetailScreen(report: sampleReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(sampleReport.id), findsWidgets);
      expect(find.text(sampleReport.title), findsOneWidget);
      expect(find.text(sampleReport.locationAddress), findsOneWidget);
      expect(find.textContaining('Official Municipal Escalation Guidance'), findsOneWidget);
      expect(find.text('Copy Grievance Summary for Official Portal'), findsOneWidget);
      expect(find.textContaining('Demo / Viva Simulation Controls'), findsOneWidget);
    });
  });
}
