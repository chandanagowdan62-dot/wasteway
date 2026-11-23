import 'civic_location_model.dart';

/// Represents a municipal authority, local body, or civic grievance department
class MunicipalAuthorityModel {
  final String id;
  final String name;
  final String localBodyType;
  final String jurisdiction;
  final String state;
  final bool isVerified;
  final String? matchedWard;
  final String helplineNumber;
  final String? helplineAlternate;
  final String portalUrl;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String swachhataUrl;
  final String swachhataHelpline;
  final String? bswmlUrl;
  final String routingInstructions;

  const MunicipalAuthorityModel({
    required this.id,
    required this.name,
    required this.localBodyType,
    required this.jurisdiction,
    required this.state,
    required this.isVerified,
    this.matchedWard,
    required this.helplineNumber,
    this.helplineAlternate,
    required this.portalUrl,
    this.playStoreUrl,
    this.appStoreUrl,
    this.swachhataUrl = 'https://swachhatah-urban.gov.in',
    this.swachhataHelpline = '1969',
    this.bswmlUrl,
    required this.routingInstructions,
  });

  /// Factory for BBMP (Bengaluru)
  factory MunicipalAuthorityModel.bbmp({String? ward, String? zone}) {
    final wardText = ward != null ? (zone != null ? '$ward ($zone)' : ward) : null;
    return MunicipalAuthorityModel(
      id: 'bbmp',
      name: 'Bruhat Bengaluru Mahanagara Palike (BBMP)',
      localBodyType: 'City Municipal Corporation',
      jurisdiction: 'Bengaluru Urban, Karnataka',
      state: 'Karnataka',
      isVerified: true,
      matchedWard: wardText,
      helplineNumber: '1533',
      helplineAlternate: '080-22660000',
      portalUrl: 'https://bbmpsahaaya.karnataka.gov.in',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.bbmp.sahaaya',
      appStoreUrl: 'https://apps.apple.com/in/app/namma-bengaluru-sahaaya/id1450239082',
      bswmlUrl: 'https://bswml.co.in',
      routingInstructions:
          'File complaint directly on BBMP Sahaaya 2.0 portal (bbmpsahaaya.karnataka.gov.in) or call 24x7 BBMP Control Room at 1533.',
    );
  }

  /// Factory for unmapped / unverified authorities
  factory MunicipalAuthorityModel.unverified([CivicLocationModel? location]) {
    final region = location?.city ?? location?.state ?? 'your area';
    return MunicipalAuthorityModel(
      id: 'unverified',
      name: 'Authority Unverified',
      localBodyType: 'Unknown / Unmapped Local Body',
      jurisdiction: location?.fullDisplayLocation ?? 'Location not matched to verified municipal database',
      state: location?.state ?? 'India',
      isVerified: false,
      matchedWard: null,
      helplineNumber: '1969',
      helplineAlternate: null,
      portalUrl: 'https://swachhatah-urban.gov.in',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.ichangemycity.swachhbharat',
      appStoreUrl: 'https://apps.apple.com/in/app/swachhata-mohua/id1143890695',
      swachhataUrl: 'https://swachhatah-urban.gov.in',
      swachhataHelpline: '1969',
      bswmlUrl: null,
      routingInstructions:
          'No verified local municipal portal is configured for $region. Route your grievance via Ministry of Housing & Urban Affairs Swachhata portal or helpline 1969.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localBodyType': localBodyType,
      'jurisdiction': jurisdiction,
      'state': state,
      'isVerified': isVerified,
      'matchedWard': matchedWard,
      'helplineNumber': helplineNumber,
      'helplineAlternate': helplineAlternate,
      'portalUrl': portalUrl,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'swachhataUrl': swachhataUrl,
      'swachhataHelpline': swachhataHelpline,
      'bswmlUrl': bswmlUrl,
      'routingInstructions': routingInstructions,
    };
  }

  factory MunicipalAuthorityModel.fromJson(Map<String, dynamic> json) {
    return MunicipalAuthorityModel(
      id: json['id'] as String? ?? 'unverified',
      name: json['name'] as String? ?? 'Authority Unverified',
      localBodyType: json['localBodyType'] as String? ?? 'Local Body',
      jurisdiction: json['jurisdiction'] as String? ?? '',
      state: json['state'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      matchedWard: json['matchedWard'] as String?,
      helplineNumber: json['helplineNumber'] as String? ?? '1969',
      helplineAlternate: json['helplineAlternate'] as String?,
      portalUrl: json['portalUrl'] as String? ?? 'https://swachhatah-urban.gov.in',
      playStoreUrl: json['playStoreUrl'] as String?,
      appStoreUrl: json['appStoreUrl'] as String?,
      swachhataUrl: json['swachhataUrl'] as String? ?? 'https://swachhatah-urban.gov.in',
      swachhataHelpline: json['swachhataHelpline'] as String? ?? '1969',
      bswmlUrl: json['bswmlUrl'] as String?,
      routingInstructions: json['routingInstructions'] as String? ?? '',
    );
  }
}
