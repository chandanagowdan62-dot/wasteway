import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/services/firebase/firebase_service_manager.dart';
import '../providers/home_provider.dart';
import '../../../passport/presentation/providers/passport_provider.dart';
import '../../../passport/domain/models/waste_passport_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final passportProvider = context.watch<PassportProvider>();
    final recentPassports = passportProvider.passports.take(3).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Cloud Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Circular Economy Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Classify waste, generate digital passports, and find recycling pathways.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const BackendStatusChip(),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics Summary Grid (Clear, honest representation of actual app usage)
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Waste Classified',
                    value: '${passportProvider.passports.isNotEmpty ? passportProvider.passports.length : homeProvider.wasteClassifiedCount}',
                    subtitle: 'Items analyzed',
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.assignment_outlined,
                    label: 'Passports',
                    value: '${passportProvider.passports.length}',
                    subtitle: 'Saved on device',
                    color: AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.change_circle_outlined,
                    label: 'Circularity',
                    value: '${homeProvider.pathwaysAccessedCount}',
                    subtitle: 'Pathways viewed',
                    color: AppColors.accentAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily Eco-Tip Card
            EcoCard(
              backgroundColor: const Color(0xFFF1F8E9),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppColors.primaryGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Daily Circularity Insight',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.primaryGreen),
                        tooltip: 'Next Tip',
                        onPressed: homeProvider.nextDailyTip,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    homeProvider.currentDailyTip,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2E3D30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prominent Hero CTA Card: AI Waste Scanner
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E7E34), Color(0xFF2E7D32), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go(RouteNames.scanner),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan & Identify Waste',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'AI-Powered Digital Waste Passport',
                                    style: TextStyle(
                                      color: Color(0xFFE0F2F1),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upload or capture an image of any waste packaging, container, or electronic item to generate instant circularity guidance, recyclability grade, and local recycler matching.',
                          style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.go(RouteNames.scanner),
                          icon: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF1B5E20)),
                          label: const Text(
                            'Launch Scanner',
                            style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Quick Actions & Exploration
            const Text(
              'Quick Actions & Directory',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: 'Drop-off Hubs',
                    subtitle: 'Local centres & DWCCs',
                    icon: Icons.location_on,
                    color: AppColors.primaryGreen,
                    onTap: () => context.go(RouteNames.facilities),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Kabadiwala Apps',
                    subtitle: 'Doorstep scrap pickup',
                    icon: Icons.phone_android,
                    color: const Color(0xFF0288D1),
                    onTap: () => context.go(RouteNames.facilities),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    title: '7-Rs Guidance',
                    subtitle: 'Circularity engine',
                    icon: Icons.change_circle_outlined,
                    color: const Color(0xFF5D4037),
                    onTap: () => context.push(RouteNames.circularity),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    title: 'Eco Education',
                    subtitle: 'Segregation quiz',
                    icon: Icons.menu_book,
                    color: Colors.indigo,
                    onTap: () => context.push(RouteNames.education),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Digital Waste Passports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Recent Digital Waste Passports',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.passports),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentPassports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No waste items scanned yet. Tap Scan & Classify above!'),
                ),
              )
            else
              ...recentPassports.map((passport) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EcoCard(
                    onTap: () {
                      passportProvider.setActivePassport(passport);
                      context.push(RouteNames.passportDetail);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: passport.recyclabilityGrade.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.eco,
                            color: passport.recyclabilityGrade.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passport.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${passport.primaryMaterial} • ${passport.subType}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: passport.recyclabilityGrade.name,
                          color: passport.recyclabilityGrade.color,
                          icon: Icons.star_border,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Secondary Workflow Banner (Civic Neglect Reporting)
            EcoCard(
              backgroundColor: const Color(0xFFFFF3E0),
              border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.alertRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Public Waste Neglect Alert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBF360C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Report illegal garbage dumps or overflowing civic bins in your locality.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(RouteNames.civicReports),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertRed,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Report'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF37474F)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BackendStatusChip extends StatelessWidget {
  const BackendStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseManager = context.watch<FirebaseServiceManager>();
    final isCloud = firebaseManager.isCloudConnected;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(
              isCloud ? Icons.cloud_done : Icons.cloud_off_outlined,
              color: isCloud ? AppColors.primaryGreen : AppColors.secondaryTeal,
              size: 44,
            ),
            title: Text(isCloud ? 'Firebase Cloud Connected' : 'Local Offline Fallback Mode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCloud
                      ? 'WasteWay is connected to live Cloud Firebase. Waste passports and civic alerts sync across devices in real time.'
                      : 'Your data is saved on this device.\n\nAll Waste Passports, scan history, circularity bookmarks, and Civic Reports are stored locally in secure on-device storage (SharedPreferences). No cloud login or configuration is required.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: ${firebaseManager.statusMessage}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              if (isCloud)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final synced = await firebaseManager.syncLocalDataToCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Synced $synced local items to Cloud Firestore!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Local Data Now'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isCloud ? AppColors.primaryGreen : AppColors.secondaryTeal).withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isCloud ? AppColors.primaryGreen : AppColors.secondaryTeal).withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCloud ? Icons.cloud_done : Icons.cloud_off_outlined,
              size: 14,
              color: isCloud ? AppColors.primaryGreen : AppColors.secondaryTeal,
            ),
            const SizedBox(width: 6),
            Text(
              isCloud ? 'Cloud' : 'Local Storage',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCloud ? AppColors.primaryGreen : AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
