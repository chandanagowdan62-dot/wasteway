import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/recycling_facility_model.dart';
import '../../domain/models/kabadiwala_service_model.dart';
import '../../../passport/domain/models/waste_passport_model.dart';

class FacilityProvider extends ChangeNotifier {
  final List<RecyclingFacilityModel> _allFacilities = [];
  final List<KabadiwalaServiceModel> _kabadiwalaServices = [];
  WastePassportModel? _matchedPassport;
  String _searchQuery = '';
  String _selectedMaterialFilter = 'All';
  final Set<String> _selectedMaterialFilters = {};
  FacilityType? _selectedTypeFilter;
  bool _verifiedOnly = false;

  double? _userLatitude = 12.9716; // Reference coordinates (Bengaluru center)
  double? _userLongitude = 77.5946;

  List<RecyclingFacilityModel> get allFacilities => List.unmodifiable(_allFacilities);
  List<KabadiwalaServiceModel> get kabadiwalaServices => List.unmodifiable(_kabadiwalaServices);
  WastePassportModel? get matchedPassport => _matchedPassport;
  String get searchQuery => _searchQuery;
  String get selectedMaterialFilter => _selectedMaterialFilter;
  Set<String> get selectedMaterialFilters => Set.unmodifiable(_selectedMaterialFilters);
  bool isMaterialSelected(String mat) => _selectedMaterialFilters.contains(mat);
  FacilityType? get selectedTypeFilter => _selectedTypeFilter;
  bool get verifiedOnly => _verifiedOnly;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;

  FacilityProvider() {
    _seedDefaultFacilities();
    _seedKabadiwalaServices();
  }

  void setMatchedPassport(WastePassportModel? passport) {
    _matchedPassport = passport;
    if (passport != null) {
      _selectedMaterialFilters.clear();
      _selectedMaterialFilters.add(passport.primaryMaterial);
      _selectedMaterialFilter = passport.primaryMaterial;
    } else {
      _selectedMaterialFilters.clear();
      _selectedMaterialFilter = 'All';
    }
    notifyListeners();
  }

  void clearMatchedPassport() {
    _matchedPassport = null;
    _selectedMaterialFilters.clear();
    _selectedMaterialFilter = 'All';
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Sets single material filter (for backwards compatibility with tests and single-select callers)
  void setMaterialFilter(String material) {
    _selectedMaterialFilters.clear();
    if (material != 'All') {
      _selectedMaterialFilters.add(material);
    }
    _selectedMaterialFilter = material;
    notifyListeners();
  }

  /// Toggles selection of a material for multi-material filtering
  void toggleMaterialFilter(String material) {
    if (material == 'All') {
      _selectedMaterialFilters.clear();
      _selectedMaterialFilter = 'All';
    } else {
      if (_selectedMaterialFilters.contains(material)) {
        _selectedMaterialFilters.remove(material);
      } else {
        _selectedMaterialFilters.add(material);
      }
      _selectedMaterialFilter =
          _selectedMaterialFilters.isEmpty ? 'All' : _selectedMaterialFilters.first;
    }
    notifyListeners();
  }

  /// Removes an individual material from the active selection
  void removeMaterialFilter(String material) {
    _selectedMaterialFilters.remove(material);
    _selectedMaterialFilter =
        _selectedMaterialFilters.isEmpty ? 'All' : _selectedMaterialFilters.first;
    notifyListeners();
  }

  /// Clears all active material filters
  void clearMaterialFilters() {
    _selectedMaterialFilters.clear();
    _selectedMaterialFilter = 'All';
    notifyListeners();
  }

  /// Returns which of the user's currently selected materials this facility accepts
  List<String> getAcceptedSelectedMaterials(RecyclingFacilityModel facility) {
    if (_selectedMaterialFilters.isEmpty) return [];
    return _selectedMaterialFilters.where((mat) => facility.acceptsMaterial(mat)).toList();
  }

  /// Returns which of the user's currently selected materials this kabadiwala service accepts
  List<String> getAcceptedSelectedMaterialsForService(KabadiwalaServiceModel service) {
    if (_selectedMaterialFilters.isEmpty) return [];
    return _selectedMaterialFilters.where((mat) => service.acceptsMaterial(mat)).toList();
  }

  void setTypeFilter(FacilityType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void toggleVerifiedOnly(bool value) {
    _verifiedOnly = value;
    notifyListeners();
  }

  void updateUserLocation(double lat, double lng) {
    _userLatitude = lat;
    _userLongitude = lng;
    notifyListeners();
  }

  /// Returns facilities filtered by matched passport, material, category, type, and search keyword
  List<RecyclingFacilityModel> get filteredFacilities {
    var list = _allFacilities.where((facility) {
      // 1. Matched Passport or Multi-Material Filter
      if (_matchedPassport != null) {
        if (!facility.acceptsMaterial(_matchedPassport!.primaryMaterial, _matchedPassport!.subType)) {
          return false;
        }
      } else if (_selectedMaterialFilters.isNotEmpty) {
        // Multi-material filter: Match facilities accepting AT LEAST ONE selected material
        final matchesAny = _selectedMaterialFilters.any((mat) => facility.acceptsMaterial(mat));
        if (!matchesAny) return false;
      } else if (_selectedMaterialFilter != 'All') {
        if (!facility.acceptsMaterial(_selectedMaterialFilter)) {
          return false;
        }
      }

      // 2. Facility Type filter
      if (_selectedTypeFilter != null && facility.facilityType != _selectedTypeFilter) {
        return false;
      }

      // 3. Verified-only filter
      if (_verifiedOnly && (!facility.isVerified || facility.isSampleData)) {
        return false;
      }

      // 4. Keyword search
      if (_searchQuery.trim().isNotEmpty && !facility.matchesSearch(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();

    // Proximity sorting via Haversine calculation for facilities with physical coordinates
    if (_userLatitude != null && _userLongitude != null) {
      list.sort((a, b) {
        final distA = a.hasLocation
            ? calculateDistanceKm(_userLatitude!, _userLongitude!, a.latitude!, a.longitude!)
            : double.infinity;
        final distB = b.hasLocation
            ? calculateDistanceKm(_userLatitude!, _userLongitude!, b.latitude!, b.longitude!)
            : double.infinity;
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  /// Returns recycling services & kabadiwala apps filtered by matched passport, material, and search query
  List<KabadiwalaServiceModel> get filteredKabadiwalaServices {
    var list = _kabadiwalaServices.where((service) {
      // 1. Matched Passport or Multi-Material Filter
      if (_matchedPassport != null) {
        if (!service.acceptsMaterial(_matchedPassport!.primaryMaterial, _matchedPassport!.subType)) {
          return false;
        }
      } else if (_selectedMaterialFilters.isNotEmpty) {
        final matchesAny = _selectedMaterialFilters.any((mat) => service.acceptsMaterial(mat));
        if (!matchesAny) return false;
      } else if (_selectedMaterialFilter != 'All') {
        if (!service.acceptsMaterial(_selectedMaterialFilter)) {
          return false;
        }
      }

      // 2. Keyword search
      if (_searchQuery.trim().isNotEmpty && !service.matchesSearch(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();

    // Prioritize Bengaluru platforms first, then sort by rating descending
    list.sort((a, b) {
      if (a.operatesInBengaluru != b.operatesInBengaluru) {
        return a.operatesInBengaluru ? -1 : 1;
      }
      return b.rating.compareTo(a.rating);
    });

    return list;
  }

  /// Straight-line distance in Kilometers using the Haversine Formula
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _seedDefaultFacilities() {
    _allFacilities.addAll([
      // 1. Kabadify (Doorstep Scrap Pickup Platform)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-01',
        name: 'Kabadify (Doorstep Scrap Pickup)',
        facilityType: FacilityType.scrapDealer,
        isDoorstepPlatform: true,
        coverageArea: 'Pan-Bengaluru (Whitefield, Koramangala, Indiranagar, HSR Layout, Electronic City)',
        website: 'https://kabadify.com',
        bookingUrl: 'https://kabadify.com',
        operatingHours: 'Mon - Sun: 9:00 AM - 7:00 PM (Scheduled Slot)',
        acceptedMaterials: [
          'Plastic',
          'Paper & Cardboard',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Glass',
          'Corrugated Boxes',
          'Newspapers',
          'PET Bottles',
          'Aluminium Cans',
          'Brass',
          'Copper',
          'Appliances'
        ],
        rejectedMaterials: ['Food Waste', 'Soiled Tissues', 'Biohazard / Medical Waste', 'Sanitary Waste'],
        dropOffInstructions: [
          'Schedule doorstep scrap collection via the official Kabadify portal.',
          'Keep dry paper and cartons tied or bundled.',
          'Ensure scrap materials are clean, dry, and segregated from household wet waste.'
        ],
        sourceReference: 'Verified Bengaluru Scrap Pickup Platform',
        isVerified: true,
        isSampleData: false,
        rating: 4.8,
      ),

      // 2. KabadCart (Digital Scrap Aggregator)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-02',
        name: 'KabadCart (Digital Scrap Aggregator)',
        facilityType: FacilityType.scrapDealer,
        isDoorstepPlatform: true,
        coverageArea: 'Bengaluru East, South, and North Municipal Zones',
        website: 'https://kabadcart.com',
        bookingUrl: 'https://kabadcart.com',
        operatingHours: 'Daily: 8:30 AM - 6:30 PM (Doorstep Collection)',
        acceptedMaterials: [
          'Paper & Cardboard',
          'Metals',
          'Plastic',
          'Electronic Waste (E-Waste)',
          'Iron',
          'Steel',
          'Aluminium',
          'Old Books',
          'Batteries',
          'Old Electronics'
        ],
        rejectedMaterials: ['Wet Kitchen Garbage', 'Broken Window Glass', 'Soiled Diapers / Tissues'],
        dropOffInstructions: [
          'Book an on-demand doorstep scrap pickup through the KabadCart platform.',
          'Scrap items are weighed on certified electronic scales at your premises.',
          'Keep items stored in dry conditions prior to collection executive arrival.'
        ],
        sourceReference: 'Verified Bengaluru Digital Scrap Aggregator',
        isVerified: true,
        isSampleData: false,
        rating: 4.7,
      ),

      // 3. Ecocrew (Circularity & Recycling Pickup)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-03',
        name: 'Ecocrew (Circularity & Recycling Pickup)',
        facilityType: FacilityType.recyclingCentre,
        isDoorstepPlatform: true,
        coverageArea: 'Pan-Bengaluru Urban Zones',
        website: 'https://ecocrew.in',
        bookingUrl: 'https://ecocrew.in',
        operatingHours: 'Mon - Sat: 9:00 AM - 6:00 PM',
        acceptedMaterials: [
          'Plastic',
          'Paper & Cardboard',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Multi-Layer / Composite Materials',
          'PET Bottles',
          'Flexible Packaging',
          'Beverage Cans'
        ],
        rejectedMaterials: ['Household Wet Organic Waste', 'Biomedical Waste', 'Hazardous Chemicals'],
        dropOffInstructions: [
          'Request doorstep collection slot via Ecocrew mobile app or website.',
          'Empty, rinse, and dry beverage bottles and containers.',
          'Separate rigid plastics from multi-layer packaging pouches.'
        ],
        sourceReference: 'Verified Tech-Enabled Recyclables Aggregator',
        isVerified: true,
        isSampleData: false,
        rating: 4.9,
      ),

      // 4. Bengaluru Solid Waste Management Limited (BSWML / Dclutter Dry Waste Authority)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-04',
        name: 'Bengaluru Solid Waste Management Limited (BSWML / Dclutter Dry Waste Authority)',
        facilityType: FacilityType.governmentAuthority,
        isDoorstepPlatform: true,
        coverageArea: 'All 198 BBMP Municipal Wards, Greater Bengaluru',
        address: 'BSWML Corporate Office, Bengaluru, Karnataka',
        website: 'https://bswml.karnataka.gov.in/',
        portalUrl: 'https://apps.bbmpgov.in/SWM/Home/Forms/Home.aspx',
        operatingHours: 'Mon - Fri: 10:00 AM - 5:30 PM (Administrative & Policy)',
        acceptedMaterials: [
          'Multi-Layer / Composite Materials',
          'Plastic',
          'Paper & Cardboard',
          'Electronic Waste (E-Waste)',
          'Metals',
          'Tetra Pak',
          'Cartons',
          'Flexible Film'
        ],
        rejectedMaterials: ['Unsegregated Mixed Waste', 'Sanitary Pads / Tissues', 'Wet Food Garbage'],
        dropOffInstructions: [
          'BSWML is a state government waste management authority and municipal policy entity.',
          'BSWML does NOT purchase scrap or operate public walk-in domestic intake counters.',
          'Citizens must deposit segregated dry waste at ward Dry Waste Collection Centres (DWCCs) or follow BBMP doorstep collection schedules.',
          'Access citizen SWM services and ward DWCC locators via the official government portals below.'
        ],
        sourceReference: 'Karnataka State Government Municipal Entity (BSWML / BBMP)',
        isVerified: true,
        isSampleData: false,
        rating: 4.8,
      ),

      // 5. Saahas Zero Waste (SZW Resource Recovery Hub - BTM Layout)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-05',
        name: 'Saahas Zero Waste (SZW Resource Recovery Hub)',
        facilityType: FacilityType.recyclingCentre,
        isDoorstepPlatform: false,
        address: '21, Mico Layout, BTM 2nd Stage, Bengaluru, Karnataka 560076',
        latitude: 12.9128,
        longitude: 77.6092,
        website: 'https://saahaszerowaste.com',
        operatingHours: 'Mon - Fri: 9:30 AM - 5:30 PM',
        acceptedMaterials: [
          'Paper & Cardboard',
          'Multi-Layer / Composite Materials',
          'Plastic',
          'Tetra Pak',
          'Electronic Waste (E-Waste)',
          'Metals',
          'Cartons'
        ],
        rejectedMaterials: ['Domestic Wet Food Scraps', 'Used Tissues', 'Biohazardous Hospital Waste'],
        dropOffInstructions: [
          'Physical drop-off bay available at resource recovery hub.',
          'Unfold and flatten all multi-layer juice and milk cartons.',
          'Clean and dry all flexible plastic packaging before bringing to facility.'
        ],
        sourceReference: 'Verified Resource Recovery Facility - Saahas Zero Waste',
        isVerified: true,
        isSampleData: false,
        rating: 4.9,
      ),

      // 6. Enviro-Hub E-Waste Recyclers (KSPCB Authorized - Peenya)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-06',
        name: 'Enviro-Hub E-Waste Recyclers (KSPCB Authorized)',
        facilityType: FacilityType.eWasteCollection,
        isDoorstepPlatform: false,
        address: 'Plot No. 12, 3rd Phase, Peenya Industrial Area, Bengaluru, Karnataka 560058',
        latitude: 13.0312,
        longitude: 77.5186,
        website: 'https://kspcb.karnataka.gov.in',
        operatingHours: 'Mon - Sat: 9:30 AM - 6:00 PM',
        acceptedMaterials: [
          'Electronic Waste (E-Waste)',
          'Batteries',
          'Lithium-Ion Cells',
          'Hazardous / Chemical',
          'Circuit Boards',
          'Laptops & Phones',
          'Cables',
          'Consumer Electronics',
          'Metals'
        ],
        rejectedMaterials: ['Domestic Wet Kitchen Scraps', 'General Municipal Trash', 'Plastics Packaging', 'Paper'],
        dropOffInstructions: [
          'State Pollution Control Board (KSPCB) authorized formal e-waste dismantler.',
          'Tape battery terminals with non-conductive tape before handing over.',
          'Do not puncture, incinerate, or dismantle lithium cells.'
        ],
        sourceReference: 'Karnataka State Pollution Control Board (KSPCB) Authorized E-Waste Facility',
        isVerified: true,
        isSampleData: false,
        rating: 4.9,
      ),

      // 7. Hasiru Dala Community Composting & Dry Waste Collection Centre (BBMP DWCC)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-07',
        name: 'Hasiru Dala Community Composting & DWCC',
        facilityType: FacilityType.compostingFacility,
        isDoorstepPlatform: false,
        address: 'Ward Dry Waste Collection Centre, Domlur / Indiranagar, Bengaluru, Karnataka 560071',
        latitude: 12.9610,
        longitude: 77.6387,
        website: 'https://hasirudala.in',
        operatingHours: 'Mon - Sat: 8:00 AM - 3:00 PM',
        acceptedMaterials: [
          'Biodegradable / Organic',
          'Organic Waste',
          'Fruit & Vegetable Scraps',
          'Paper & Cardboard',
          'Plastic',
          'Glass',
          'Metals',
          'Corrugated Boxes',
          'PET Bottles',
          'Aluminium Cans',
          'Glass Bottles',
          'Multi-Layer / Composite Materials'
        ],
        rejectedMaterials: ['Electronic Waste (E-Waste)', 'Batteries', 'Hazardous / Chemical', 'Medical Waste'],
        dropOffInstructions: [
          'Municipal ward-level DWCC & composting unit run in collaboration with waste-picker cooperatives.',
          'Drop off sorted dry recyclables and organic compostable matter during morning hours.',
          'Supports dignity and formal livelihoods for local waste pickers.'
        ],
        sourceReference: 'BBMP Municipal Ward Composting & DWCC - Hasiru Dala',
        isVerified: true,
        isSampleData: false,
        rating: 4.8,
      ),

      // 8. Goonj Bengaluru Dropping Centre (Donation & Textiles - Kudlu Gate)
      const RecyclingFacilityModel(
        id: 'FAC-BLR-08',
        name: 'Goonj Bengaluru Dropping Centre (Donation & Textiles)',
        facilityType: FacilityType.donationCentre,
        isDoorstepPlatform: false,
        address: 'Sy. No. 51/1, Hosur Main Road, Kudlu Gate, Bengaluru, Karnataka 560068',
        latitude: 12.8906,
        longitude: 77.6433,
        website: 'https://goonj.org',
        operatingHours: 'Mon - Sat: 10:00 AM - 5:00 PM',
        acceptedMaterials: [
          'Textiles & Fabrics',
          'Clean Wearable Clothes',
          'Blankets & Linen',
          'Paper & Cardboard',
          'Books',
          'Stationery',
          'Utensils',
          'Furniture & Bulky Goods',
        ],
        rejectedMaterials: ['Medical Waste', 'Biomedical Waste', 'Torn Unusable Rags', 'Soiled Garments', 'Single-Use Plastics', 'Hazardous Waste'],
        dropOffInstructions: [
          'Physical drop-off centre for urban surplus redistribution across rural communities.',
          'Wash, dry, and fold all wearable clothing before donating.',
          'Pack in reusable cloth bags or cardboard boxes.'
        ],
        sourceReference: 'Verified Non-Profit Dropping Centre - Goonj Foundation',
        isVerified: true,
        isSampleData: false,
        rating: 4.9,
      ),
    ]);
  }

  void _seedKabadiwalaServices() {
    _kabadiwalaServices.addAll([
      // 1. Kabadify (Doorstep Scrap Pickup Platform)
      const KabadiwalaServiceModel(
        id: 'SRV-BLR-01',
        name: 'Kabadify',
        serviceType: 'Doorstep Scrap Pickup Platform',
        description:
            'On-demand doorstep scrap collection operating across Bengaluru with electronic weighing scales and instant digital UPI payments.',
        acceptedMaterials: [
          'Plastic',
          'Paper & Cardboard',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Glass',
          'Corrugated Boxes',
          'Newspapers',
          'PET Bottles',
          'Aluminium Cans',
          'Brass',
          'Copper',
          'Appliances',
        ],
        rejectedMaterials: [
          'Food Waste',
          'Soiled Tissues',
          'Biohazard / Medical Waste',
          'Sanitary Waste',
          'Hazardous Chemicals',
        ],
        geographicCoverage: 'Pan-Bengaluru (Whitefield, Koramangala, Indiranagar, HSR Layout, Electronic City, Jayanagar)',
        operatesInBengaluru: true,
        coverageNotes: 'Active across all major Bengaluru residential areas and tech corridors.',
        operatingHours: 'Mon - Sun: 9:00 AM - 7:00 PM (Scheduled Slot)',
        websiteUrl: 'https://kabadify.com',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.kabadify.user',
        bookingUrl: 'https://kabadify.com',
        isVerified: true,
        rating: 4.8,
        sourceReference: 'Verified Bengaluru Scrap Pickup Platform',
        pickupInstructions: [
          'Schedule doorstep scrap collection via the official Kabadify portal or app.',
          'Keep dry paper and cartons bundled together.',
          'Ensure scrap materials are clean, dry, and segregated from household wet waste.',
        ],
      ),

      // 2. KabadCart (Digital Scrap Aggregator)
      const KabadiwalaServiceModel(
        id: 'SRV-BLR-02',
        name: 'KabadCart',
        serviceType: 'Digital Scrap Aggregator & Pickup',
        description:
            'Bengaluru-based digital scrap aggregator providing transparent rates for dry recyclables, e-waste, and scrap metals from households and gated societies.',
        acceptedMaterials: [
          'Paper & Cardboard',
          'Metals',
          'Plastic',
          'Electronic Waste (E-Waste)',
          'Iron',
          'Steel',
          'Aluminium',
          'Old Books',
          'Batteries',
          'Old Electronics',
        ],
        rejectedMaterials: [
          'Wet Kitchen Garbage',
          'Broken Window Glass',
          'Soiled Diapers / Tissues',
          'Medical Waste',
        ],
        geographicCoverage: 'Bengaluru Urban (East, South, North Municipal Zones)',
        operatesInBengaluru: true,
        coverageNotes: 'Active across Bengaluru Urban wards, communities, and apartment complexes.',
        operatingHours: 'Daily: 8:30 AM - 6:30 PM (Doorstep Collection)',
        websiteUrl: 'https://kabadcart.com',
        bookingUrl: 'https://kabadcart.com',
        isVerified: true,
        rating: 4.7,
        sourceReference: 'Verified Bengaluru Digital Scrap Aggregator',
        pickupInstructions: [
          'Book on-demand doorstep scrap pickup through the KabadCart web portal.',
          'Scrap items are weighed on certified electronic scales at your premises.',
          'Keep items stored in dry conditions prior to collection executive arrival.',
        ],
      ),

      // 3. Ecocrew (Circularity & Recycling Pickup)
      const KabadiwalaServiceModel(
        id: 'SRV-BLR-03',
        name: 'Ecocrew',
        serviceType: 'Circularity & Recyclables Pickup App',
        description:
            'Tech-enabled circular waste management platform collecting dry recyclables, multilayer packaging, plastics, and e-waste directly from households with carbon credits.',
        acceptedMaterials: [
          'Plastic',
          'Paper & Cardboard',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Multi-Layer / Composite Materials',
          'PET Bottles',
          'Flexible Packaging',
          'Beverage Cans',
        ],
        rejectedMaterials: [
          'Household Wet Organic Waste',
          'Biomedical Waste',
          'Hazardous Chemicals',
        ],
        geographicCoverage: 'Pan-Bengaluru Urban Zones & Delhi NCR',
        operatesInBengaluru: true,
        coverageNotes: 'Doorstep collection available across Bengaluru and Delhi NCR.',
        operatingHours: 'Mon - Sat: 9:00 AM - 6:00 PM',
        websiteUrl: 'https://ecocrew.in',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.ecocrew.app',
        appStoreUrl: 'https://apps.apple.com/in/app/ecocrew/id1578330756',
        bookingUrl: 'https://ecocrew.in',
        isVerified: true,
        rating: 4.9,
        sourceReference: 'Verified Circularity Platform - Ecocrew',
        pickupInstructions: [
          'Request doorstep collection slot via Ecocrew mobile app or website.',
          'Empty, rinse, and dry beverage bottles and containers.',
          'Separate rigid plastics from multi-layer packaging pouches.',
        ],
      ),

      // 4. ScrapUncle (Online Kabadiwala - Delhi NCR)
      const KabadiwalaServiceModel(
        id: 'SRV-NCR-04',
        name: 'ScrapUncle',
        serviceType: 'Online Kabadiwala & Scrap Pickup Platform',
        description:
            'Shark Tank India featured doorstep scrap collection service for dry recyclables, electronics, and heavy appliances with ISO-certified electronic weighing scales.',
        acceptedMaterials: [
          'Paper & Cardboard',
          'Plastic',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Old Appliances',
          'Cartons',
          'Magazines',
          'Iron',
          'Copper',
          'Brass',
        ],
        rejectedMaterials: [
          'Wet Kitchen Waste',
          'Sanitary Waste',
          'Ceramics',
          'Wood',
          'Biohazard / Medical Waste',
        ],
        geographicCoverage: 'Delhi NCR (Delhi, Gurugram, Noida, Faridabad, Ghaziabad)',
        operatesInBengaluru: false,
        coverageNotes:
            'Regional Coverage: Active primarily in Delhi NCR. Listed as verified scrap platform for North India; does NOT currently service Bengaluru doorstep pickups.',
        operatingHours: 'Mon - Sun: 9:00 AM - 7:00 PM',
        websiteUrl: 'https://scrapuncle.com',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.scrapuncle.app',
        appStoreUrl: 'https://apps.apple.com/in/app/scrapuncle/id1593922872',
        bookingUrl: 'https://scrapuncle.com',
        isVerified: true,
        rating: 4.8,
        sourceReference: 'Verified Regional Platform - ScrapUncle (Delhi NCR)',
        pickupInstructions: [
          'Request doorstep collection through mobile app or official website.',
          'Doorstep pickup executive visits with digital weighing scale.',
          'Instant digital payment on weight confirmation.',
        ],
      ),

      // 5. The Kabadiwala (Central & Western India)
      const KabadiwalaServiceModel(
        id: 'SRV-IND-05',
        name: 'The Kabadiwala',
        serviceType: 'Smart Doorstep Scrap Collection Platform',
        description:
            'Pioneering smart scrap collection network offering scheduled pickups, transparent market rates, and certified recycling across central and western Indian cities.',
        acceptedMaterials: [
          'Paper & Cardboard',
          'Plastic',
          'Metals',
          'Electronic Waste (E-Waste)',
          'Glass',
          'Old Vehicles / Scraps',
          'Corrugated Boxes',
          'Appliances',
        ],
        rejectedMaterials: [
          'Wet Organic Waste',
          'Sanitary Waste',
          'Hospital Waste',
          'Hazardous Chemicals',
        ],
        geographicCoverage: 'Central & Western India (Bhopal, Indore, Raipur, Nagpur, Ahmedabad, Lucknow)',
        operatesInBengaluru: false,
        coverageNotes:
            'Regional Coverage: Operates across Central & Western India (Bhopal, Indore, Raipur, Nagpur). Informational reference for regional users; Bengaluru not currently covered.',
        operatingHours: 'Mon - Sat: 9:00 AM - 6:30 PM',
        websiteUrl: 'https://thekabadiwala.com',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.thekabadiwala.app',
        appStoreUrl: 'https://apps.apple.com/in/app/the-kabadiwala/id1458925501',
        bookingUrl: 'https://thekabadiwala.com',
        isVerified: true,
        rating: 4.7,
        sourceReference: 'Verified Regional Platform - The Kabadiwala',
        pickupInstructions: [
          'Schedule pickup via app, website, or toll-free line.',
          'Select scrap category and estimated weight.',
          'Certified field staff with electronic scale and cash/UPI payment.',
        ],
      ),

      // 6. Recykal (Pan-India Digital Waste Commerce)
      const KabadiwalaServiceModel(
        id: 'SRV-PAN-06',
        name: 'Recykal (Digital Waste Commerce)',
        serviceType: 'Waste Commerce & Recyclables Marketplace',
        description:
            'Pan-India digital waste-commerce network enabling bulk scrap collection, deposit refund systems, and institutional circular recycling drives.',
        acceptedMaterials: [
          'Plastic',
          'Paper & Cardboard',
          'Electronic Waste (E-Waste)',
          'Multi-Layer / Composite Materials',
          'Metals',
          'Tetra Pak',
          'Industrial Recyclables',
        ],
        rejectedMaterials: [
          'Domestic Mixed Garbage',
          'Biohazard / Medical Waste',
          'Sanitary Waste',
        ],
        geographicCoverage: 'Pan-India (Bengaluru, Hyderabad, Pune, Mumbai, Chennai, Delhi NCR)',
        operatesInBengaluru: true,
        coverageNotes: 'Pan-India presence including Bengaluru urban drives and deposit-return kiosks.',
        operatingHours: 'Mon - Fri: 9:30 AM - 6:30 PM',
        websiteUrl: 'https://recykal.com',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.recykal.consumer',
        bookingUrl: 'https://recykal.com',
        isVerified: true,
        rating: 4.8,
        sourceReference: 'Verified Pan-India Waste Commerce Platform - Recykal',
        pickupInstructions: [
          'Access consumer circularity drives and e-waste deposit drop-offs.',
          'Bulk collection booking available for apartments, universities, and commercial offices.',
          'Complete EPR traceability and certified recycling certificates.',
        ],
      ),
    ]);
  }
}
