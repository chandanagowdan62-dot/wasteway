import 'package:flutter/foundation.dart';

class HomeProvider extends ChangeNotifier {
  int _wasteClassifiedCount = 4;
  int _pathwaysAccessedCount = 8;

  int get scannedCount => _wasteClassifiedCount;
  int get wasteClassifiedCount => _wasteClassifiedCount;
  double get divertedKg => (_wasteClassifiedCount * 0.35);
  int get reportsSubmitted => 2;
  int get pathwaysAccessedCount => _pathwaysAccessedCount;

  final List<String> _ecoTips = [
    'Rinse and dry plastic milk pouches before dropping them in the dry-waste bin to prevent fungal contamination of dry paper recyclables.',
    'Tissues and napkins are made of ultra-short cellulose fibers and cannot be recycled into new paper; compost food-soiled tissues, dispose personal hygiene tissues in sanitary trash.',
    'Multi-layer chips packets (BOPP + vacuum-sputtered aluminium) cannot be recycled with clear PET bottles; route them to dry waste collection centres for cement kiln co-processing.',
    'Lithium-ion batteries present severe thermal fire risks if crushed in garbage trucks. Always tape battery terminals with cello tape before taking them to authorized e-waste kiosks.',
    'Crushing plastic beverage bottles vertically with the cap screwed back on saves up to 70% of collection truck volume and prevents cap sorting loss.',
    'Greasy sections of pizza boxes should be torn off and composted; only clean, oil-free cardboard can be repulped into new cartons.',
    'Electronics should never enter regular municipal trash. Circuit boards contain toxic lead solder alongside recoverable precious metals.',
    'Clean aluminium kitchen foil can be scrunched into a baseball-sized sphere so automated magnetic eddy-current sorters can detect and recover it.',
    'Reusing glass jars for dry pantry spice storage eliminates the need for disposable plastic containers and keeps food moisture-free.',
    'Cotton clothes with slight tears can be patched or donated to textile upcyclers like Goonj rather than going to landfills.',
    'Used coffee grounds and steeped tea leaves are rich in nitrogen; sprinkle them directly into flower beds or mix into kitchen wet compost.',
    'Check the bottom of plastic containers for Resin Identification Codes 1 (PET) and 2 (HDPE) - these have the highest scrap recovery value in India.',
  ];

  int _currentTipIndex = 0;
  String get currentDailyTip => _ecoTips[_currentTipIndex];

  void nextDailyTip() {
    _currentTipIndex = (_currentTipIndex + 1) % _ecoTips.length;
    notifyListeners();
  }

  void incrementScanStats([double weightKg = 0.25]) {
    _wasteClassifiedCount++;
    notifyListeners();
  }

  void incrementPathwaysAccessed() {
    _pathwaysAccessedCount++;
    notifyListeners();
  }
}
