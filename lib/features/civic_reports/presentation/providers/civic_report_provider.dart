import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/civic_location_model.dart';
import '../../domain/models/civic_report_model.dart';
import '../../domain/models/municipal_authority_model.dart';
import '../../domain/services/civic_authority_registry.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase/firebase_service_manager.dart';

/// Provider for Module 8: Public-space neglect and illegal-dumping reporting
class CivicReportProvider extends ChangeNotifier {
  final List<CivicReportModel> _reports = [];
  CivicReportModel? _activeReport;

  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedCategoryFilter = 'All';

  List<CivicReportModel> get reports => List.unmodifiable(_reports);
  CivicReportModel? get activeReport => _activeReport;

  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  int get totalCount => _reports.length;
  int get submittedCount => _reports.where((r) => r.status == ReportStatus.submitted || r.status == ReportStatus.prepared).length;
  int get preparedCount => _reports.where((r) => r.status == ReportStatus.prepared || r.status == ReportStatus.submitted).length;
  int get handoffCount => _reports.where((r) => r.status == ReportStatus.handoffInitiated).length;
  int get officiallySubmittedCount => _reports.where((r) => r.status == ReportStatus.officiallySubmitted || r.status == ReportStatus.acknowledged).length;
  int get underReviewCount => _reports.where((r) => r.status == ReportStatus.underReview).length;
  int get resolvedCount => _reports.where((r) => r.status == ReportStatus.resolved).length;
  int get rejectedCount => _reports.where((r) => r.status == ReportStatus.rejected).length;

  /// Filtered list of reports based on search query, status, and category
  List<CivicReportModel> get filteredReports {
    return _reports.where((report) {
      // 1. Status Filter
      if (_selectedStatusFilter != 'All') {
        final filterLower = _selectedStatusFilter.toLowerCase();
        final matchesStatus = report.status.label.toLowerCase() == filterLower ||
            report.status.name.toLowerCase() == filterLower ||
            (_selectedStatusFilter == 'Submitted' && report.status == ReportStatus.prepared) ||
            (_selectedStatusFilter == 'Prepared' && report.status == ReportStatus.submitted);
        if (!matchesStatus) return false;
      }

      // 2. Category Filter
      if (_selectedCategoryFilter != 'All' && report.issueCategory != _selectedCategoryFilter) {
        return false;
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = report.id.toLowerCase().contains(q);
        final matchTitle = report.title.toLowerCase().contains(q);
        final matchCategory = report.issueCategory.toLowerCase().contains(q);
        final matchLocation = report.locationAddress.toLowerCase().contains(q);
        final matchDesc = report.description.toLowerCase().contains(q);
        final matchAuthority = report.municipalAuthority?.name.toLowerCase().contains(q) ?? false;
        final matchWard = report.municipalAuthority?.matchedWard?.toLowerCase().contains(q) ?? false;
        final matchRef = report.officialReferenceNumber?.toLowerCase().contains(q) ?? false;

        if (!matchId &&
            !matchTitle &&
            !matchCategory &&
            !matchLocation &&
            !matchDesc &&
            !matchAuthority &&
            !matchWard &&
            !matchRef) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  CivicReportProvider() {
    _seedDefaultReports();
    _loadPersistedReports();
  }

  void setActiveReport(CivicReportModel? report) {
    _activeReport = report;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatusFilter = 'All';
    _selectedCategoryFilter = 'All';
    notifyListeners();
  }

  /// Submits/Prepares a new civic report, generates a unique ID, and persists it locally
  Future<CivicReportModel> submitReport({
    required String title,
    required String issueCategory,
    required IssueSeverity severity,
    required String description,
    required String locationAddress,
    CivicLocationModel? civicLocation,
    MunicipalAuthorityModel? municipalAuthority,
    double? latitude,
    double? longitude,
    String? imagePath,
    String? imageBase64,
    ReportStatus status = ReportStatus.prepared,
  }) async {
    final effectiveLocation = civicLocation ??
        CivicLocationModel(
          address: locationAddress,
          latitude: latitude,
          longitude: longitude,
          isGpsDetected: latitude != null && longitude != null,
        );

    final effectiveAuthority = municipalAuthority ?? CivicAuthorityRegistry.resolveAuthority(effectiveLocation);

    // Generate unique local report ID: e.g. CR-2026-1051
    final uniqueId = 'CR-2026-${1000 + _reports.length + 1}';

    final newReport = CivicReportModel(
      id: uniqueId,
      title: title,
      issueCategory: issueCategory,
      severity: severity,
      description: description,
      locationAddress: effectiveLocation.fullDisplayLocation,
      latitude: effectiveLocation.latitude ?? latitude,
      longitude: effectiveLocation.longitude ?? longitude,
      status: status,
      statusNote: 'Prepared in WasteWay citizen tracking registry. Ready for official portal handoff.',
      createdAt: DateTime.now(),
      imagePreviewPath: imagePath,
      imageBase64: imageBase64,
      isSampleData: false,
      civicLocation: effectiveLocation,
      municipalAuthority: effectiveAuthority,
    );

    _reports.insert(0, newReport);
    _activeReport = newReport;
    notifyListeners();

    await _persistReports();

    try {
      if (FirebaseServiceManager().isInitialized) {
        await FirebaseServiceManager().database.saveCivicReport(newReport);
      }
    } catch (e) {
      debugPrint('[CivicReportProvider] Cloud sync skipped/fallback: $e');
    }

    return newReport;
  }

  /// Records an official handoff action when the citizen opens an external government channel
  Future<void> markHandoffInitiated(String reportId, String channelUsed) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final current = _reports[index];
      // Do not downgrade if already submitted or acknowledged
      if (current.status == ReportStatus.officiallySubmitted ||
          current.status == ReportStatus.acknowledged ||
          current.status == ReportStatus.resolved) {
        return;
      }

      final updated = current.copyWith(
        status: ReportStatus.handoffInitiated,
        officialChannelUsed: channelUsed,
        handoffInitiatedAt: DateTime.now(),
        statusNote: 'Official handoff initiated via $channelUsed. Complete submission on official channel.',
      );
      _reports[index] = updated;

      if (_activeReport?.id == reportId) {
        _activeReport = updated;
      }

      notifyListeners();
      await _persistReports();
    }
  }

  /// Records that the citizen has officially submitted the complaint on the municipal portal
  Future<void> recordOfficialSubmission(
    String reportId, {
    String? officialReferenceNumber,
    required String channelUsed,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final current = _reports[index];
      final hasRef = officialReferenceNumber != null && officialReferenceNumber.trim().isNotEmpty;
      final newStatus = hasRef ? ReportStatus.acknowledged : ReportStatus.officiallySubmitted;

      final updated = current.copyWith(
        status: newStatus,
        officialReferenceNumber: hasRef ? officialReferenceNumber.trim() : current.officialReferenceNumber,
        officialChannelUsed: channelUsed,
        officiallySubmittedAt: DateTime.now(),
        statusNote: hasRef
            ? 'Officially acknowledged by authority. Official Ref: ${officialReferenceNumber.trim()}'
            : 'Officially submitted by citizen via $channelUsed. Pending authority acknowledgement.',
      );
      _reports[index] = updated;

      if (_activeReport?.id == reportId) {
        _activeReport = updated;
      }

      notifyListeners();
      await _persistReports();
    }
  }

  /// Updates or records the official ticket / grievance reference number entered by user
  Future<void> updateOfficialReference(String reportId, String referenceNumber) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final current = _reports[index];
      final trimmed = referenceNumber.trim();
      final updated = current.copyWith(
        officialReferenceNumber: trimmed.isNotEmpty ? trimmed : null,
        status: trimmed.isNotEmpty ? ReportStatus.acknowledged : current.status,
        statusNote: trimmed.isNotEmpty
            ? 'Official municipal ticket reference attached: $trimmed'
            : current.statusNote,
      );
      _reports[index] = updated;

      if (_activeReport?.id == reportId) {
        _activeReport = updated;
      }

      notifyListeners();
      await _persistReports();
    }
  }

  /// Updates status of an existing report (useful for evaluation / testing demo)
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? statusNote,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final updated = _reports[index].copyWith(
        status: newStatus,
        statusNote: statusNote ?? _getDefaultNoteForStatus(newStatus),
      );
      _reports[index] = updated;

      if (_activeReport?.id == reportId) {
        _activeReport = updated;
      }

      notifyListeners();
      await _persistReports();

      try {
        if (FirebaseServiceManager().isInitialized) {
          await FirebaseServiceManager().database.updateCivicReportStatus(
                reportId,
                newStatus,
                statusNote: statusNote ?? _getDefaultNoteForStatus(newStatus),
              );
        }
      } catch (e) {
        debugPrint('[CivicReportProvider] Cloud update skipped/fallback: $e');
      }
    }
  }

  /// Deletes a report by ID
  Future<void> deleteReport(String reportId) async {
    _reports.removeWhere((r) => r.id == reportId);
    if (_activeReport?.id == reportId) {
      _activeReport = _reports.isNotEmpty ? _reports.first : null;
    }
    notifyListeners();
    await _persistReports();

    try {
      if (FirebaseServiceManager().isInitialized) {
        await FirebaseServiceManager().database.deleteCivicReport(reportId);
      }
    } catch (e) {
      debugPrint('[CivicReportProvider] Cloud delete skipped/fallback: $e');
    }
  }

  String _getDefaultNoteForStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'Draft notice saved locally in WasteWay.';
      case ReportStatus.prepared:
        return 'Prepared in WasteWay citizen tracking registry. Ready for official portal handoff.';
      case ReportStatus.handoffInitiated:
        return 'Citizen opened official municipal channel. Ready to paste details and submit.';
      case ReportStatus.officiallySubmitted:
        return 'Submitted to municipal authority by citizen. Awaiting official reference number.';
      case ReportStatus.acknowledged:
        return 'Officially acknowledged by municipal grievance system.';
      case ReportStatus.submitted:
        return 'Logged in WasteWay citizen tracking registry. Pending community review.';
      case ReportStatus.underReview:
        return 'Verified by community moderator. Recommended for submission to municipal ward desk.';
      case ReportStatus.resolved:
        return 'Issue resolved. Waste cleared by municipal crew or community clean-up.';
      case ReportStatus.rejected:
        return 'Notice rejected. Evidence does not meet public-space neglect criteria or appears duplicate.';
      case ReportStatus.escalated:
        return 'Escalated to local municipal grievance authority with geotagged evidence.';
    }
  }

  Future<void> _persistReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _reports.map((r) => r.toJson()).toList();
      await prefs.setString(AppConstants.keyOfflineReports, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to persist civic reports: $e');
    }
  }

  Future<void> _loadPersistedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedString = prefs.getString(AppConstants.keyOfflineReports);
      if (storedString != null && storedString.isNotEmpty) {
        final decodedList = jsonDecode(storedString) as List;
        if (decodedList.isNotEmpty) {
          _reports.clear();
          for (final item in decodedList) {
            _reports.add(CivicReportModel.fromJson(item as Map<String, dynamic>));
          }
          if (_reports.isNotEmpty) {
            _activeReport = _reports.first;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading saved civic reports: $e');
    }
  }

  void _seedDefaultReports() {
    final loc1 = const CivicLocationModel(
      address: 'Opposite Community Park Gate 3, 5th Main Road, Indiranagar',
      locality: 'Indiranagar',
      landmark: 'Near Gate 3',
      postalCode: '560038',
      city: 'Bengaluru',
      state: 'Karnataka',
      latitude: 12.9730,
      longitude: 77.5980,
      isGpsDetected: true,
    );
    final auth1 = CivicAuthorityRegistry.resolveAuthority(loc1);

    final loc2 = const CivicLocationModel(
      address: 'Near Metro Station Bus Bay, North Entrance, Domlur',
      locality: 'Domlur',
      landmark: 'North Entrance Bus Bay',
      postalCode: '560071',
      city: 'Bengaluru',
      state: 'Karnataka',
      latitude: 12.9610,
      longitude: 77.6380,
      isGpsDetected: false,
    );
    final auth2 = CivicAuthorityRegistry.resolveAuthority(loc2);

    final loc3 = const CivicLocationModel(
      address: 'Behind Industrial Estate Plot 14, Peenya 2nd Stage',
      locality: 'Peenya',
      landmark: 'Plot 14 Service Road',
      postalCode: '560058',
      city: 'Bengaluru',
      state: 'Karnataka',
      latitude: 13.0342,
      longitude: 77.5155,
      isGpsDetected: true,
    );
    final auth3 = CivicAuthorityRegistry.resolveAuthority(loc3);

    final loc4 = const CivicLocationModel(
      address: 'Rural Bypass Junction, Near Old Toll Post',
      locality: 'Village Outskirts',
      landmark: 'Old Toll Post',
      postalCode: '571401',
      city: 'Mandya District',
      state: 'Karnataka',
      latitude: 12.5200,
      longitude: 76.8900,
      isGpsDetected: false,
    );
    final auth4 = CivicAuthorityRegistry.resolveAuthority(loc4);

    _reports.addAll([
      CivicReportModel(
        id: 'CR-2026-1048',
        title: 'Commercial Debris Dumping on Sidewalk',
        issueCategory: CivicIssueCategories.illegalDumping,
        severity: IssueSeverity.high,
        description:
            'Large pile of mixed concrete debris, broken plasterboards and industrial plastic packaging dumped along the pedestrian sidewalk corner.',
        locationAddress: loc1.fullDisplayLocation,
        latitude: loc1.latitude,
        longitude: loc1.longitude,
        status: ReportStatus.prepared,
        statusNote: 'Prepared in WasteWay. Ready for submission on BBMP Sahaaya 2.0 portal.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isSampleData: true,
        civicLocation: loc1,
        municipalAuthority: auth1,
      ),
      CivicReportModel(
        id: 'CR-2026-1021',
        title: 'Secondary Waste Receptacle Overflow',
        issueCategory: CivicIssueCategories.overflowingDustbins,
        severity: IssueSeverity.moderate,
        description:
            'Public secondary steel bin overflowing onto pedestrian path, causing scattered organic litter, plastic waste, and stray animal foraging.',
        locationAddress: loc2.fullDisplayLocation,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
        status: ReportStatus.acknowledged,
        officialReferenceNumber: 'BBMP-SAH-2026-88912',
        officialChannelUsed: 'BBMP Sahaaya 2.0 Web Portal',
        officiallySubmittedAt: DateTime.now().subtract(const Duration(days: 3)),
        statusNote: 'Officially acknowledged by BBMP Sahaaya. Ticket reference #BBMP-SAH-2026-88912.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isSampleData: true,
        civicLocation: loc2,
        municipalAuthority: auth2,
      ),
      CivicReportModel(
        id: 'CR-2026-1014',
        title: 'Discarded Lead-Acid Batteries near Storm Drain',
        issueCategory: CivicIssueCategories.hazardousWaste,
        severity: IssueSeverity.critical,
        description:
            'Two cracked commercial automotive lead-acid batteries abandoned adjacent to open monsoon stormwater drain, risking acid runoff.',
        locationAddress: loc3.fullDisplayLocation,
        latitude: loc3.latitude,
        longitude: loc3.longitude,
        status: ReportStatus.handoffInitiated,
        officialChannelUsed: 'BBMP Control Room Helpline 1533',
        handoffInitiatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        statusNote: 'Handoff initiated via BBMP Control Room 1533. Citizen instructed to quote location details.',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        isSampleData: true,
        civicLocation: loc3,
        municipalAuthority: auth3,
      ),
      CivicReportModel(
        id: 'CR-2026-0995',
        title: 'Roadside Unmanaged Plastic Waste Pile',
        issueCategory: CivicIssueCategories.garbageAccumulation,
        severity: IssueSeverity.moderate,
        description:
            'Unmanaged pile of mixed plastic bottles and food packaging accumulated along rural bypass roadside.',
        locationAddress: loc4.fullDisplayLocation,
        latitude: loc4.latitude,
        longitude: loc4.longitude,
        status: ReportStatus.prepared,
        statusNote: 'Prepared in WasteWay. Authority unverified — routed to Central Swachhata Urban portal.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isSampleData: true,
        civicLocation: loc4,
        municipalAuthority: auth4,
      ),
    ]);
    _activeReport = _reports.first;
    notifyListeners();
  }
}
