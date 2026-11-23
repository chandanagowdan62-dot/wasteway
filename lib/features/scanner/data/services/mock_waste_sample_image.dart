import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Generates valid, standards-compliant encoded image bytes for offline mock demonstrations.
/// Guarantees cross-platform decodability in Flutter Web (CanvasKit/HTML) and Android/iOS.
class MockWasteSampleImage {
  static final Map<String, Uint8List> _cache = {};

  /// Returns valid JPEG byte payload representing the specified mock item.
  static Uint8List getSampleImageBytes(String sampleName) {
    final key = sampleName.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    img.ColorRgb8 primaryColor;
    img.ColorRgb8 accentColor;

    if (key.contains('battery')) {
      primaryColor = img.ColorRgb8(198, 40, 40); // Deep red
      accentColor = img.ColorRgb8(239, 154, 154);
    } else if (key.contains('can') || key.contains('soda')) {
      primaryColor = img.ColorRgb8(69, 90, 100); // Blue-grey slate
      accentColor = img.ColorRgb8(176, 190, 197);
    } else if (key.contains('box') || key.contains('cardboard') || key.contains('shipping')) {
      primaryColor = img.ColorRgb8(121, 85, 72); // Warm brown
      accentColor = img.ColorRgb8(188, 170, 164);
    } else if (key.contains('chip') || key.contains('snack') || key.contains('wrapper')) {
      primaryColor = img.ColorRgb8(230, 81, 0); // Deep Orange
      accentColor = img.ColorRgb8(255, 183, 77);
    } else if (key.contains('tissue') || key.contains('napkin')) {
      primaryColor = img.ColorRgb8(96, 125, 139); // Blue-grey / parchment
      accentColor = img.ColorRgb8(207, 216, 220);
    } else {
      // Default / Bottle
      primaryColor = img.ColorRgb8(46, 125, 50); // Eco green
      accentColor = img.ColorRgb8(165, 214, 167);
    }

    // Generate a 320x240 image with decorative borders and center box
    final image = img.Image(width: 320, height: 240);
    img.fill(image, color: primaryColor);

    // Draw inner accent border
    for (int x = 12; x < 308; x++) {
      image.setPixel(x, 12, accentColor);
      image.setPixel(x, 228, accentColor);
    }
    for (int y = 12; y < 228; y++) {
      image.setPixel(12, y, accentColor);
      image.setPixel(308, y, accentColor);
    }

    // Draw a center card outline
    for (int x = 60; x < 260; x++) {
      image.setPixel(x, 60, accentColor);
      image.setPixel(x, 180, accentColor);
    }
    for (int y = 60; y < 180; y++) {
      image.setPixel(60, y, accentColor);
      image.setPixel(260, y, accentColor);
    }

    // Encode to standard JPEG
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
    _cache[key] = bytes;
    return bytes;
  }
}
