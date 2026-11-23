import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'civic_location_model.dart';
import 'municipal_authority_model.dart';
import '../services/civic_authority_registry.dart';

/// Severity level of the reported public waste issue
enum IssueSeverity { low, moderate, high, critical }

extension IssueSeverityExt on IssueSeverity {
  String get label {
    switch (this) {
      case IssueSeverity.low:
        return 'Low - Minor Litter';
      case IssueSeverity.moderate:
        return 'Moderate - Overflowing Bin';
      case IssueSeverity.high:
        return 'High - Substantial Illegal Dump';
      case IssueSeverity.critical:
        return 'Critical - Hazardous / Chemical Spill';
    }
  }

  Color get color {
    switch (this) {
      case IssueSeverity.low:
        return AppColors.gradeB;
      case IssueSeverity.moderate:
        return AppColors.accentAmber;
      case IssueSeverity.high:
        return Colors.deepOrange;
      case IssueSeverity.critical:
        return AppColors.alertRed;
    }
  }
}

/// Honest lifecycle status for civic neglect and illegal dumping reports.
///
/// Clearly distinguishes local WasteWay drafting/preparation from actual
/// official handoff, citizen confirmation of official submission, and
/// verified official reference/ticket acknowledgement.
enum ReportStatus {
  draft,
  prepared,
  handoffInitiated,
  officiallySubmitted,
  acknowledged,
  submitted,
  underReview,
  resolved,
  rejected,
  escalated,
}

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.draft:
        return 'Draft Notice';
      case ReportStatus.prepared:
        return 'Prepared in WasteWay';
      case ReportStatus.handoffInitiated:
        return 'Handoff Initiated';
      case ReportStatus.officiallySubmitted:
        return 'Officially Submitted';
      case ReportStatus.acknowledged:
        return 'Acknowledged with Ref #';
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.escalated:
        return 'Escalated to Municipality';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.draft:
        return const Color(0xFF78909C);
      case ReportStatus.prepared:
        return AppColors.primaryGreen;
      case ReportStatus.handoffInitiated:
        return const Color(0xFFE65100);
      case ReportStatus.officiallySubmitted:
        return AppColors.secondaryTeal;
      case ReportStatus.acknowledged:
        return const Color(0xFF2E7D32);
      case ReportStatus.submitted:
        return AppColors.statusSubmitted;
      case ReportStatus.underReview:
        return AppColors.statusUnderReview;
      case ReportStatus.resolved:
        return AppColors.statusResolved;
      case ReportStatus.rejected:
        return const Color(0xFF546E7A);
      case ReportStatus.escalated:
        return AppColors.statusEscalated;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.draft:
        return Icons.edit_note;
      case ReportStatus.prepared:
        return Icons.assignment_turned_in_outlined;
      case ReportStatus.handoffInitiated:
        return Icons.launch_outlined;
      case ReportStatus.officiallySubmitted:
        return Icons.check_circle_outline;
      case ReportStatus.acknowledged:
        return Icons.verified_outlined;
      case ReportStatus.submitted:
        return Icons.send_outlined;
      case ReportStatus.underReview:
        return Icons.search_outlined;
      case ReportStatus.resolved:
        return Icons.task_alt;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
      case ReportStatus.escalated:
        return Icons.campaign_outlined;
    }
  }
}

/// Standardized public waste and sanitation issue categories
class CivicIssueCategories {
  CivicIssueCategories._();

  static const String illegalDumping = 'Illegal Dumping';
  static const String garbageAccumulation = 'Garbage Accumulation';
  static const String overflowingDustbins = 'Overflowing Public Dustbins';
  static const String wasteBurning = 'Waste Burning';
  static const String publicSpaceNeglect = 'Public-Space Waste Neglect';
  static const String hazardousWaste = 'Hazardous Waste & Chemical Spills';
  static const String cloggedDrains = 'Clogged Drains / Waterway Litter';
  static const String otherSanitation = 'Other Sanitation / Waste Issues';

  static const List<String> all = [
    illegalDumping,
    garbageAccumulation,
    overflowingDustbins,
    wasteBurning,
    publicSpaceNeglect,
    hazardousWaste,
    cloggedDrains,
    otherSanitation,
  ];
}

/// Model for Module 8: Public-space neglect and illegal-dumping reporting
class CivicReportModel {
  final String id;
  final String title;
  final String issueCategory;
  final IssueSeverity severity;
  final String description;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final ReportStatus status;
  final String? statusNote;
  final DateTime createdAt;
  final String? imagePreviewPath;
  final String? imageBase64;
  final bool isSampleData;

  // Location & Municipal Authority Details
  final CivicLocationModel? civicLocation;
  final MunicipalAuthorityModel? municipalAuthority;

  // Honest official routing tracking
  final String? officialReferenceNumber;
  final String? officialChannelUsed;
  final DateTime? handoffInitiatedAt;
  final DateTime? officiallySubmittedAt;

  /// Alias for backward compatibility
  String get landmark => civicLocation?.landmark ?? locationAddress;

  const CivicReportModel({
    required this.id,
    required this.title,
    required this.issueCategory,
    required this.severity,
    required this.description,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.status,
    this.statusNote,
    required this.createdAt,
    this.imagePreviewPath,
    this.imageBase64,
    this.isSampleData = false,
    this.civicLocation,
    this.municipalAuthority,
    this.officialReferenceNumber,
    this.officialChannelUsed,
    this.handoffInitiatedAt,
    this.officiallySubmittedAt,
  });

  CivicReportModel copyWith({
    String? id,
    String? title,
    String? issueCategory,
    IssueSeverity? severity,
    String? description,
    String? locationAddress,
    double? latitude,
    double? longitude,
    ReportStatus? status,
    String? statusNote,
    DateTime? createdAt,
    String? imagePreviewPath,
    String? imageBase64,
    bool? isSampleData,
    CivicLocationModel? civicLocation,
    MunicipalAuthorityModel? municipalAuthority,
    String? officialReferenceNumber,
    String? officialChannelUsed,
    DateTime? handoffInitiatedAt,
    DateTime? officiallySubmittedAt,
  }) {
    return CivicReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      issueCategory: issueCategory ?? this.issueCategory,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      statusNote: statusNote ?? this.statusNote,
      createdAt: createdAt ?? this.createdAt,
      imagePreviewPath: imagePreviewPath ?? this.imagePreviewPath,
      imageBase64: imageBase64 ?? this.imageBase64,
      isSampleData: isSampleData ?? this.isSampleData,
      civicLocation: civicLocation ?? this.civicLocation,
      municipalAuthority: municipalAuthority ?? this.municipalAuthority,
      officialReferenceNumber: officialReferenceNumber ?? this.officialReferenceNumber,
      officialChannelUsed: officialChannelUsed ?? this.officialChannelUsed,
      handoffInitiatedAt: handoffInitiatedAt ?? this.handoffInitiatedAt,
      officiallySubmittedAt: officiallySubmittedAt ?? this.officiallySubmittedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'issueCategory': issueCategory,
      'severity': severity.name,
      'description': description,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'statusNote': statusNote,
      'createdAt': createdAt.toIso8601String(),
      'imagePreviewPath': imagePreviewPath,
      'imageBase64': imageBase64,
      'isSampleData': isSampleData,
      'civicLocation': civicLocation?.toJson(),
      'municipalAuthority': municipalAuthority?.toJson(),
      'officialReferenceNumber': officialReferenceNumber,
      'officialChannelUsed': officialChannelUsed,
      'handoffInitiatedAt': handoffInitiatedAt?.toIso8601String(),
      'officiallySubmittedAt': officiallySubmittedAt?.toIso8601String(),
    };
  }

  factory CivicReportModel.fromJson(Map<String, dynamic> json) {
    final address = json['locationAddress'] as String? ?? json['landmark'] as String? ?? 'Unknown Location';
    final parsedTitle = json['title'] as String? ?? json['issueCategory'] as String? ?? 'Civic Waste Notice';

    IssueSeverity parsedSeverity = IssueSeverity.moderate;
    if (json['severity'] != null) {
      try {
        parsedSeverity = IssueSeverity.values.byName(json['severity'] as String);
      } catch (_) {
        parsedSeverity = IssueSeverity.moderate;
      }
    }

    ReportStatus parsedStatus = ReportStatus.submitted;
    if (json['status'] != null) {
      try {
        parsedStatus = ReportStatus.values.byName(json['status'] as String);
      } catch (_) {
        parsedStatus = ReportStatus.submitted;
      }
    }

    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();

    CivicLocationModel? location;
    if (json['civicLocation'] != null) {
      location = CivicLocationModel.fromJson(json['civicLocation'] as Map<String, dynamic>);
    } else {
      location = CivicLocationModel(
        address: address,
        latitude: lat,
        longitude: lng,
        isGpsDetected: lat != null && lng != null,
      );
    }

    MunicipalAuthorityModel? authority;
    if (json['municipalAuthority'] != null) {
      authority = MunicipalAuthorityModel.fromJson(json['municipalAuthority'] as Map<String, dynamic>);
    } else {
      authority = CivicAuthorityRegistry.resolveAuthority(location);
    }

    return CivicReportModel(
      id: json['id'] as String? ?? 'CR-UNKNOWN',
      title: parsedTitle,
      issueCategory: json['issueCategory'] as String? ?? 'Illegal Dumping',
      severity: parsedSeverity,
      description: json['description'] as String? ?? '',
      locationAddress: address,
      latitude: lat,
      longitude: lng,
      status: parsedStatus,
      statusNote: json['statusNote'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePreviewPath: json['imagePreviewPath'] as String?,
      imageBase64: json['imageBase64'] as String?,
      isSampleData: json['isSampleData'] as bool? ?? false,
      civicLocation: location,
      municipalAuthority: authority,
      officialReferenceNumber: json['officialReferenceNumber'] as String?,
      officialChannelUsed: json['officialChannelUsed'] as String?,
      handoffInitiatedAt: json['handoffInitiatedAt'] != null
          ? DateTime.tryParse(json['handoffInitiatedAt'] as String)
          : null,
      officiallySubmittedAt: json['officiallySubmittedAt'] != null
          ? DateTime.tryParse(json['officiallySubmittedAt'] as String)
          : null,
    );
  }
}
