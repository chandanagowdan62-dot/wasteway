/// Detailed location model for location-based civic waste reporting
class CivicLocationModel {
  final String address;
  final String? locality;
  final String? landmark;
  final String? postalCode;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final bool isGpsDetected;

  const CivicLocationModel({
    required this.address,
    this.locality,
    this.landmark,
    this.postalCode,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.isGpsDetected = false,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedCoordinates {
    if (!hasCoordinates) return 'Coordinates not attached';
    final latStr = latitude!.toStringAsFixed(4);
    final lngStr = longitude!.toStringAsFixed(4);
    return '$latStr° N, $lngStr° E';
  }

  /// Full formatted summary of the location
  String get fullDisplayLocation {
    final parts = <String>[];
    if (address.trim().isNotEmpty) parts.add(address.trim());
    if (locality != null && locality!.trim().isNotEmpty && !address.contains(locality!)) {
      parts.add(locality!.trim());
    }
    if (landmark != null && landmark!.trim().isNotEmpty && !address.contains(landmark!)) {
      parts.add('Landmark: ${landmark!.trim()}');
    }
    if (city != null && city!.trim().isNotEmpty && !address.contains(city!)) {
      parts.add(city!.trim());
    }
    if (postalCode != null && postalCode!.trim().isNotEmpty && !address.contains(postalCode!)) {
      parts.add('PIN: ${postalCode!.trim()}');
    }
    return parts.isEmpty ? 'Location unspecified' : parts.join(', ');
  }

  CivicLocationModel copyWith({
    String? address,
    String? locality,
    String? landmark,
    String? postalCode,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    bool? isGpsDetected,
  }) {
    return CivicLocationModel(
      address: address ?? this.address,
      locality: locality ?? this.locality,
      landmark: landmark ?? this.landmark,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isGpsDetected: isGpsDetected ?? this.isGpsDetected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'locality': locality,
      'landmark': landmark,
      'postalCode': postalCode,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'isGpsDetected': isGpsDetected,
    };
  }

  factory CivicLocationModel.fromJson(Map<String, dynamic> json) {
    return CivicLocationModel(
      address: json['address'] as String? ?? json['locationAddress'] as String? ?? '',
      locality: json['locality'] as String?,
      landmark: json['landmark'] as String?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isGpsDetected: json['isGpsDetected'] as bool? ?? false,
    );
  }
}
