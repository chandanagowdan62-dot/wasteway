import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../routes/route_names.dart';

/// Master responsive scaffold shell with StatefulNavigationShell support for GoRouter.
/// Integrates bottom navigation on mobile and navigation rail on web/desktop.
class AppScaffoldShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffoldShell({
    super.key,
    required this.navigationShell,
  });

  void _onTapDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 850;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.recycling,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'WasteWay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (screenWidth >= 380)
                    const Text(
                      'Digital Waste Passport System',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Education quick link
          IconButton(
            tooltip: 'Education & Quizzes',
            icon: const Icon(Icons.school_outlined),
            onPressed: () => context.push(RouteNames.education),
          ),
          // Civic Issue Reporting - Strictly highlighted as secondary workflow
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: screenWidth < 360
                ? IconButton(
                    tooltip: 'Civic Alert',
                    icon: const Icon(Icons.report_problem_outlined, color: AppColors.alertRed),
                    onPressed: () => context.push(RouteNames.civicReports),
                  )
                : OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.civicReports),
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: const Text('Civic Alert'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onTapDestination,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppColors.primaryGreen),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.qr_code_scanner_outlined),
                      selectedIcon: Icon(Icons.qr_code_scanner),
                      label: Text('Scan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment),
                      label: Text('Passports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.location_on_outlined),
                      selectedIcon: Icon(Icons.location_on),
                      label: Text('Recyclers'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTapDestination,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Passports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on),
                  label: 'Recyclers',
                ),
              ],
            ),
    );
  }
}
