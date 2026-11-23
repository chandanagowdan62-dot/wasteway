import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../widgets/app_scaffold_shell.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/passport/presentation/screens/passport_history_screen.dart';
import '../../features/passport/presentation/screens/passport_detail_screen.dart';
import '../../features/circularity/presentation/screens/circularity_screen.dart';
import '../../features/facilities/presentation/screens/facilities_screen.dart';
import '../../features/education/presentation/screens/education_screen.dart';
import '../../features/civic_reports/presentation/screens/civic_reports_screen.dart';
import '../../features/civic_reports/presentation/screens/new_report_screen.dart';
import '../../features/civic_reports/presentation/screens/civic_report_review_screen.dart';
import '../../features/civic_reports/presentation/screens/civic_report_detail_screen.dart';
import '../../features/civic_reports/domain/models/civic_report_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized GoRouter setup for WasteWay
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.home,
    routes: [
      // Primary Application Shell with Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home & Overview
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Scanner & AI Material Classifier
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.scanner,
                builder: (context, state) => const ScannerScreen(),
              ),
            ],
          ),

          // Branch 2: Digital Waste Passports History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.passports,
                builder: (context, state) => const PassportHistoryScreen(),
              ),
            ],
          ),

          // Branch 3: Recycling Facility Directory & Navigation
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.facilities,
                builder: (context, state) => const FacilitiesScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail & Sub-Routes pushed over the shell
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.passportDetail,
        builder: (context, state) => const PassportDetailScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.circularity,
        builder: (context, state) => const CircularityScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.education,
        builder: (context, state) => const EducationScreen(),
      ),

      // Secondary Workflow: Civic Neglect & Dumping Reports (Module 8)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.civicReports,
        builder: (context, state) => const CivicReportsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.newCivicReport,
        builder: (context, state) => const NewReportScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.reviewCivicReport,
        builder: (context, state) {
          final args = state.extra as CivicReportReviewArgs;
          return CivicReportReviewScreen(args: args);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.civicReportDetail,
        builder: (context, state) {
          final model = state.extra as CivicReportModel?;
          return CivicReportDetailScreen(report: model);
        },
      ),
    ],
  );
}
