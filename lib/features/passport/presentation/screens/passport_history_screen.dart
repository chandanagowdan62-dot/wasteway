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

class PassportHistoryScreen extends StatelessWidget {
  const PassportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final passportProvider = context.watch<PassportProvider>();
    final passports = passportProvider.filteredPassports;

    final materialFilters = ['All', 'Plastic', 'Metals', 'E-Waste', 'Paper', 'Glass', 'Organic'];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Waste Passports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Verifiable circular lifecycle records generated from AI image classifications.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by item, material or passport ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: passportProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => passportProvider.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: passportProvider.setSearchQuery,
            ),
            const SizedBox(height: 12),

            // Recyclability Grade Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: const Text('All Grades'),
                      selected: passportProvider.selectedGradeFilter == null,
                      onSelected: (val) {
                        if (val) passportProvider.setGradeFilter(null);
                      },
                    ),
                  ),
                  ...RecyclabilityGrade.values.map((grade) {
                    final isSel = passportProvider.selectedGradeFilter == grade;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('Grade ${grade.name}'),
                        selected: isSel,
                        selectedColor: grade.color.withAlpha(35),
                        onSelected: (val) {
                          passportProvider.setGradeFilter(val ? grade : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Material Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: materialFilters.map((mat) {
                  final isSel = passportProvider.selectedMaterialFilter == mat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(mat),
                      selected: isSel,
                      selectedColor: AppColors.primaryGreen.withAlpha(30),
                      onSelected: (val) {
                        passportProvider.setMaterialFilter(val ? mat : 'All');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Passports List
            if (passports.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 52, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching passports found.',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting your search filters or scan a new waste item.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go(RouteNames.scanner),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan New Item'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final passport = passports[index];
                  return Dismissible(
                    key: Key(passport.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      passportProvider.deletePassport(passport.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed ${passport.id}')),
                      );
                    },
                    child: EcoCard(
                      onTap: () {
                        passportProvider.setActivePassport(passport);
                        context.push(RouteNames.passportDetail);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    passport.id,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (passport.isHazardous) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.warning_amber, size: 14, color: AppColors.alertRed),
                                  ],
                                ],
                              ),
                              StatusBadge(
                                label: passport.recyclabilityGrade.label.split(' - ').first,
                                color: passport.recyclabilityGrade.color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            passport.itemName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${passport.primaryMaterial} • ${passport.subType}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.hourglass_bottom, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  passport.degradationTime,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM').format(passport.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
