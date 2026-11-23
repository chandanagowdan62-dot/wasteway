import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../passport/presentation/providers/passport_provider.dart';
import '../../../passport/domain/models/waste_passport_model.dart';
import '../../../facilities/presentation/providers/facility_provider.dart';

class CircularityScreen extends StatefulWidget {
  const CircularityScreen({super.key});

  @override
  State<CircularityScreen> createState() => _CircularityScreenState();
}

class _CircularityScreenState extends State<CircularityScreen> {
  String _selectedRFilter = 'All';

  bool _isStepRelevantForMaterial(String keyName, WastePassportModel passport) {
    final mat = passport.primaryMaterial.toLowerCase();
    final sub = passport.subType.toLowerCase();
    final name = passport.itemName.toLowerCase();

    // 1. Used Paper Tissues / Napkins
    if (sub.contains('tissue') || sub.contains('napkin') || name.contains('tissue') || name.contains('napkin')) {
      // Only Compost and Safe Disposal are relevant (no repair, donate, return, or paper mill recycling)
      return keyName == 'compost' || keyName == 'safe_disposal';
    }

    // 2. Multi-Layer / Chips / Snack Packets
    if (mat.contains('multi-layer') || sub.contains('chips') || sub.contains('snack') || sub.contains('wrapper')) {
      // Reuse (eco-bricks), Recycle (cement kiln coprocessing/DWCC), Return (brand collection), Safe Disposal
      return keyName == 'reuse' || keyName == 'recycle' || keyName == 'return' || keyName == 'safe_disposal';
    }

    // 3. Batteries / Hazardous E-Waste
    if (passport.isHazardous || sub.contains('battery') || sub.contains('lithium')) {
      // Return (OEM bins), Recycle (hydrometallurgical), Safe Disposal (tape terminals)
      return keyName == 'return' || keyName == 'recycle' || keyName == 'safe_disposal';
    }

    // 4. Plastic Bottles / Rigid Plastics
    if (mat.contains('plastic') || sub.contains('bottle') || sub.contains('pet')) {
      // Reuse, Recycle, Return, Safe Disposal
      return keyName == 'reuse' || keyName == 'recycle' || keyName == 'return' || keyName == 'safe_disposal';
    }

    // 5. Cardboard & Clean Paper
    if (mat.contains('paper') || mat.contains('cardboard')) {
      // Reuse, Recycle, Donate, Compost, Safe Disposal
      return keyName == 'reuse' ||
          keyName == 'recycle' ||
          keyName == 'donate' ||
          keyName == 'compost' ||
          keyName == 'safe_disposal';
    }

    // 6. Metals & Cans
    if (mat.contains('metal') || mat.contains('can')) {
      // Reuse, Recycle, Return, Safe Disposal
      return keyName == 'reuse' || keyName == 'recycle' || keyName == 'return' || keyName == 'safe_disposal';
    }

    // 7. Glass Jars & Bottles
    if (mat.contains('glass')) {
      // Reuse, Recycle, Donate, Return, Safe Disposal
      return keyName == 'reuse' ||
          keyName == 'recycle' ||
          keyName == 'donate' ||
          keyName == 'return' ||
          keyName == 'safe_disposal';
    }

    // 8. Textiles & Clothing
    if (mat.contains('textile') || mat.contains('fabric') || mat.contains('cloth')) {
      // Donate, Repair, Reuse, Recycle, Safe Disposal
      return keyName == 'donate' ||
          keyName == 'repair' ||
          keyName == 'reuse' ||
          keyName == 'recycle' ||
          keyName == 'safe_disposal';
    }

    // 9. Food & Organic Biomass
    if (mat.contains('organic') || mat.contains('biodegradable') || mat.contains('food')) {
      // Compost, Reuse, Safe Disposal
      return keyName == 'compost' || keyName == 'reuse' || keyName == 'safe_disposal';
    }

    // 10. Medical & Sanitary Waste (Hazardous)
    if (mat.contains('medical') || mat.contains('sanitary') || sub.contains('biomedical') || sub.contains('sanitary')) {
      // Strictly Safe Disposal and Return (take-back bins); never compost or reuse
      return keyName == 'safe_disposal' || keyName == 'return';
    }

    // 11. Furniture & Bulky Goods
    if (mat.contains('furniture') || mat.contains('bulky')) {
      // Donate, Repair, Reuse, Recycle, Safe Disposal
      return keyName == 'donate' ||
          keyName == 'repair' ||
          keyName == 'reuse' ||
          keyName == 'recycle' ||
          keyName == 'safe_disposal';
    }

    // 12. Construction & Demolition Waste
    if (mat.contains('construction') || mat.contains('demolition') || sub.contains('debris') || sub.contains('rubble')) {
      // Reuse (crushed aggregate), Recycle, Safe Disposal
      return keyName == 'reuse' || keyName == 'recycle' || keyName == 'safe_disposal';
    }

    // Default fallback: show Reuse, Recycle, Safe Disposal
    return keyName == 'reuse' || keyName == 'recycle' || keyName == 'safe_disposal';
  }

  @override
  Widget build(BuildContext context) {
    final passportProvider = context.watch<PassportProvider>();
    final passport = passportProvider.activePassport;

    if (passport == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Circularity Guidance (7-Rs)')),
        body: const Center(child: Text('No active passport selected.')),
      );
    }

    final guidance = passport.circularityGuidance;

    final allSteps = [
      _CircularityStep(
        keyName: 'reuse',
        rLabel: '1. Reuse',
        title: 'Domestic & Creative Repurposing',
        description: guidance['reuse'] ??
            'Inspect structural integrity to determine domestic or organizational reuse possibilities before discarding.',
        icon: Icons.replay_outlined,
        color: const Color(0xFF2E7D32),
        priorityBadge: 'Highest Value',
      ),
      _CircularityStep(
        keyName: 'repair',
        rLabel: '2. Repair',
        title: 'Component Maintenance & Life Extension',
        description: guidance['repair'] ??
            'Evaluate repairability, modular parts replacement, or structural reinforcement to avoid replacement.',
        icon: Icons.build_outlined,
        color: const Color(0xFF1565C0),
        priorityBadge: 'Extends Lifespan',
      ),
      _CircularityStep(
        keyName: 'recycle',
        rLabel: '3. Recycle',
        title: 'Material Recovery & Reprocessing',
        description: guidance['recycle'] ??
            'Segregate into dry recyclables stream for secondary pelletization or foundry smelting.',
        icon: Icons.recycling_outlined,
        color: const Color(0xFF00897B),
        priorityBadge: 'Circular Loop',
      ),
      _CircularityStep(
        keyName: 'donate',
        rLabel: '4. Donate',
        title: 'Social Redistribution & Second Life',
        description: guidance['donate'] ??
            'Functional or repairable goods can be offered to local community organizations or informal scrap collectors.',
        icon: Icons.volunteer_activism_outlined,
        color: const Color(0xFF6A1B9A),
        priorityBadge: 'Community Value',
      ),
      _CircularityStep(
        keyName: 'return',
        rLabel: '5. Return',
        title: 'Producer Responsibility (EPR) & Kiosks',
        description: guidance['return'] ??
            'Many consumer brands and retailers operate reverse vending machines or take-back collection kiosks.',
        icon: Icons.assignment_return_outlined,
        color: const Color(0xFFEF6C00),
        priorityBadge: 'Brand Take-Back',
      ),
      _CircularityStep(
        keyName: 'compost',
        rLabel: '6. Compost',
        title: 'Biological Nutrient Loop',
        description: guidance['compost'] ??
            'Assess biodegradable suitability for aerobic home composting or municipal organic treatment.',
        icon: Icons.park_outlined,
        color: const Color(0xFF558B2F),
        priorityBadge: 'Soil Regeneration',
      ),
      _CircularityStep(
        keyName: 'safe_disposal',
        rLabel: '7. Safe Disposal',
        title: 'Safe Household Containment',
        description: guidance['safe_disposal'] ??
            'Ensure toxic or non-recyclable fractions are safely contained to prevent soil and groundwater contamination.',
        icon: Icons.shield_outlined,
        color: AppColors.alertRed,
        priorityBadge: 'Safe Containment',
      ),
    ];

    // Dynamically filter only the circularity steps relevant to this material
    final relevantSteps = allSteps.where((step) => _isStepRelevantForMaterial(step.keyName, passport)).toList();

    final filteredSteps = _selectedRFilter == 'All'
        ? relevantSteps
        : relevantSteps.where((s) => s.keyName == _selectedRFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circularity Guidance (7-Rs)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Material Banner
            EcoCard(
              backgroundColor: const Color(0xFFF1F8E9),
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.change_circle, color: AppColors.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Circularity Matrix: ${passport.itemName}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${passport.primaryMaterial} • ${passport.subType}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: passport.recyclabilityGrade.name,
                    color: passport.recyclabilityGrade.color,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Material-Specific Insight Banner
            if (passport.isHazardous) ...[
              EcoCard(
                backgroundColor: const Color(0xFFFFEBEE),
                border: Border.all(color: AppColors.alertRed),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.alertRed, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Priority for this item: Option 5 (Return) & Option 7 (Safe Disposal). Never allow hazardous elements into common municipal trash.',
                        style: TextStyle(fontSize: 12, color: Colors.brown[900], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (passport.primaryMaterial.toLowerCase().contains('organic') ||
                passport.primaryMaterial.toLowerCase().contains('biodegradable')) ...[
              EcoCard(
                backgroundColor: const Color(0xFFE8F5E9),
                border: Border.all(color: const Color(0xFF81C784)),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Priority for this item: Option 6 (Compost). Diverting wet organic waste from landfills eliminates harmful anaerobic methane emissions.',
                        style: TextStyle(fontSize: 12, color: Colors.green[900], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'Explore Actionable Circular Pathways',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Circularity adheres to a hierarchy: higher options minimize energy loss and carbon impact.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Filter Chips for Relevant Rs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('All Relevant (${relevantSteps.length})'),
                      selected: _selectedRFilter == 'All',
                      selectedColor: AppColors.primaryGreen.withAlpha(35),
                      onSelected: (val) {
                        if (val) setState(() => _selectedRFilter = 'All');
                      },
                    ),
                  ),
                  ...relevantSteps.map((step) {
                    final isSel = _selectedRFilter == step.keyName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(step.rLabel),
                        selected: isSel,
                        selectedColor: step.color.withAlpha(35),
                        onSelected: (val) {
                          setState(() {
                            _selectedRFilter = val ? step.keyName : 'All';
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step List
            if (filteredSteps.isEmpty) ...[
              EcoCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'This circular pathway is not applicable for ${passport.itemName}.',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...filteredSteps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EcoCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: step.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(step.icon, color: step.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  step.rLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: step.color,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: step.color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    step.priorityBadge,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: step.color),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              style: TextStyle(fontSize: 13, color: Colors.grey[850], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            ],
            const SizedBox(height: 16),

            // CTA to Find Local Recyclers
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<FacilityProvider>().setMatchedPassport(passport);
                  context.go(RouteNames.facilities);
                },
                icon: const Icon(Icons.near_me),
                label: Text('Locate Recycling Centers for ${passport.primaryMaterial}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularityStep {
  final String keyName;
  final String rLabel;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String priorityBadge;

  const _CircularityStep({
    required this.keyName,
    required this.rLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.priorityBadge,
  });
}
