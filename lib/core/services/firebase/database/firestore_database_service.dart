import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../features/passport/domain/models/waste_passport_model.dart';
import '../../../../features/civic_reports/domain/models/civic_report_model.dart';
import 'i_cloud_database_service.dart';

/// Live Cloud Firestore database service implementation
class FirestoreDatabaseService implements ICloudDatabaseService {
  final FirebaseFirestore _firestore;

  static const String colPassports = 'waste_passports';
  static const String colCivicReports = 'civic_reports';

  FirestoreDatabaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isCloudConnected => true;

  @override
  Future<void> savePassport(WastePassportModel passport) async {
    try {
      final docRef = _firestore.collection(colPassports).doc(passport.id);
      await docRef.set({
        ...passport.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirestoreDatabaseService] Passport ${passport.id} saved to Cloud Firestore.');
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Failed to save passport to Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<List<WastePassportModel>> fetchPassports({String? userId}) async {
    try {
      Query query = _firestore.collection(colPassports).orderBy('createdAt', descending: true);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WastePassportModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Error fetching passports from Firestore: $e');
      return [];
    }
  }

  @override
  Future<void> deletePassport(String passportId) async {
    try {
      await _firestore.collection(colPassports).doc(passportId).delete();
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Error deleting passport from Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveCivicReport(CivicReportModel report) async {
    try {
      final docRef = _firestore.collection(colCivicReports).doc(report.id);
      await docRef.set({
        ...report.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirestoreDatabaseService] Civic Report ${report.id} saved to Cloud Firestore.');
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Failed to save civic report to Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<List<CivicReportModel>> fetchCivicReports({String? userId}) async {
    try {
      Query query = _firestore.collection(colCivicReports).orderBy('createdAt', descending: true);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CivicReportModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Error fetching civic reports from Firestore: $e');
      return [];
    }
  }

  @override
  Future<void> updateCivicReportStatus(
    String reportId,
    ReportStatus status, {
    String? statusNote,
  }) async {
    try {
      await _firestore.collection(colCivicReports).doc(reportId).update({
        'status': status.name,
        'statusNote': statusNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Error updating civic report status in Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCivicReport(String reportId) async {
    try {
      await _firestore.collection(colCivicReports).doc(reportId).delete();
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] Error deleting civic report from Firestore: $e');
      rethrow;
    }
  }
}
