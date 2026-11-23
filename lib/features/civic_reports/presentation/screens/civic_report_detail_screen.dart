import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/civic_report_provider.dart';
import '../../domain/models/civic_report_model.dart';
import '../../domain/models/municipal_authority_model.dart';

/// Screen displaying comprehensive details, municipal authority routing,
/// official channel handoff, and honest status tracking (Module 8)
class CivicReportDetailScreen extends StatelessWidget {
  final CivicReportModel? report;

  const CivicReportDetailScreen({super.key, this.report});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyOfficialSummary(BuildContext context, CivicReportModel r) {
    final gps = (r.latitude != null && r.longitude != null)
        ? '${r.latitude!.toStringAsFixed(4)}° N, ${r.longitude!.toStringAsFixed(4)}° E'
        : 'Coordinates not attached (Manual Location)';

    final authName = r.municipalAuthority?.name ?? 'Authority Unverified';
    final ward = r.municipalAuthority?.matchedWard ?? 'Ward Unspecified';
    final ref = r.officialReferenceNumber != null ? 'Official Reference #: ${r.officialReferenceNumber}\n' : '';

    final summary = '''
WASTEWAY PUBLIC SANITATION GRIEVANCE SUMMARY
---------------------------------------------
Local Tracking ID: ${r.id}
${ref}Date Prepared: ${DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt)}
Issue Category: ${r.issueCategory}
Estimated Severity: ${r.severity.label}
Title: ${r.title}

TARGET MUNICIPAL JURISDICTION:
- Authority: $authName
- Ward: $ward

LOCATION DETAILS:
- Address: ${r.locationAddress}
- GPS Coordinates: $gps

DETAILED GRIEVANCE DESCRIPTION:
${r.description}

STATUS IN WASTEWAY:
- Lifecycle State: ${r.status.label}
- Status Note: ${r.statusNote ?? 'Prepared for official grievance submission.'}

---------------------------------------------
Prepared via WasteWay Citizen Guidance Platform for direct submission to municipal grievance portals.
''';

    _copyToClipboard(context, summary, 'Formal grievance summary');
  }

  Future<void> _launchExternalUrl(BuildContext context, String urlString, {String? channelName, String? reportId}) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        if (reportId != null && channelName != null && context.mounted) {
          context.read<CivicReportProvider>().markHandoffInitiated(reportId, channelName);
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching official link: $e')),
      );
    }
  }

  Future<void> _callHelpline(BuildContext context, String phoneNumber, {String? channelName, String? reportId}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        if (reportId != null && channelName != null && context.mounted) {
          context.read<CivicReportProvider>().markHandoffInitiated(reportId, channelName);
        }
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dial $phoneNumber')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing call: $e')),
      );
    }
  }

  Future<void> _openLocationMap(BuildContext context, CivicReportModel r) async {
    Uri mapUri;
    if (r.latitude != null && r.longitude != null) {
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}');
    } else {
      final query = Uri.encodeComponent(r.locationAddress);
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map viewer.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: $e')),
      );
    }
  }

  void _showRecordOfficialSubmissionDialog(BuildContext context, CivicReportProvider provider, CivicReportModel r) {
    final refController = TextEditingController(text: r.officialReferenceNumber ?? '');
    String channel = r.officialChannelUsed ?? (r.municipalAuthority?.id == 'bbmp' ? 'BBMP Sahaaya 2.0 Web Portal' : 'Central Swachhata Portal');

    final channels = [
      'BBMP Sahaaya 2.0 Web Portal',
      'BBMP Sahaaya Mobile App',
      'BBMP Control Room Helpline (1533)',
      'MoHUA Swachhata Urban Portal (swachhatah-urban.gov.in)',
      'MoHUA Swachhata Citizen App',
      'Swachhata Helpline (1969)',
      'Other Municipal Portal / Ward Desk',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified_outlined, color: AppColors.primaryGreen, size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('Record Official Submission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record your official grievance submission. If the municipal portal provided an official ticket or reference number, enter it here:',
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      labelText: 'Official Reference / Ticket Number',
                      hintText: 'e.g. BBMP-SAH-2026-88912',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Channel Used for Submission:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: channels.contains(channel) ? channel : channels.first,
                    items: channels.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => channel = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: const Text(
                      'Honesty Guarantee: WasteWay records this locally for your records and does not fabricate government ticket confirmations.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await provider.recordOfficialSubmission(
                    r.id,
                    officialReferenceNumber: refController.text.trim().isNotEmpty ? refController.text.trim() : null,
                    channelUsed: channel,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Save Submission Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, CivicReportProvider provider, CivicReportModel r) {
    ReportStatus selectedStatus = r.status;
    final noteController = TextEditingController(text: r.statusNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Simulate Lifecycle Status (Demo)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a status lifecycle stage to demonstrate in academic evaluation or testing:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...ReportStatus.values.map((status) {
                    return RadioListTile<ReportStatus>(
                      title: Text(status.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: status,
                      groupValue: selectedStatus,
                      activeColor: status.color,
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Status Note / Inspector Remark',
                      hintText: 'e.g. Cleared by municipal team during morning round.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await provider.updateReportStatus(
                    r.id,
                    selectedStatus,
                    statusNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CivicReportProvider>();
    final activeReport = report ?? provider.activeReport;

    if (activeReport == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Civic Report Details')),
        body: const Center(
          child: Text('No report selected. Please return to the Civic Reports Hub.'),
        ),
      );
    }

    final authority = activeReport.municipalAuthority;
    final isBbmp = authority?.id == 'bbmp';

    return Scaffold(
      appBar: AppBar(
        title: Text(activeReport.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy Report ID',
            onPressed: () => _copyToClipboard(context, activeReport.id, 'Report ID'),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Copy Formal Grievance Summary',
            onPressed: () => _copyOfficialSummary(context, activeReport),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activeReport.status.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeReport.status.color.withAlpha(80), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: activeReport.status.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(activeReport.status.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS: ${activeReport.status.label.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: activeReport.status.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeReport.statusNote ?? 'Prepared in WasteWay. Pending official handoff.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[850], height: 1.3),
                        ),
                        if (activeReport.officialReferenceNumber != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 13, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Official Ticket Ref: ${activeReport.officialReferenceNumber}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photographic Evidence Display (if present)
            if (activeReport.imageBase64 != null) ...[
              EcoCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_outlined, size: 16, color: AppColors.primaryGreen),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Geotagged Photographic Evidence',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(activeReport.imageBase64!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Issue Details Card
            EcoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        activeReport.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(activeReport.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    activeReport.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: activeReport.issueCategory,
                        color: AppColors.secondaryTeal,
                        isFilled: true,
                      ),
                      StatusBadge(
                        label: activeReport.severity.label,
                        color: activeReport.severity.color,
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Location
                  const Text(
                    'Location Details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.alertRed),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activeReport.locationAddress,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (activeReport.latitude != null && activeReport.longitude != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GPS: ${activeReport.latitude!.toStringAsFixed(4)}° N, ${activeReport.longitude!.toStringAsFixed(4)}° E',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        )
                      else
                        const Text(
                          'Manual location only (No GPS attached)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      TextButton.icon(
                        onPressed: () => _openLocationMap(context, activeReport),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Open in Maps', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Description
                  const Text(
                    'Complaint Description',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeReport.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[850], height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // IDENTIFIED MUNICIPAL AUTHORITY & WARD CARD
            if (authority != null) ...[
              EcoCard(
                backgroundColor: authority.isVerified ? const Color(0xFFF1F8E9) : const Color(0xFFFFF8E1),
                border: Border.all(
                  color: authority.isVerified ? const Color(0xFF81C784) : const Color(0xFFFFD54F),
                  width: 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          authority.isVerified ? Icons.account_balance : Icons.warning_amber_rounded,
                          color: authority.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authority.isVerified ? 'Responsible Municipal Authority' : 'Authority Unverified',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: authority.isVerified ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: authority.isVerified ? AppColors.primaryGreen.withAlpha(40) : Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            authority.isVerified ? 'VERIFIED' : 'UNVERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: authority.isVerified ? AppColors.primaryGreen : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authority.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    if (authority.matchedWard != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_city, size: 14, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Matched Ward: ${authority.matchedWard!}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Jurisdiction: ${authority.jurisdiction}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      authority.routingInstructions,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // OFFICIAL COMPLAINT ROUTING & HANDOFF (Primary Feature)
            EcoCard(
              backgroundColor: const Color(0xFFE8F5E9),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.open_in_new, color: AppColors.primaryGreen, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Official Grievance Submission Channels',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'WasteWay does not submit tickets to the government automatically. Use the links below to file directly with the official authority:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // 1. Copy Structured Text Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyOfficialSummary(context, activeReport),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('1. Copy Formatted Grievance Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 2. Open Official Web Portal Button
                  if (authority != null && authority.portalUrl.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchExternalUrl(
                          context,
                          authority.portalUrl,
                          channelName: isBbmp ? 'BBMP Sahaaya 2.0 Web Portal' : '${authority.name} Portal',
                          reportId: activeReport.id,
                        ),
                        icon: const Icon(Icons.language, size: 16),
                        label: Text(
                          isBbmp ? '2. Open BBMP Sahaaya 2.0 Portal' : '2. Open Official Portal',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 3. Dial Official Helpline
                  if (authority != null && authority.helplineNumber.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _callHelpline(
                          context,
                          authority.helplineNumber,
                          channelName: '${authority.name} Helpline (${authority.helplineNumber})',
                          reportId: activeReport.id,
                        ),
                        icon: const Icon(Icons.phone_in_talk, size: 16),
                        label: Text(
                          isBbmp ? '3. Call BBMP Control Room (1533)' : '3. Call Helpline (${authority.helplineNumber})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey[900],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 4. Sahaaya App / Swachhata App Link
                  if (authority?.playStoreUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _launchExternalUrl(
                          context,
                          authority!.playStoreUrl!,
                          channelName: isBbmp ? 'BBMP Sahaaya App' : 'Swachhata App',
                          reportId: activeReport.id,
                        ),
                        icon: const Icon(Icons.android, size: 16),
                        label: Text(
                          isBbmp ? 'Open BBMP Sahaaya Citizen App (Play Store)' : 'Open Swachhata Citizen App',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],

                  // 5. BSWML Site (if Bengaluru)
                  if (isBbmp && authority?.bswmlUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _launchExternalUrl(context, authority!.bswmlUrl!),
                        icon: const Icon(Icons.recycling, size: 16),
                        label: const Text('Bangalore Solid Waste Management (BSWML)', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],

                  // 6. Central Swachhata Urban Portal
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _launchExternalUrl(
                        context,
                        'https://swachhatah-urban.gov.in',
                        channelName: 'Central Swachhata Urban Portal',
                        reportId: activeReport.id,
                      ),
                      icon: const Icon(Icons.public, size: 16),
                      label: const Text('Central Swachhata Urban Portal (Helpline 1969)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // RECORD OFFICIAL SUBMISSION & TICKET TRACKER
            EcoCard(
              backgroundColor: const Color(0xFFE0F2F1),
              border: Border.all(color: const Color(0xFF80CBC4), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.secondaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeReport.officialReferenceNumber != null
                              ? 'Official Grievance Confirmed'
                              : 'Have You Filed on the Official Portal?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF004D40),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activeReport.officialReferenceNumber != null) ...[
                    Text(
                      'Official Ticket Reference: ${activeReport.officialReferenceNumber}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF00796B)),
                    ),
                    if (activeReport.officialChannelUsed != null)
                      Text(
                        'Channel: ${activeReport.officialChannelUsed}',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    if (activeReport.officiallySubmittedAt != null)
                      Text(
                        'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(activeReport.officiallySubmittedAt!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showRecordOfficialSubmissionDialog(context, provider, activeReport),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit Official Ticket #', style: TextStyle(fontSize: 12)),
                    ),
                  ] else ...[
                    const Text(
                      'Once you submit this grievance on BBMP Sahaaya or Swachhata, enter your official grievance reference number to track it locally in WasteWay.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF004D40), height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRecordOfficialSubmissionDialog(context, provider, activeReport),
                        icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                        label: const Text('Record Official Ticket / Reference #'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // HONEST STATUS LIFECYCLE TIMELINE
            EcoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Honest Grievance Lifecycle',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'WasteWay distinguishes local preparation from actual official submission:',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  _buildTimelineStage(
                    title: '1. Prepared in WasteWay',
                    subtitle: 'Logged locally on ${DateFormat('dd MMM yyyy, hh:mm a').format(activeReport.createdAt)}',
                    isDone: true,
                    isActive: activeReport.status == ReportStatus.prepared || activeReport.status == ReportStatus.submitted,
                  ),
                  _buildTimelineStage(
                    title: '2. Official Handoff Initiated',
                    subtitle: activeReport.handoffInitiatedAt != null
                        ? 'Initiated via ${activeReport.officialChannelUsed ?? "official channel"} on ${DateFormat('dd MMM, hh:mm a').format(activeReport.handoffInitiatedAt!)}'
                        : 'Citizen opens official portal or helpline',
                    isDone: activeReport.handoffInitiatedAt != null ||
                        activeReport.status == ReportStatus.handoffInitiated ||
                        activeReport.status == ReportStatus.officiallySubmitted ||
                        activeReport.status == ReportStatus.acknowledged ||
                        activeReport.status == ReportStatus.resolved,
                    isActive: activeReport.status == ReportStatus.handoffInitiated,
                  ),
                  _buildTimelineStage(
                    title: '3. Officially Submitted',
                    subtitle: activeReport.officiallySubmittedAt != null
                        ? 'Citizen confirmed submission on official portal'
                        : 'Citizen files grievance on official channel',
                    isDone: activeReport.status == ReportStatus.officiallySubmitted ||
                        activeReport.status == ReportStatus.acknowledged ||
                        activeReport.status == ReportStatus.resolved,
                    isActive: activeReport.status == ReportStatus.officiallySubmitted,
                  ),
                  _buildTimelineStage(
                    title: '4. Acknowledged with Ticket #',
                    subtitle: activeReport.officialReferenceNumber != null
                        ? 'Official Ref: ${activeReport.officialReferenceNumber}'
                        : 'Citizen enters reference number provided by authority',
                    isDone: activeReport.status == ReportStatus.acknowledged ||
                        activeReport.officialReferenceNumber != null ||
                        activeReport.status == ReportStatus.resolved,
                    isActive: activeReport.status == ReportStatus.acknowledged,
                  ),
                  _buildTimelineStage(
                    title: '5. Resolved / Cleaned',
                    subtitle: activeReport.status == ReportStatus.resolved
                        ? (activeReport.statusNote ?? 'Waste cleared by municipal crew')
                        : 'Waste cleared by civic sanitation crew',
                    isDone: activeReport.status == ReportStatus.resolved,
                    isActive: activeReport.status == ReportStatus.resolved,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Demo / Academic Simulation Card
            EcoCard(
              backgroundColor: Colors.grey[50]!,
              border: Border.all(color: Colors.grey[300]!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined, size: 18, color: AppColors.secondaryTeal),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Demo / Viva Simulation Controls',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showStatusUpdateDialog(context, provider, activeReport),
                        child: const Text('Simulate Status', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'For testing and evaluation demonstrations, you can simulate status transitions and inspect listener updates.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStage({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isDone ? AppColors.primaryGreen : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? AppColors.primaryGreen : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.primaryGreen : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
