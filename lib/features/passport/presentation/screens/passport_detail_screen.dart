import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/passport_provider.dart';
import '../../domain/models/waste_passport_model.dart';
import '../../../facilities/presentation/providers/facility_provider.dart';

class PassportDetailScreen extends StatefulWidget {
  const PassportDetailScreen({super.key});

  @override
  State<PassportDetailScreen> createState() => _PassportDetailScreenState();
}

class _PassportDetailScreenState extends State<PassportDetailScreen> {
  final Set<int> _checkedSteps = {};

  void _showManualSubtypeDialog(
    BuildContext context,
    PassportProvider provider,
    WastePassportModel passport,
  ) {
    final controller = TextEditingController(text: passport.subType);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Material Subtype'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the verified resin type, metal alloy, or material label found on the item (e.g. "HDPE (Type 2)", "PP (Type 5)", "PET (Type 1)", "Cotton 100%"):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Material Subtype',
                hintText: 'e.g. Polypropylene (PP Type 5)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                provider.updatePassportMaterial(
                  passportId: passport.id,
                  newSubType: text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated material subtype to "$text".')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(WastePassportModel passport) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              passport.isSimulated ? Icons.science_outlined : Icons.qr_code,
              color: passport.isSimulated ? const Color(0xFFE65100) : AppColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(passport.id),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: passport.isSimulated ? const Color(0xFFFFB300) : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    passport.isSimulated ? Icons.science_outlined : Icons.qr_code_2,
                    size: 140,
                    color: passport.isSimulated ? const Color(0xFFE65100) : Colors.black87,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    passport.passportSignature,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              passport.isSimulated ? 'Simulation Demonstration Record' : 'Verified Circular Product Record',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: passport.isSimulated ? const Color(0xFFE65100) : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              passport.isSimulated
                  ? 'Sample demonstration passport generated offline. Not verified by live AI classification.'
                  : 'Scannable by municipal recyclers, scrap depots, and circular logistics partners.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passportProvider = context.watch<PassportProvider>();
    final passport = passportProvider.activePassport;

    if (passport == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Waste Passport')),
        body: const Center(child: Text('No active passport found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Waste Passport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Verify Passport Signature',
            onPressed: () => _showVerificationDialog(passport),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Passport',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Passport record for ${passport.itemName} (${passport.id}) copied!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Simulation / Demo Record Banner
            if (passport.isSimulated) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Simulation / Demo Record',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFE65100)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            passport.simulationNotice ??
                                'Generated via offline simulation engine for demonstration purposes. Not classified by live AI.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Passport Header Card
            EcoCard(
              backgroundColor: passport.isSimulated ? const Color(0xFFFFFDF5) : const Color(0xFFF1F8E9),
              border: Border.all(
                color: passport.isSimulated ? const Color(0xFFFFD54F) : AppColors.primaryGreen,
                width: 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            passport.isSimulated ? Icons.science_outlined : Icons.verified,
                            color: passport.isSimulated ? const Color(0xFFE65100) : AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            passport.id,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: passport.isSimulated ? const Color(0xFFE65100) : AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(passport.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    passport.itemName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${passport.primaryMaterial} • ${passport.subType}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(
                        label: passport.recyclabilityGrade.label,
                        color: passport.recyclabilityGrade.color,
                        isFilled: true,
                      ),
                      if (passport.isSimulated) ...[
                        const StatusBadge(
                          label: 'Demo Template (Simulated)',
                          color: Color(0xFFE65100),
                          icon: Icons.science_outlined,
                        ),
                      ] else ...[
                        const StatusBadge(
                          label: 'Live AI Verified',
                          color: AppColors.primaryGreen,
                          icon: Icons.verified,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: Text(
                            'Confidence: ${(passport.confidenceScore * 100).toInt()}%',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passport.recyclabilityGrade.shortDescription,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                  if (passport.visualEvidence != null && passport.visualEvidence!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Visual Evidence Detected:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  passport.visualEvidence!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Low AI Certainty / Ambiguous Material Card
            if ((passport.isAmbiguous || passport.confidenceScore < 0.65) && !passport.isSimulated) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline, color: Color(0xFFE65100), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Low AI Certainty – Please Verify Material',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (passport.ambiguityReason != null && passport.ambiguityReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        passport.ambiguityReason!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4E342E), height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Confirm actual material from physical markings or appearance:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...passport.alternativeMaterials.map((candidate) {
                          return ActionChip(
                            avatar: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFE65100)),
                            label: Text(candidate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFFFB74D)),
                            onPressed: () {
                              passportProvider.updatePassportMaterial(
                                passportId: passport.id,
                                newSubType: candidate,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Updated material subtype to "$candidate".')),
                              );
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                          label: const Text('Other / Custom Subtype', style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.blueGrey),
                          onPressed: () => _showManualSubtypeDialog(context, passportProvider, passport),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mixed Waste Segregation Alert (if applicable)
            if (passport.isMixedWaste) ...[
              EcoCard(
                backgroundColor: const Color(0xFFFFF3E0),
                border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.layers_outlined, color: Color(0xFFE65100), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mixed Waste Detected – Segregation Required',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (passport.detectedItems.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Detected Components: ${passport.detectedItems.join(", ")}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            passport.segregationAdvice ??
                                'Separate rigid recyclables, flexible plastic films, and organic residues before disposing.',
                            style: TextStyle(fontSize: 12, color: Colors.brown[900], height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hazardous Waste Special Warning vs Ordinary Non-Hazardous Banner
            if (passport.isHazardous) ...[
              EcoCard(
                backgroundColor: const Color(0xFFFFEBEE),
                border: Border.all(color: AppColors.alertRed, width: 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.alertRed, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hazardous / Special Handling Required',
                            style: TextStyle(
                              color: AppColors.alertRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This item contains toxic, heavy-metal, or volatile chemicals. DO NOT discard in regular municipal curbside bins or incinerate. Hand over only to certified aggregators.',
                            style: TextStyle(fontSize: 12, color: Colors.brown[900], height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              EcoCard(
                backgroundColor: const Color(0xFFE8F5E9),
                border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordinary Non-Hazardous Waste',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Safe for standard household handling. Segregate cleanly into dry recyclables or wet compost per local municipal guidelines.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Municipal Receptacle Stream Recommendation
            EcoCard(
              backgroundColor: passport.binColor.withAlpha(20),
              border: Border.all(color: passport.binColor.withAlpha(80), width: 1.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: passport.binColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommended Municipal Disposal Stream',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          passport.recommendedBinStream,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: passport.binColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Material Composition Breakdown
            const Text(
              'Material Composition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (passport.materialComposition.isEmpty ||
                passport.materialComposition.containsKey('Material composition not confirmed')) ...[
              EcoCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueGrey, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Material composition not confirmed (Single-material item: ${passport.primaryMaterial})',
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              EcoCard(
                child: Column(
                  children: passport.materialComposition.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${entry.value}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: entry.value / 100,
                            backgroundColor: Colors.grey[200],
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Environmental Relevance Metrics
            const Text(
              'Environmental Relevance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            EcoCard(
              backgroundColor: const Color(0xFFF1F8E9),
              border: Border.all(color: const Color(0xFFC5E1A5)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.eco_outlined, color: AppColors.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Household Environmental Impact',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passport.simpleEnvironmentalRelevance,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: EcoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.deepOrange, size: 24),
                        const SizedBox(height: 8),
                        const Text('Degradation Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          passport.degradationTime,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EcoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cloud_outlined, color: AppColors.secondaryTeal, size: 24),
                        const SizedBox(height: 8),
                        const Text('Carbon Relevance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          passport.estimatedCarbonKg,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mandatory Handling & Preparation Protocol with Interactive Checkpoints
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'Mandatory Preparation Protocol',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_checkedSteps.length} of ${passport.handlingInstructions.length} completed',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            EcoCard(
              child: Column(
                children: passport.handlingInstructions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  final isDone = _checkedSteps.contains(idx);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isDone) {
                          _checkedSteps.remove(idx);
                        } else {
                          _checkedSteps.add(idx);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isDone ? AppColors.primaryGreen : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? Colors.grey : const Color(0xFF1E2220),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons: 7-Rs Circularity & Recyclers
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(RouteNames.circularity),
                icon: const Icon(Icons.change_circle_outlined),
                label: const Text('View 7-Rs Circularity Guidance'),
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
                onPressed: () {
                  context.read<FacilityProvider>().setMatchedPassport(passport);
                  context.go(RouteNames.facilities);
                },
                icon: const Icon(Icons.near_me),
                label: Text('Find Recyclers for ${passport.primaryMaterial}'),
                style: OutlinedButton.styleFrom(
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
