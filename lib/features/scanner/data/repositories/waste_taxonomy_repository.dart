import '../data_sources/waste_taxonomy_data.dart';
import '../../domain/models/waste_taxonomy_item.dart';

/// Repository providing structured access, lookup, search, and confusion-resolution
/// over the WasteWay Waste Taxonomy Knowledge Base (100 distinct items).
class WasteTaxonomyRepository {
  final List<WasteTaxonomyItem> _items = WasteTaxonomyData.items;

  List<WasteTaxonomyItem> get allItems => List.unmodifiable(_items);

  int get totalItemCount => _items.length;

  WasteTaxonomyItem? findById(String id) {
    try {
      return _items.firstWhere(
        (item) => item.id.toUpperCase() == id.trim().toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<WasteTaxonomyItem> getItemsByCategory(String category) {
    final lower = category.trim().toLowerCase();
    return _items.where((item) {
      return item.mainCategory.toLowerCase() == lower ||
          item.mainCategory.toLowerCase().contains(lower);
    }).toList();
  }

  List<String> getAllCategories() {
    return _items.map((e) => e.mainCategory).toSet().toList();
  }

  /// Searches for the most relevant taxonomy item matching a textual query,
  /// visual clue, or item name using multi-tier token and keyword scoring.
  WasteTaxonomyItem? searchBestMatch(String query) {
    if (query.trim().isEmpty) return null;
    final normalized = query.trim().toLowerCase();

    // 1. Direct ID match
    for (final item in _items) {
      if (item.id.toLowerCase() == normalized) return item;
    }

    // 2. Direct Common Name match
    for (final item in _items) {
      for (final name in item.commonNames) {
        if (name.toLowerCase() == normalized) return item;
      }
    }

    // 3. SubCategory match
    for (final item in _items) {
      if (item.subCategory.toLowerCase() == normalized) return item;
    }

    // 4. Token & Keyword scoring
    final stopWords = {'with', 'and', 'the', 'for', 'from', 'made', 'this', 'that', 'into'};
    final queryTokens = normalized
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !stopWords.contains(t))
        .toList();

    WasteTaxonomyItem? bestItem;
    int highestScore = 0;

    for (final item in _items) {
      int score = 0;

      // Check common names
      for (final name in item.commonNames) {
        final nameLower = name.toLowerCase();
        if (normalized.contains(nameLower)) {
          score += 15;
        }
        for (final token in queryTokens) {
          if (nameLower.contains(token)) {
            score += 6;
          }
        }
      }

      // Check subcategory
      final subLower = item.subCategory.toLowerCase();
      for (final token in queryTokens) {
        if (subLower.contains(token)) score += 4;
      }

      // Check main category
      final catLower = item.mainCategory.toLowerCase();
      for (final token in queryTokens) {
        if (catLower.contains(token)) score += 3;
      }

      // Check description and distinguishing characteristics
      final distLower = item.distinguishingCharacteristics.toLowerCase();
      final descLower = item.description.toLowerCase();
      for (final token in queryTokens) {
        if (distLower.contains(token)) score += 2;
        if (descLower.contains(token)) score += 1;
      }

      if (score > highestScore) {
        highestScore = score;
        bestItem = item;
      }
    }

    if (highestScore >= 4) {
      return bestItem;
    }

    return null;
  }

  /// Returns 3-5 alternative candidates for a given query or category
  /// to support the user confirmation sheet when uncertainty is detected.
  List<WasteTaxonomyItem> getAlternativeCandidates(String queryOrCategory, {int limit = 5}) {
    final normalized = queryOrCategory.trim().toLowerCase();
    final List<WasteTaxonomyItem> results = [];

    // Find primary match
    final primary = searchBestMatch(normalized);
    if (primary != null) {
      results.add(primary);
      // Add items from similar categories
      for (final similarName in primary.similarCategoriesToAvoidConfusingWith) {
        final similarItem = searchBestMatch(similarName);
        if (similarItem != null && !results.any((e) => e.id == similarItem.id)) {
          results.add(similarItem);
        }
      }
    }

    // Fill with category peers if needed
    for (final item in _items) {
      if (results.length >= limit) break;
      if (!results.any((e) => e.id == item.id)) {
        if (item.mainCategory.toLowerCase().contains(normalized) ||
            normalized.contains(item.mainCategory.toLowerCase())) {
          results.add(item);
        }
      }
    }

    // Default fallbacks if still empty
    if (results.isEmpty) {
      return [
        findById('PAPR-001')!, // Tissue
        findById('CMPL-001')!, // Chips packet
        findById('PLAS-001')!, // PET bottle
        findById('PAPR-002')!, // Cardboard
        findById('METL-001')!, // Aluminium can
      ].take(limit).toList();
    }

    return results.take(limit).toList();
  }

  /// Specific Domain Confusion Resolver:
  /// Evaluates ambiguous visual clues and returns the verified taxonomy entry,
  /// preventing common misclassifications like tissue -> water bottle or
  /// chips wrapper -> lithium battery.
  WasteTaxonomyItem resolveAmbiguity({
    required String visualClue,
    required bool hasVisibleTerminals,
    required bool hasMetallicFoilInterior,
    required bool isFibrousAbsorbent,
  }) {
    final clue = visualClue.toLowerCase();

    // Confusion Rule 1: Tissue vs Plastic
    if (isFibrousAbsorbent ||
        clue.contains('tissue') ||
        clue.contains('napkin') ||
        clue.contains('wipe')) {
      return findById('PAPR-001')!; // Used Paper Tissue
    }

    // Confusion Rule 2: Chips Wrapper vs Lithium Battery
    if (hasMetallicFoilInterior ||
        clue.contains('chips') ||
        clue.contains('wrapper') ||
        clue.contains('snack')) {
      return findById('CMPL-001')!; // Multi-layer Snack Pouch
    }

    // Confusion Rule 3: Battery vs Everyday Metal
    if (clue.contains('battery') || clue.contains('cell')) {
      if (hasVisibleTerminals || clue.contains('18650') || clue.contains('aa')) {
        return findById('BATT-001')!; // Lithium cylindrical cell
      }
    }

    // Confusion Rule 4: Clear Glass vs PET Bottle
    if (clue.contains('clear') || clue.contains('transparent')) {
      if (clue.contains('glass') || clue.contains('jar') || clue.contains('heavy')) {
        return findById('GLAS-001')!; // Clear glass bottle
      }
      return findById('PLAS-001')!; // PET bottle
    }

    // Fallback to general search
    return searchBestMatch(clue) ?? findById('PLAS-001')!;
  }
}
