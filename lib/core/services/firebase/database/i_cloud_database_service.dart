import '../../../../features/passport/domain/models/waste_passport_model.dart';
import '../../../../features/civic_reports/domain/models/civic_report_model.dart';

/// Abstract contract for cloud and local database persistence in WasteWay
abstract class ICloudDatabaseService {
  bool get isCloudConnected;

  // Waste Passports
  Future<void> savePassport(WastePassportModel passport);
  Future<List<WastePassportModel>> fetchPassports({String? userId});
  Future<void> deletePassport(String passportId);

  // Civic Reports (Module 8)
  Future<void> saveCivicReport(CivicReportModel report);
  Future<List<CivicReportModel>> fetchCivicReports({String? userId});
  Future<void> updateCivicReportStatus(String reportId, ReportStatus status, {String? statusNote});
  Future<void> deleteCivicReport(String reportId);
}
