import '../models/civic_location_model.dart';
import '../models/municipal_authority_model.dart';

/// Registry and resolver for municipal authorities based on civic locations.
///
/// Designed with open extensible architecture:
/// - Bengaluru / BBMP is fully verified with ward mapping.
/// - Unrecognized locations gracefully resolve to `MunicipalAuthorityModel.unverified`
///   with Central Swachhata Urban routing.
class CivicAuthorityRegistry {
  CivicAuthorityRegistry._();

  static final Map<String, String> _bengaluruPinToWard = {
    '560001': 'Ward 110 - Sampangiram Nagar (East Zone)',
    '560002': 'Ward 109 - Chickpete (South Zone)',
    '560003': 'Ward 65 - Kadu Malleshwaram (West Zone)',
    '560004': 'Ward 142 - Sunkenahalli / Basavanagudi (South Zone)',
    '560008': 'Ward 111 - Shantala Nagar (East Zone)',
    '560011': 'Ward 144 - Siddapura / Jayanagar (South Zone)',
    '560025': 'Ward 111 - Richmond Town / East Zone',
    '560034': 'Ward 151 - Koramangala (South Zone)',
    '560038': 'Ward 112 - Domlur / Indiranagar (East Zone)',
    '560047': 'Ward 114 - Neelasandra / Austin Town (East Zone)',
    '560058': 'Ward 40 - Peenya Industrial Area (Dasarahalli Zone)',
    '560064': 'Ward 4 - Yelahanka Satellite Town (Yelahanka Zone)',
    '560066': 'Ward 84 - Hagadur / Whitefield (Mahadevapura Zone)',
    '560068': 'Ward 174 - Madivala / Bommanahalli (Bommanahalli Zone)',
    '560076': 'Ward 176 - BTM Layout (South Zone)',
    '560078': 'Ward 177 - JP Nagar (South Zone)',
    '560085': 'Ward 161 - Hosakerehalli / Banashankari (South Zone)',
    '560092': 'Ward 7 - Byatarayanapura (Yelahanka Zone)',
    '560095': 'Ward 151 - Koramangala 4th/8th Block (South Zone)',
    '560100': 'Ward 192 - Begur / Electronic City (Bommanahalli Zone)',
    '560103': 'Ward 150 - Bellandur (Mahadevapura Zone)',
  };

  static final Map<String, String> _bengaluruLocalityToWard = {
    'indiranagar': 'Ward 112 - Domlur / Indiranagar (East Zone)',
    'domlur': 'Ward 112 - Domlur (East Zone)',
    'koramangala': 'Ward 151 - Koramangala (South Zone)',
    'whitefield': 'Ward 84 - Hagadur / Whitefield (Mahadevapura Zone)',
    'jayanagar': 'Ward 144 - Siddapura / Jayanagar (South Zone)',
    'malleshwaram': 'Ward 65 - Kadu Malleshwaram (West Zone)',
    'peenya': 'Ward 40 - Peenya Industrial Area (Dasarahalli Zone)',
    'btm': 'Ward 176 - BTM Layout (South Zone)',
    'bellandur': 'Ward 150 - Bellandur (Mahadevapura Zone)',
    'yelahanka': 'Ward 4 - Yelahanka Satellite Town (Yelahanka Zone)',
    'basavanagudi': 'Ward 142 - Sunkenahalli / Basavanagudi (South Zone)',
    'mg road': 'Ward 111 - Shantala Nagar (East Zone)',
    'brigade road': 'Ward 111 - Shantala Nagar (East Zone)',
    'hebbal': 'Ward 21 - Hebbal (Yelahanka Zone)',
    'marathahalli': 'Ward 85 - Doddanekkundi / Marathahalli (Mahadevapura Zone)',
    'rajajinagar': 'Ward 99 - Rajajinagar (West Zone)',
  };

  /// Resolves the appropriate municipal authority based on the given location.
  /// If the location is outside verified regions, returns `MunicipalAuthorityModel.unverified`.
  static MunicipalAuthorityModel resolveAuthority(CivicLocationModel location) {
    // 1. Check Bengaluru / BBMP
    if (_isBengaluru(location)) {
      final ward = _resolveBengaluruWard(location);
      return MunicipalAuthorityModel.bbmp(ward: ward);
    }

    // 2. Check Mysuru (MCC)
    if (_isMysuru(location)) {
      return const MunicipalAuthorityModel(
        id: 'mcc_mysuru',
        name: 'Mysuru City Corporation (MCC)',
        localBodyType: 'City Municipal Corporation',
        jurisdiction: 'Mysuru, Karnataka',
        state: 'Karnataka',
        isVerified: true,
        matchedWard: null,
        helplineNumber: '0821-2418800',
        helplineAlternate: '0821-2440890',
        portalUrl: 'https://mysurucitycorporation.co.in',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.ichangemycity.swachhbharat',
        appStoreUrl: null,
        swachhataUrl: 'https://swachhatah-urban.gov.in',
        swachhataHelpline: '1969',
        bswmlUrl: null,
        routingInstructions:
            'File civic grievances on Mysuru City Corporation portal or reach MCC helpline at 0821-2418800.',
      );
    }

    // 3. Check Delhi (MCD)
    if (_isDelhi(location)) {
      return const MunicipalAuthorityModel(
        id: 'mcd_delhi',
        name: 'Municipal Corporation of Delhi (MCD)',
        localBodyType: 'Municipal Corporation',
        jurisdiction: 'National Capital Territory of Delhi',
        state: 'Delhi',
        isVerified: true,
        matchedWard: null,
        helplineNumber: '155305',
        helplineAlternate: '011-23220010',
        portalUrl: 'https://mcdonline.nic.in',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.mcd.mcd311',
        appStoreUrl: null,
        swachhataUrl: 'https://swachhatah-urban.gov.in',
        swachhataHelpline: '1969',
        bswmlUrl: null,
        routingInstructions:
            'Report waste and sanitation grievances on MCD 311 portal (mcdonline.nic.in) or call MCD helpline 155305.',
      );
    }

    // 4. Default: Return unverified authority (do NOT assume BBMP!)
    return MunicipalAuthorityModel.unverified(location);
  }

  static bool _isBengaluru(CivicLocationModel loc) {
    // Check postal code (Bengaluru PIN codes start with 560)
    final pin = loc.postalCode?.trim() ?? '';
    if (pin.length >= 3 && pin.startsWith('560')) return true;

    // Check city
    final city = (loc.city ?? '').toLowerCase();
    if (city.contains('bengaluru') || city.contains('bangalore')) return true;

    // Check address and locality strings
    final addr = loc.address.toLowerCase();
    final locality = (loc.locality ?? '').toLowerCase();
    if (addr.contains('bengaluru') ||
        addr.contains('bangalore') ||
        locality.contains('bengaluru') ||
        locality.contains('bangalore')) {
      return true;
    }

    // Check known Bengaluru localities
    for (final key in _bengaluruLocalityToWard.keys) {
      if (addr.contains(key) || locality.contains(key)) {
        return true;
      }
    }

    // Check GPS coordinates within Bengaluru bounding box
    // Lat: 12.75 to 13.20, Lng: 77.40 to 77.80
    if (loc.latitude != null && loc.longitude != null) {
      final lat = loc.latitude!;
      final lng = loc.longitude!;
      if (lat >= 12.75 && lat <= 13.20 && lng >= 77.40 && lng <= 77.80) {
        return true;
      }
    }

    return false;
  }

  static String? _resolveBengaluruWard(CivicLocationModel loc) {
    // 1. PIN code matching
    final pin = loc.postalCode?.trim() ?? '';
    if (_bengaluruPinToWard.containsKey(pin)) {
      return _bengaluruPinToWard[pin];
    }

    // Check if PIN is present inside address text
    for (final entry in _bengaluruPinToWard.entries) {
      if (loc.address.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Locality matching
    final combined = '${loc.locality ?? ''} ${loc.landmark ?? ''} ${loc.address}'.toLowerCase();
    for (final entry in _bengaluruLocalityToWard.entries) {
      if (combined.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'BBMP Ward Unspecified (Bengaluru Urban Jurisdiction)';
  }

  static bool _isMysuru(CivicLocationModel loc) {
    final pin = loc.postalCode?.trim() ?? '';
    if (pin.startsWith('570')) return true;

    final city = (loc.city ?? '').toLowerCase();
    final addr = loc.address.toLowerCase();
    return city.contains('mysuru') || city.contains('mysore') || addr.contains('mysuru') || addr.contains('mysore');
  }

  static bool _isDelhi(CivicLocationModel loc) {
    final pin = loc.postalCode?.trim() ?? '';
    if (pin.startsWith('110')) return true;

    final city = (loc.city ?? '').toLowerCase();
    final addr = loc.address.toLowerCase();
    return city.contains('delhi') || addr.contains('delhi');
  }
}
