import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:wasteway/features/scanner/data/services/mock_waste_sample_image.dart';
import 'package:wasteway/features/scanner/domain/services/image_processing_service.dart';
import 'package:wasteway/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';
import 'package:wasteway/features/civic_reports/presentation/providers/civic_report_provider.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_reports_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_report_detail_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/new_report_screen.dart';
import 'package:wasteway/features/civic_reports/presentation/screens/civic_report_review_screen.dart';
import 'package:wasteway/features/civic_reports/domain/models/civic_report_model.dart';
import 'package:wasteway/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:wasteway/core/theme/app_theme.dart';

void main() {
  group('Phase 8 Stage 2: Mock Waste Sample Image Codec Tests', () {
    test('Generates valid JPEG bytes for all mock sample items', () {
      final samples = ['bottle.jpg', 'battery.jpg', 'soda_can.jpg', 'shipping_box.jpg'];

      for (final sample in samples) {
        final bytes = MockWasteSampleImage.getSampleImageBytes(sample);
        expect(bytes.isNotEmpty, true);

        // Verify valid image header (SOI 0xFFD8 for JPEG)
        expect(bytes[0], 0xFF);
        expect(bytes[1], 0xD8);

        // Verify package:image can decode it
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        expect(decoded?.width, 320);
        expect(decoded?.height, 240);
      }
    });

    test('ImageProcessingService successfully optimizes mock sample image without codec error', () async {
      final service = ImageProcessingService();
      final sampleBytes = MockWasteSampleImage.getSampleImageBytes('bottle.jpg');

      final result = await service.preprocessImage(
        rawBytes: sampleBytes,
        maxDimension: 1024,
        quality: 80,
      );

      expect(result.processedBytes.isNotEmpty, true);
      expect(result.width, lessThanOrEqualTo(1024));
      expect(result.height, lessThanOrEqualTo(1024));
    });
  });

  group('Phase 8 Stage 2: Responsive Narrow Viewport Layout Tests (320px & 360px)', () {
    Widget buildTestHarness(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScannerProvider()),
          ChangeNotifierProvider(create: (_) => PassportProvider()),
          ChangeNotifierProvider(create: (_) => CivicReportProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('CivicReportsScreen renders cleanly without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(const CivicReportsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Public Space Neglect Hub (Module 8)'), findsOneWidget);
      expect(find.byType(CivicReportsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NewReportScreen renders cleanly without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(const NewReportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('File a Public Space Neglect Notice'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CivicReportDetailScreen renders cleanly without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(const CivicReportDetailScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Official Municipal Escalation Guidance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CivicReportReviewScreen renders cleanly without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const reviewArgs = CivicReportReviewArgs(
        title: 'Overturned Metal Bin on Pathway',
        issueCategory: 'Overflowing Public Bins',
        severity: IssueSeverity.moderate,
        description: 'Large commercial bin fallen over with debris strewn across the pedestrian path.',
        locationAddress: 'Opposite Community Park Gate 3, 5th Main Road',
      );

      await tester.pumpWidget(buildTestHarness(const CivicReportReviewScreen(args: reviewArgs)));
      await tester.pumpAndSettle();

      expect(find.text('Review Your Civic Notice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ScannerScreen error state buttons wrap cleanly without overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scannerProvider = ScannerProvider();
      scannerProvider.setError('Test error for overflow verification');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: scannerProvider),
            ChangeNotifierProvider(create: (_) => PassportProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry Analysis'), findsOneWidget);
      expect(find.text('Update API Key'), findsOneWidget);
      expect(find.text('Run Offline Simulation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
