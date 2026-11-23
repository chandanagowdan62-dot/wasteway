import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/civic_report_provider.dart';

/// Screen displaying submitted civic reports, search/filters, and municipal guidance (Module 8)
class CivicReportsScreen extends StatelessWidget {
  const CivicReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<CivicReportProvider>();
    final reports = reportProvider.filteredReports;

    final filterStatuses = [
      'All',
      'Prepared',
      'Handoff Initiated',
      'Officially Submitted',
      'Acknowledged',
      'Resolved',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Alert Complaints'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.newCivicReport),
        backgroundColor: AppColors.alertRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Report Public Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module 8 Scope Explainer Banner
            EcoCard(
              backgroundColor: const Color(0xFFFFF3E0),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: AppColors.alertRed, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Civic Alert — Public Sanitation Guidance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.brown[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Secondary citizen guidance feature: prepare structured complaints for illegal dumping, overflowing bins, and public litter with photos and mapped municipal routing (BBMP Sahaaya 2.0 / Swachhata Urban).',
                    style: TextStyle(fontSize: 12, color: Colors.brown[800], height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID, title, landmark, authority, or ticket #...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: reportProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => reportProvider.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => reportProvider.setSearchQuery(val),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterStatuses.map((status) {
                  final isSelected = reportProvider.selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: AppColors.alertRed.withAlpha(30),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected ? AppColors.alertRed : Colors.black87,
                      ),
                      onSelected: (selected) {
                        reportProvider.setStatusFilter(selected ? status : 'All');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Section Header with Count
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Prepared Complaints (${reports.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (reportProvider.searchQuery.isNotEmpty || reportProvider.selectedStatusFilter != 'All')
                  TextButton(
                    onPressed: () => reportProvider.clearFilters(),
                    child: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Reports List or Empty State
            if (reports.isEmpty)
              EcoCard(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No complaints found matching your criteria',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try clearing search filters or prepare a new public waste notice.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => reportProvider.clearFilters(),
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...reports.map((report) {
                final auth = report.municipalAuthority;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EcoCard(
                    onTap: () {
                      reportProvider.setActiveReport(report);
                      context.push(RouteNames.civicReportDetail);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ID, Sample tag, and Status Header
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              report.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.secondaryTeal,
                              ),
                            ),
                            if (report.isSampleData)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Sample Notice',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ),
                            StatusBadge(
                              label: report.status.label,
                              color: report.status.color,
                              isFilled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title & Thumbnail Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.issueCategory,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            if (report.imageBase64 != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  base64Decode(report.imageBase64!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Authority and Ward Pill
                        if (auth != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: auth.isVerified ? const Color(0xFFF1F8E9) : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: auth.isVerified ? const Color(0xFFC8E6C9) : const Color(0xFFFFE082),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  auth.isVerified ? Icons.account_balance : Icons.warning_amber_rounded,
                                  size: 13,
                                  color: auth.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    auth.isVerified
                                        ? '${auth.id.toUpperCase()} • ${auth.matchedWard ?? "Jurisdiction Mapped"}'
                                        : 'Authority Unverified • Swachhata Urban',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: auth.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Official Reference Number Pill (if attached)
                        if (report.officialReferenceNumber != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryGreen.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 13, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Ref #: ${report.officialReferenceNumber!}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Description preview
                        Text(
                          report.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),

                        // Location row
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_outlined, size: 14, color: AppColors.alertRed),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.locationAddress,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Severity & Date footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(
                              label: report.severity.label.split(' - ').first,
                              color: report.severity.color,
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(report.createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Authority Guidance & Transparency Disclaimer
            EcoCard(
              backgroundColor: const Color(0xFFF1F8E9),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Municipal Redressal Transparency',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WasteWay is a digital circularity and waste passport platform. WasteWay does not dispatch garbage collection vehicles or directly operate government grievance databases.\n\n'
                    'Each prepared complaint provides a one-tap handoff to official portals (BBMP Sahaaya 2.0 at bbmpsahaaya.karnataka.gov.in, helpline 1533, or MoHUA Swachhata Urban at swachhatah-urban.gov.in).',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[800], height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For life-threatening hazardous or chemical spills, immediately contact your State Disaster Management Authority or local emergency services.',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }
}
