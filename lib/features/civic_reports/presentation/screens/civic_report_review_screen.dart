import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/civic_report_provider.dart';
import '../../domain/models/civic_location_model.dart';
import '../../domain/models/civic_report_model.dart';
import '../../domain/models/municipal_authority_model.dart';

/// Screen arguments bundle for reviewing a civic report before final preparation
class CivicReportReviewArgs {
  final String title;
  final String issueCategory;
  final IssueSeverity severity;
  final String description;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final Uint8List? imageBytes;
  final CivicLocationModel? civicLocation;
  final MunicipalAuthorityModel? municipalAuthority;

  const CivicReportReviewArgs({
    required this.title,
    required this.issueCategory,
    required this.severity,
    required this.description,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.imageBytes,
    this.civicLocation,
    this.municipalAuthority,
  });
}

/// Screen providing a clear review-before-submit verification step (Module 8)
class CivicReportReviewScreen extends StatefulWidget {
  final CivicReportReviewArgs args;

  const CivicReportReviewScreen({
    super.key,
    required this.args,
  });

  @override
  State<CivicReportReviewScreen> createState() => _CivicReportReviewScreenState();
}

class _CivicReportReviewScreenState extends State<CivicReportReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _handleConfirmSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<CivicReportProvider>();

      String? base64Image;
      if (widget.args.imageBytes != null) {
        base64Image = base64Encode(widget.args.imageBytes!);
      }

      final submitted = await provider.submitReport(
        title: widget.args.title,
        issueCategory: widget.args.issueCategory,
        severity: widget.args.severity,
        description: widget.args.description,
        locationAddress: widget.args.locationAddress,
        civicLocation: widget.args.civicLocation,
        municipalAuthority: widget.args.municipalAuthority,
        latitude: widget.args.latitude,
        longitude: widget.args.longitude,
        imagePath: widget.args.imagePath,
        imageBase64: base64Image,
        status: ReportStatus.prepared,
      );

      if (!mounted) return;

      // Show celebratory confirmation dialog with honest guidance
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 52),
          title: const Text(
            'Complaint Prepared',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WasteWay ID: ${submitted.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTeal,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${submitted.status.label}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Target: ${submitted.municipalAuthority?.name ?? "Municipal Desk"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'WasteWay has prepared your complaint summary with geotagged evidence. Open the official channel handoff to copy details and file directly with the municipal authority.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(RouteNames.civicReports);
              },
              child: const Text('View All Notices'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                provider.setActiveReport(submitted);
                context.push(RouteNames.civicReportDetail, extra: submitted);
              },
              icon: const Icon(Icons.launch, size: 16),
              label: const Text('Official Routing Handoff'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to prepare report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final authority = args.municipalAuthority;
    final location = args.civicLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Civic Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Step 2 of 2: Review & Confirm Preparation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Review Your Complaint Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please verify photographic evidence, severity, location, and mapped municipal authority before saving.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Photographic Evidence Preview (if attached)
            if (args.imageBytes != null) ...[
              EcoCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_back, size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Photographic Evidence',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        args.imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Details Card
            EcoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Category Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              args.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              args.issueCategory,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: args.severity.label.split(' - ').first,
                        color: args.severity.color,
                        isFilled: true,
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Location section
                  const Text(
                    'Reported Location',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.alertRed, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location?.fullDisplayLocation ?? args.locationAddress,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // GPS Coordinates chip
                  if (args.latitude != null && args.longitude != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed, size: 14, color: AppColors.secondaryTeal),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'GPS: ${args.latitude!.toStringAsFixed(4)}° N, ${args.longitude!.toStringAsFixed(4)}° E',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_off, size: 14, color: Colors.grey),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Manual address only (GPS not tagged)',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 24),

                  // Identified Municipal Authority & Ward
                  if (authority != null) ...[
                    Row(
                      children: [
                        Icon(
                          authority.isVerified ? Icons.verified : Icons.help_outline,
                          color: authority.isVerified ? AppColors.primaryGreen : Colors.amber[800],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          authority.isVerified ? 'Municipal Authority Routing' : 'Authority Unverified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: authority.isVerified ? const Color(0xFF2E7D32) : Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authority.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (authority.matchedWard != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        authority.matchedWard!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Official Portal: ${authority.portalUrl}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryTeal),
                    ),
                    Text(
                      'Control Room Helpline: ${authority.helplineNumber}${authority.helplineAlternate != null ? " / ${authority.helplineAlternate}" : ""}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const Divider(height: 24),
                  ],

                  // Description
                  const Text(
                    'Issue Description',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    args.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[850], height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Honest Civic Responsibility Disclaimer
            EcoCard(
              backgroundColor: const Color(0xFFFFF8E1),
              border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.accentAmber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important Official Routing Notice',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.brown[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• WasteWay prepares and structures your complaint for citizen documentation.\n'
                    '• WasteWay does not claim to directly file tickets on government servers.\n'
                    '• On the next screen, use the official-channel handoff tools to copy your prepared complaint and submit via BBMP Sahaaya 2.0, Swachhata Urban, or call 1533.',
                    style: TextStyle(fontSize: 12, color: Colors.brown[800], height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleConfirmSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSubmitting ? 'Preparing Complaint...' : 'Confirm & Save Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Back to Edit Details'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
