/// Global application constants for WasteWay
class AppConstants {
  AppConstants._();

  static const String appName = 'WasteWay';
  static const String appTagline = 'Digital Waste Passport & Circularity Guidance';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyOfflineReports = 'wasteway_offline_reports';
  static const String keySavedPassports = 'wasteway_saved_passports';
  static const String keyUserPreferences = 'wasteway_user_preferences';

  // AI Configuration defaults
  static const String defaultGeminiModel = 'gemini-3.8-flash';
  static const int maxImageDimension = 1024;
  static const int imageQuality = 80;
  static const int maxUploadSizeBytes = 500 * 1024; // 500 KB limit
}
