import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/waste_passport_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase/firebase_service_manager.dart';

class PassportProvider extends ChangeNotifier {
  final List<WastePassportModel> _passports = [];
  WastePassportModel? _activePassport;

  String _searchQuery = '';
  RecyclabilityGrade? _selectedGradeFilter;
  String _selectedMaterialFilter = 'All';

  List<WastePassportModel> get passports => List.unmodifiable(_passports);
  WastePassportModel? get activePassport => _activePassport;
  String get searchQuery => _searchQuery;
  RecyclabilityGrade? get selectedGradeFilter => _selectedGradeFilter;
  String get selectedMaterialFilter => _selectedMaterialFilter;

  PassportProvider() {
    _seedDefaultPassports();
    _loadPersistedPassports();
  }

  void setActivePassport(WastePassportModel passport) {
    _activePassport = passport;
    notifyListeners();
  }

  /// Updates passport material subtype based on user physical verification
  Future<void> updatePassportMaterial({
    required String passportId,
    required String newSubType,
    String? newPrimaryMaterial,
  }) async {
    final index = _passports.indexWhere((p) => p.id == passportId);
    if (index == -1) return;

    final old = _passports[index];
    final updated = old.copyWith(
      subType: newSubType,
      primaryMaterial: newPrimaryMaterial ?? old.primaryMaterial,
      isAmbiguous: false,
      ambiguityReason: 'Confirmed by user inspection: $newSubType',
      confidenceScore: 0.95,
    );
    _passports[index] = updated;
    if (_activePassport?.id == passportId) {
      _activePassport = updated;
    }
    notifyListeners();
    await _persistPassports();

    try {
      if (FirebaseServiceManager().isInitialized) {
        await FirebaseServiceManager().database.savePassport(updated);
      }
    } catch (e) {
      debugPrint('[PassportProvider] Cloud update failed: $e');
    }
  }

  Future<void> addPassport(WastePassportModel passport) async {
    // Avoid duplicate IDs
    _passports.removeWhere((p) => p.id == passport.id);
    _passports.insert(0, passport);
    _activePassport = passport;
    notifyListeners();
    await _persistPassports();

    try {
      if (FirebaseServiceManager().isInitialized) {
        await FirebaseServiceManager().database.savePassport(passport);
      }
    } catch (e) {
      debugPrint('[PassportProvider] Cloud database sync skipped/fallback: $e');
    }
  }

  Future<void> deletePassport(String id) async {
    _passports.removeWhere((p) => p.id == id);
    if (_activePassport?.id == id) {
      _activePassport = _passports.isNotEmpty ? _passports.first : null;
    }
    notifyListeners();
    await _persistPassports();

    try {
      if (FirebaseServiceManager().isInitialized) {
        await FirebaseServiceManager().database.deletePassport(id);
      }
    } catch (e) {
      debugPrint('[PassportProvider] Cloud database delete skipped/fallback: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setGradeFilter(RecyclabilityGrade? grade) {
    _selectedGradeFilter = grade;
    notifyListeners();
  }

  void setMaterialFilter(String material) {
    _selectedMaterialFilter = material;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedGradeFilter = null;
    _selectedMaterialFilter = 'All';
    notifyListeners();
  }

  List<WastePassportModel> get filteredPassports {
    return _passports.where((p) {
      // 1. Search query match
      if (_searchQuery.isNotEmpty) {
        final matchesItem = p.itemName.toLowerCase().contains(_searchQuery);
        final matchesMaterial = p.primaryMaterial.toLowerCase().contains(_searchQuery);
        final matchesSub = p.subType.toLowerCase().contains(_searchQuery);
        final matchesId = p.id.toLowerCase().contains(_searchQuery);
        if (!matchesItem && !matchesMaterial && !matchesSub && !matchesId) {
          return false;
        }
      }

      // 2. Grade filter match
      if (_selectedGradeFilter != null && p.recyclabilityGrade != _selectedGradeFilter) {
        return false;
      }

      // 3. Material filter match
      if (_selectedMaterialFilter != 'All' &&
          !p.primaryMaterial.toLowerCase().contains(_selectedMaterialFilter.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _persistPassports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _passports.map((p) => p.toJson()).toList();
      await prefs.setString(AppConstants.keySavedPassports, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to persist passports: $e');
    }
  }

  Future<void> _loadPersistedPassports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedString = prefs.getString(AppConstants.keySavedPassports);
      if (storedString != null && storedString.isNotEmpty) {
        final decodedList = jsonDecode(storedString) as List;
        if (decodedList.isNotEmpty) {
          _passports.clear();
          for (final item in decodedList) {
            _passports.add(WastePassportModel.fromJson(item as Map<String, dynamic>));
          }
          _activePassport = _passports.first;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading saved passports: $e');
    }
  }

  void _seedDefaultPassports() {
    _passports.addAll([
      WastePassportModel(
        id: 'DWP-2026-0819',
        itemName: 'Single-Use Beverage Bottle',
        primaryMaterial: 'Plastic',
        subType: 'Polyethylene Terephthalate (PET - Type 1)',
        confidenceScore: 0.96,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years in landfill',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'PET Bottle Body': 88, 'PP Cap': 12},
        handlingInstructions: [
          'Unscrew the PP cap and empty any residual liquid completely.',
          'Rinse the bottle with clean water to remove sugars and dairy contaminants.',
          'Crush the bottle vertically to save volume in dry-waste collection bags.'
        ],
        circularityGuidance: {
          'reuse': 'Repurpose as an indoor plant self-watering reservoir, seed starter, or craft funnel.',
          'repair': 'Single-use container; structural repair not recommended. Prioritize upcycling.',
          'recycle': 'Highly recyclable. Deposit in the Blue Dry-Waste bin for flake pelletization into rPET.',
          'donate': 'Accumulate clean, crushed bottles in bulk for informal scrap collector livelihoods.',
          'return': 'Accepted in supermarket reverse vending machines and brand deposit return schemes.',
          'compost': 'Strictly non-biodegradable. Keep completely segregated from organic composting bins.',
          'safe_disposal': 'Contain in dry-waste bags to prevent mechanical degradation into marine microplastics.'
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      WastePassportModel(
        id: 'DWP-2026-0742',
        itemName: 'Corrugated Shipping Box',
        primaryMaterial: 'Paper & Cardboard',
        subType: 'Unbleached Kraft Fiber',
        confidenceScore: 0.94,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '2 - 3 months in soil',
        estimatedCarbonKg: '0.15 kg CO2e',
        materialComposition: {'Kraft Cardboard': 95, 'Adhesive Tape': 5},
        handlingInstructions: [
          'Peel off synthetic plastic packing tape and sticky shipping waybills.',
          'Flatten the box completely to reduce transport footprint.',
          'Keep dry; oil-stained or wet cardboard must never enter paper recycling.'
        ],
        circularityGuidance: {
          'reuse': 'Ideal for household moving, attic organization, or cardboard sheet mulching in gardens.',
          'repair': 'Reinforce structural corners with brown kraft paper tape for multiple moving cycles.',
          'recycle': 'Deposit in the dry paper bin for mechanical repulping into recycled linerboard.',
          'donate': 'Offer to local book vendors or small parcel businesses needing sturdy packaging.',
          'return': 'Many e-commerce hubs and courier offices accept clean boxes for reuse.',
          'compost': 'Clean, shredded brown cardboard is an exceptional carbon source for home composting.',
          'safe_disposal': 'Ensure cardboard contaminated with toxic motor oil or paint is routed to hazmat bins.'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      WastePassportModel(
        id: 'DWP-2026-0618',
        itemName: 'Rechargeable Li-Ion Battery Pack',
        primaryMaterial: 'Electronic Waste (E-Waste)',
        subType: 'Lithium-Cobalt Oxide Cell',
        confidenceScore: 0.92,
        recyclabilityGrade: RecyclabilityGrade.E,
        degradationTime: 'Non-biodegradable (Severe toxicity)',
        estimatedCarbonKg: '1.40 kg CO2e',
        materialComposition: {'Lithium & Cobalt Cathode': 35, 'Graphite Anode': 25, 'Aluminium & Copper Shell': 40},
        handlingInstructions: [
          'DANGER: Do NOT puncture, crush, or expose to heat or water.',
          'Tape exposed terminals with non-conductive electrical tape immediately.',
          'Never place in municipal curbside dry or wet waste bins.'
        ],
        circularityGuidance: {
          'reuse': 'Check cell voltage with a multimeter for secondary low-current solar battery banks.',
          'repair': 'Authorized technician battery refurbishment centers can replace worn internal BMS circuits.',
          'recycle': 'Take only to authorized e-waste hydrometallurgical recycling facilities for cobalt/lithium extraction.',
          'donate': 'Not recommended for casual donation due to internal thermal runaway fire hazards.',
          'return': 'Return directly to OEM retail drop-off kiosks (e.g. smartphone/laptop service centers).',
          'compost': 'STRICTLY FORBIDDEN. Releases toxic heavy metals into soil and groundwater.',
          'safe_disposal': 'Store in a cool, non-flammable container until handed over to certified e-waste aggregators.'
        },
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
    _activePassport = _passports.first;
    notifyListeners();
  }
}
