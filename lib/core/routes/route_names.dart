/// Centralized route paths and names for GoRouter navigation
class RouteNames {
  RouteNames._();

  // Bottom navigation primary tabs
  static const String home = '/';
  static const String scanner = '/scanner';
  static const String passports = '/passports';
  static const String facilities = '/facilities';

  // Sub-routes & detail screens
  static const String passportDetail = '/passports/detail';
  static const String circularity = '/circularity';
  static const String education = '/education';

  // Secondary, strictly segregated civic reporting workflow (Module 8)
  static const String civicReports = '/civic-reports';
  static const String newCivicReport = '/civic-reports/new';
  static const String reviewCivicReport = '/civic-reports/review';
  static const String civicReportDetail = '/civic-reports/detail';
}
