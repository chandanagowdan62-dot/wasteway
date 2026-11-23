import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/facility_provider.dart';
import '../../domain/models/recycling_facility_model.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  int _selectedTab = 0; // 0: Physical Drop-Off Facilities, 1: Recycling Services & Kabadiwala Apps

  Future<void> _openDirections(String name, String? address, [double? lat, double? lng]) async {
    final destination = address != null && address.isNotEmpty ? '$name, $address' : name;
    final encoded = Uri.encodeComponent(destination);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url, [BuildContext? context]) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open external link: $url'),
              backgroundColor: Colors.orange[800],
            ),
          );
        }
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Browser unavailable to handle link: $url'),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilityProvider = context.watch<FacilityProvider>();
    final facilities = facilityProvider.filteredFacilities;
    final kabadiwalaServices = facilityProvider.filteredKabadiwalaServices;
    final matchedPassport = facilityProvider.matchedPassport;

    final materialFilters = [
      'All',
      'Plastic',
      'Electronic Waste (E-Waste)',
      'Metals',
      'Paper & Cardboard',
      'Glass',
      'Biodegradable / Organic',
      'Hazardous / Chemical',
      'Textiles & Fabrics',
      'Multi-Layer / Composite Materials',
      'Medical & Sanitary Waste',
      'Furniture & Bulky Goods',
      'Construction & Demolition Waste',
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title & Header
            Text(
              'Recycling & Waste Directory',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Locate certified drop-off centres or discover external kabadiwala apps for doorstep recycling.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Strict Scope Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Informational Directory & Navigation only. WasteWay does not dispatch pickup, transport, or collection logistics.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0D47A1), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Category Segmented Selector: Drop-Off Centres vs. Kabadiwala Apps
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: _selectedTab == 0 ? AppColors.primaryGreen : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Drop-off Centres (${facilities.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                                  color: _selectedTab == 0 ? AppColors.primaryGreen : Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 16,
                              color: _selectedTab == 1 ? const Color(0xFF0288D1) : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Kabadiwala Apps (${kabadiwalaServices.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                                  color: _selectedTab == 1 ? const Color(0xFF0288D1) : Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Official Governmental Portals Card
            EcoCard(
              backgroundColor: const Color(0xFFF0F4F8),
              border: Border.all(color: const Color(0xFFB0BEC5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Color(0xFF1565C0), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Official Government Waste & Recycling Portals',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'For verified physical drop-off locations, authorized e-waste dismantlers, and municipal schedules, access verified civic registries:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF37474F), height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1565C0)),
                        label: const Text('CPCB India (National)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => _openUrl('https://cpcb.nic.in', context),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1565C0)),
                        label: const Text('KSPCB (State E-Waste)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => _openUrl('https://kspcb.karnataka.gov.in', context),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1565C0)),
                        label: const Text('BSWML Karnataka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => _openUrl('https://bswml.karnataka.gov.in/', context),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1565C0)),
                        label: const Text('BBMP SWM Citizen Portal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () => _openUrl('https://apps.bbmpgov.in/SWM/Home/Forms/Home.aspx', context),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF90CAF9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Matched Passport Banner (when navigating from Passport/Circularity)
            if (matchedPassport != null) ...[
              EcoCard(
                backgroundColor: const Color(0xFFE8F5E9),
                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matched Facilities for ${matchedPassport.itemName}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            'Material: ${matchedPassport.primaryMaterial} (${matchedPassport.subType})',
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: facilityProvider.clearMatchedPassport,
                      child: const Text('Show All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Honest educational notice for used tissues / napkins
              if (matchedPassport.subType.toLowerCase().contains('tissue') ||
                  matchedPassport.primaryMaterial.toLowerCase().contains('tissue') ||
                  matchedPassport.itemName.toLowerCase().contains('tissue') ||
                  matchedPassport.subType.toLowerCase().contains('napkin')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF9800)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFE65100), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Scrap Dealer Buys Used Tissues',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFE65100)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Paper recyclers and scrap dealers do NOT buy used paper tissues or napkins because cellulose fibers are too short and often soiled with food oils or hygiene microbes. '
                              'Place clean food-soiled tissues in your green wet-waste compost bin; dispose personal hygiene tissues in standard municipal trash per BBMP guidelines.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF4E342E), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Educational notice for medical and sanitary waste
              if (matchedPassport.primaryMaterial.toLowerCase().contains('medical') ||
                  matchedPassport.primaryMaterial.toLowerCase().contains('sanitary') ||
                  matchedPassport.subType.toLowerCase().contains('biomedical') ||
                  matchedPassport.subType.toLowerCase().contains('sanitary') ||
                  matchedPassport.subType.toLowerCase().contains('blister') ||
                  matchedPassport.itemName.toLowerCase().contains('mask')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alertRed),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.alertRed, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biomedical & Sanitary Handling Advisory',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.alertRed),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'General scrap dealers, dry waste collection centres, and compost units do NOT accept biomedical or sanitary waste. '
                              'Seal in a dedicated leak-proof sanitary pouch (red/yellow) and route to authorized municipal sanitary collection or hospital take-back drop boxes.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF4E342E), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Educational notice for construction & demolition waste
              if (matchedPassport.primaryMaterial.toLowerCase().contains('construction') ||
                  matchedPassport.primaryMaterial.toLowerCase().contains('demolition') ||
                  matchedPassport.subType.toLowerCase().contains('debris') ||
                  matchedPassport.subType.toLowerCase().contains('rubble')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF90A4AE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.construction_outlined, color: Color(0xFF37474F), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Construction & Demolition Debris Advisory',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF263238)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Doorstep scrap platforms and dry waste collection centres cannot handle heavy concrete, broken tiles, or masonry rubble. '
                              'Contact authorized municipal C&D processing facilities or BBMP designated ward C&D collection yards for aggregate recovery.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF37474F), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: _selectedTab == 0
                    ? 'Search by facility name, address, or material...'
                    : 'Search by app name, scrap type, or region...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: facilityProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => facilityProvider.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: facilityProvider.setSearchQuery,
            ),
            const SizedBox(height: 12),

            // Multi-Material Filter Section Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'Filter by Materials (Multi-Select):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF37474F)),
                ),
                if (facilityProvider.selectedMaterialFilters.isNotEmpty)
                  GestureDetector(
                    onTap: facilityProvider.clearMaterialFilters,
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(fontSize: 11, color: AppColors.alertRed, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Material Filter Chips (Multi-Select enabled)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 'All' Chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('All Materials'),
                      selected: facilityProvider.selectedMaterialFilters.isEmpty,
                      selectedColor: AppColors.primaryGreen.withAlpha(35),
                      checkmarkColor: AppColors.primaryGreen,
                      onSelected: (val) {
                        if (val) facilityProvider.clearMaterialFilters();
                      },
                    ),
                  ),
                  ...materialFilters.where((m) => m != 'All').map((mat) {
                    final isSel = facilityProvider.isMaterialSelected(mat);
                    final displayLabel = mat == 'Electronic Waste (E-Waste)'
                        ? 'E-Waste'
                        : mat == 'Biodegradable / Organic'
                            ? 'Compost / Organic'
                            : mat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(displayLabel),
                        selected: isSel,
                        selectedColor: AppColors.primaryGreen.withAlpha(35),
                        checkmarkColor: AppColors.primaryGreen,
                        onSelected: (_) {
                          facilityProvider.toggleMaterialFilter(mat);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Active Multi-Material Summary Bar (if selections exist)
            if (facilityProvider.selectedMaterialFilters.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGreen.withAlpha(50)),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Selected (${facilityProvider.selectedMaterialFilters.length}):',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                    ),
                    ...facilityProvider.selectedMaterialFilters.map((m) {
                      final shortLabel = m == 'Electronic Waste (E-Waste)'
                          ? 'E-Waste'
                          : m == 'Biodegradable / Organic'
                              ? 'Compost'
                              : m;
                      return Chip(
                        label: Text(shortLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close, size: 12),
                        onDeleted: () => facilityProvider.removeMaterialFilter(m),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.primaryGreen),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // If Tab 0 is selected: Facility Type Filter Chips
            if (_selectedTab == 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('All Types'),
                        selected: facilityProvider.selectedTypeFilter == null,
                        onSelected: (val) {
                          if (val) facilityProvider.setTypeFilter(null);
                        },
                      ),
                    ),
                    ...FacilityType.values.map((type) {
                      final isSel = facilityProvider.selectedTypeFilter == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Icon(type.icon, size: 14, color: isSel ? type.color : Colors.grey),
                          label: Text(type.label.split(' / ').first),
                          selected: isSel,
                          selectedColor: type.color.withAlpha(30),
                          onSelected: (val) {
                            facilityProvider.setTypeFilter(val ? type : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Informational Guidance Banner for Kabadiwala Apps
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF81D4FA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.moped, size: 20, color: Color(0xFF0288D1)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doorstep Scrap Collection Platforms',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF01579B)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'These independent digital apps and platforms allow households to book doorstep scrap collection. '
                            'Digital scales are brought to your doorstep with direct cash or UPI payments. Check coverage notes for your city.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF0277BD), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Header & Count
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  _selectedTab == 0
                      ? '${facilities.length} ${facilities.length == 1 ? 'Facility' : 'Facilities'} Available'
                      : '${kabadiwalaServices.length} ${kabadiwalaServices.length == 1 ? 'Service' : 'Services & Apps'} Available',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  _selectedTab == 0 ? 'Sorted by Proximity' : 'Prioritizing Bengaluru Coverage',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab 0: Physical Drop-off Facilities List
            if (_selectedTab == 0) ...[
              if (facilities.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No facilities match your selection.',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No registered or demonstration facility accepts this material stream under the current filters.\nFor active local drop-off points, please refer to the official government portals above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () {
                            facilityProvider.clearMatchedPassport();
                            facilityProvider.setSearchQuery('');
                            facilityProvider.setMaterialFilter('All');
                            facilityProvider.setTypeFilter(null);
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...facilities.map((facility) {
                  final distanceKm = (facility.hasLocation &&
                          facilityProvider.userLatitude != null &&
                          facilityProvider.userLongitude != null)
                      ? facilityProvider.calculateDistanceKm(
                          facilityProvider.userLatitude!,
                          facilityProvider.userLongitude!,
                          facility.latitude!,
                          facility.longitude!,
                        )
                      : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: EcoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header: Type Badge & Verification Tag
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: facility.facilityType.color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  facility.facilityType.icon,
                                  color: facility.facilityType.color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      facility.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      facility.facilityType.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: facility.facilityType.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (distanceKm != null) ...[
                                StatusBadge(
                                  label: '${distanceKm.toStringAsFixed(1)} km',
                                  color: AppColors.secondaryTeal,
                                  icon: Icons.navigation_outlined,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Verification / Sample Badge
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (facility.isDoorstepPlatform) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F5FE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF0288D1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_shipping_outlined, size: 12, color: Color(0xFF0288D1)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Doorstep Platform',
                                        style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (facility.isVerified) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryGreen),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 12, color: AppColors.primaryGreen),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Verified Physical Facility',
                                          style: TextStyle(
                                              fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (facility.rating != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      facility.rating!.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),

                          // Source Reference Citation
                          if (facility.sourceReference != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Source: ${facility.sourceReference}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ],

                          // Address (conditionally displayed if available)
                          if (facility.address != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    facility.address!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Coverage Area (for doorstep platforms)
                          if (facility.isDoorstepPlatform && facility.coverageArea != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.share_location, size: 14, color: Color(0xFF0288D1)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Coverage: ${facility.coverageArea!}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF01579B), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Operating Hours (conditionally displayed if available)
                          if (facility.operatingHours != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    facility.operatingHours!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Multi-Material Match Feedback
                          if (facilityProvider.selectedMaterialFilters.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final acceptedUserMats = facilityProvider.getAcceptedSelectedMaterials(facility);
                                final unacceptedUserMats = facilityProvider.selectedMaterialFilters
                                    .where((m) => !facility.acceptsMaterial(m))
                                    .toList();
                                final totalSelected = facilityProvider.selectedMaterialFilters.length;
                                final acceptedCount = acceptedUserMats.length;
                                final allAccepted = acceptedCount == totalSelected;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: allAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: allAccepted ? AppColors.primaryGreen : const Color(0xFFFFB300),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            allAccepted ? Icons.check_circle : Icons.info_outline,
                                            size: 14,
                                            color: allAccepted ? AppColors.primaryGreen : const Color(0xFFE65100),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              allAccepted
                                                  ? 'Accepts all $totalSelected of your selected materials'
                                                  : 'Accepts $acceptedCount of your $totalSelected selected materials',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: allAccepted
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFE65100),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (unacceptedUserMats.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Note: Does NOT accept: ${unacceptedUserMats.join(', ')}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFFC62828),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          // Accepted Materials Tags
                          const Text(
                            'Accepted Materials:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: facility.acceptedMaterials.map((mat) {
                              final isHighlightedByPassport = matchedPassport != null &&
                                  (mat.toLowerCase().contains(matchedPassport.primaryMaterial.toLowerCase()) ||
                                      matchedPassport.primaryMaterial.toLowerCase().contains(mat.toLowerCase()));
                              final isHighlightedByMultiSelect = facilityProvider.selectedMaterialFilters.any((sel) =>
                                  mat.toLowerCase().contains(sel.toLowerCase()) ||
                                  sel.toLowerCase().contains(mat.toLowerCase()));
                              final isHighlighted = isHighlightedByPassport || isHighlightedByMultiSelect;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isHighlighted ? const Color(0xFFC8E6C9) : const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isHighlighted ? Border.all(color: AppColors.primaryGreen) : null,
                                ),
                                child: Text(
                                  '✓ $mat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Drop-off instructions (if available)
                          if (facility.dropOffInstructions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.assignment_outlined, size: 14, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Drop-Off Preparation Instructions:',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...facility.dropOffInstructions.map((instruction) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                          Expanded(
                                            child: Text(
                                              instruction,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],

                          // Unverified contact notice
                          if (facility.phone == null || !facility.isVerified || facility.isSampleData) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Direct telephone contact unverified. Please consult official municipal waste directories or local civic authority portals for drop-off confirmation.',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Actions: Book Doorstep Pickup, Directions, Official Portal, Citizen Portal
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              if (facility.facilityType == FacilityType.governmentAuthority) ...[
                                if (facility.website != null && facility.website!.isNotEmpty) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _openUrl(facility.website!, context),
                                    icon: const Icon(Icons.account_balance, size: 16),
                                    label: const Text('Official Government Portal'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                                if (facility.portalUrl != null && facility.portalUrl!.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    onPressed: () => _openUrl(facility.portalUrl!, context),
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('BBMP Citizen SWM Portal'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                if (facility.isDoorstepPlatform) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _openUrl(
                                        facility.bookingUrl ?? facility.website ?? 'https://kabadify.com', context),
                                    icon: const Icon(Icons.calendar_month, size: 16),
                                    label: const Text('Book Doorstep Pickup'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ] else if (facility.hasLocation) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _openDirections(
                                        facility.name, facility.address, facility.latitude, facility.longitude),
                                    icon: const Icon(Icons.directions, size: 16),
                                    label: const Text('Directions (Maps)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                                if (facility.website != null && facility.website!.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    onPressed: () => _openUrl(facility.website!, context),
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('Official Portal'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ] else ...[
              // Tab 1: Recycling Services & Kabadiwala Apps List
              if (kabadiwalaServices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.phone_disabled_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No kabadiwala apps match your selection.',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No registered scrap collection service currently handles this material stream under the active filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () {
                            facilityProvider.clearMatchedPassport();
                            facilityProvider.setSearchQuery('');
                            facilityProvider.clearMaterialFilters();
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...kabadiwalaServices.map((service) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: EcoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header: Icon, Name, Service Type, Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0288D1).withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.moped,
                                  color: Color(0xFF0288D1),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      service.serviceType,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0288D1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    service.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Coverage Badge: Bengaluru Active vs Regional Platform
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (service.operatesInBengaluru) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryGreen),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: AppColors.primaryGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bengaluru Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFFB300)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline, size: 12, color: Color(0xFFE65100)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Regional Coverage',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Text(
                                'Coverage: ${service.geographicCoverage}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Regional Disclosure Notice if service does NOT operate in Bengaluru
                          if (!service.operatesInBengaluru && service.coverageNotes != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFB300)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_off, size: 15, color: Color(0xFFE65100)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      service.coverageNotes!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFE65100),
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Description
                          const SizedBox(height: 8),
                          Text(
                            service.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.35),
                          ),

                          // Operating Hours (if available)
                          if (service.operatingHours != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    service.operatingHours!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Multi-Material Match Feedback for Kabadiwala Service
                          if (facilityProvider.selectedMaterialFilters.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final acceptedUserMats =
                                    facilityProvider.getAcceptedSelectedMaterialsForService(service);
                                final unacceptedUserMats = facilityProvider.selectedMaterialFilters
                                    .where((m) => !service.acceptsMaterial(m))
                                    .toList();
                                final totalSelected = facilityProvider.selectedMaterialFilters.length;
                                final acceptedCount = acceptedUserMats.length;
                                final allAccepted = acceptedCount == totalSelected;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: allAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: allAccepted ? AppColors.primaryGreen : const Color(0xFFFFB300),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            allAccepted ? Icons.check_circle : Icons.info_outline,
                                            size: 14,
                                            color: allAccepted ? AppColors.primaryGreen : const Color(0xFFE65100),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              allAccepted
                                                  ? 'Collects all $totalSelected of your selected scrap streams'
                                                  : 'Collects $acceptedCount of your $totalSelected selected scrap streams',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: allAccepted
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFE65100),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (unacceptedUserMats.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Note: Does NOT collect: ${unacceptedUserMats.join(', ')}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFFC62828),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          // Accepted Scrap Materials Chips
                          const Text(
                            'Accepted Scrap Materials:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: service.acceptedMaterials.map((mat) {
                              final isHighlightedByPassport = matchedPassport != null &&
                                  (mat.toLowerCase().contains(matchedPassport.primaryMaterial.toLowerCase()) ||
                                      matchedPassport.primaryMaterial.toLowerCase().contains(mat.toLowerCase()));
                              final isHighlightedByMultiSelect = facilityProvider.selectedMaterialFilters.any((sel) =>
                                  mat.toLowerCase().contains(sel.toLowerCase()) ||
                                  sel.toLowerCase().contains(mat.toLowerCase()));
                              final isHighlighted = isHighlightedByPassport || isHighlightedByMultiSelect;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isHighlighted ? const Color(0xFFC8E6C9) : const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isHighlighted ? Border.all(color: AppColors.primaryGreen) : null,
                                ),
                                child: Text(
                                  '✓ $mat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Pickup Instructions Box
                          if (service.pickupInstructions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.task_alt, size: 14, color: Color(0xFF0288D1)),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Doorstep Collection Steps:',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...service.pickupInstructions.map((instruction) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                          Expanded(
                                            child: Text(
                                              instruction,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Action Buttons: Book Pickup, Visit Website, Play Store, App Store
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Book Doorstep Pickup Button
                              if (service.hasBooking)
                                ElevatedButton.icon(
                                  onPressed: () => _openUrl(service.bookingUrl!, context),
                                  icon: const Icon(Icons.calendar_month, size: 16),
                                  label: const Text('Book Doorstep Pickup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                ),

                              // Visit Website Button
                              if (service.hasWebsite)
                                OutlinedButton.icon(
                                  onPressed: () => _openUrl(service.websiteUrl!, context),
                                  icon: const Icon(Icons.language, size: 16),
                                  label: const Text('Visit Website'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),

                              // Google Play Store Link
                              if (service.hasPlayStore)
                                OutlinedButton.icon(
                                  onPressed: () => _openUrl(service.playStoreUrl!, context),
                                  icon: const Icon(Icons.android, size: 16, color: Color(0xFF2E7D32)),
                                  label: const Text('Get Android App'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    side: const BorderSide(color: Color(0xFF81C784)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),

                              // Apple App Store Link
                              if (service.hasAppStore)
                                OutlinedButton.icon(
                                  onPressed: () => _openUrl(service.appStoreUrl!, context),
                                  icon: const Icon(Icons.apple, size: 16, color: Colors.black87),
                                  label: const Text('Get iOS App'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: const BorderSide(color: Colors.black38),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
