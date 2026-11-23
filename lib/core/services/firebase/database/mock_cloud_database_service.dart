import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/passport/domain/models/waste_passport_model.dart';
import '../../../../features/civic_reports/domain/models/civic_report_model.dart';
import 'i_cloud_database_service.dart';

/// Local offline fallback database service using SharedPreferences
class MockCloudDatabaseService implements ICloudDatabaseService {
  @override
  bool get isCloudConnected => false;

  @override
  Future<void> savePassport(WastePassportModel passport) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchPassports();
      existing.removeWhere((p) => p.id == passport.id);
      existing.insert(0, passport);

      final jsonList = existing.map((p) => p.toJson()).toList();
      await prefs.setString(AppConstants.keySavedPassports, jsonEncode(jsonList));
      debugPrint('[MockCloudDatabaseService] Passport ${passport.id} saved to local storage.');
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Failed to save passport: $e');
    }
  }

  @override
  Future<List<WastePassportModel>> fetchPassports({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedString = prefs.getString(AppConstants.keySavedPassports);
      if (storedString != null && storedString.isNotEmpty) {
        final decoded = jsonDecode(storedString) as List;
        return decoded.map((item) => WastePassportModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Error loading passports: $e');
    }
    return [];
  }

  @override
  Future<void> deletePassport(String passportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchPassports();
      existing.removeWhere((p) => p.id == passportId);
      final jsonList = existing.map((p) => p.toJson()).toList();
      await prefs.setString(AppConstants.keySavedPassports, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Error deleting passport: $e');
    }
  }

  @override
  Future<void> saveCivicReport(CivicReportModel report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchCivicReports();
      existing.removeWhere((r) => r.id == report.id);
      existing.insert(0, report);

      final jsonList = existing.map((r) => r.toJson()).toList();
      await prefs.setString(AppConstants.keyOfflineReports, jsonEncode(jsonList));
      debugPrint('[MockCloudDatabaseService] Civic Report ${report.id} saved to local storage.');
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Failed to save civic report: $e');
    }
  }

  @override
  Future<List<CivicReportModel>> fetchCivicReports({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedString = prefs.getString(AppConstants.keyOfflineReports);
      if (storedString != null && storedString.isNotEmpty) {
        final decoded = jsonDecode(storedString) as List;
        return decoded.map((item) => CivicReportModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Error loading civic reports: $e');
    }
    return [];
  }

  @override
  Future<void> updateCivicReportStatus(
    String reportId,
    ReportStatus status, {
    String? statusNote,
  }) async {
    try {
      final existing = await fetchCivicReports();
      final index = existing.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        existing[index] = existing[index].copyWith(
          status: status,
          statusNote: statusNote,
        );
        final prefs = await SharedPreferences.getInstance();
        final jsonList = existing.map((r) => r.toJson()).toList();
        await prefs.setString(AppConstants.keyOfflineReports, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Error updating report status: $e');
    }
  }

  @override
  Future<void> deleteCivicReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await fetchCivicReports();
      existing.removeWhere((r) => r.id == reportId);
      final jsonList = existing.map((r) => r.toJson()).toList();
      await prefs.setString(AppConstants.keyOfflineReports, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[MockCloudDatabaseService] Error deleting civic report: $e');
    }
  }
}
