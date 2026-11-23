import 'package:shared_preferences/shared_preferences.dart';

/// Safe configuration manager for WasteWay AI Services.
/// Reads API keys and model configuration from user runtime settings
/// (stored in private app SharedPreferences) or from build-time `--dart-define`.
/// 
/// Note: Build-time variables (`--dart-define`) are embedded in compiled client code
/// and are NOT considered cryptographically private. For safe production deployments,
/// prefer entering keys at runtime into local private storage or routing calls
/// through an authenticated backend proxy.
class AIConfig {
  static const String defaultModel = 'gemini-3.8-flash';
  static const List<String> supportedModels = [
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-3.5-flash-lite',
  ];

  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _envModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: defaultModel);
  static const String _prefApiKey = 'wasteway_user_gemini_api_key';
  static const String _prefForceMock = 'wasteway_force_mock_mode';
  static const String _prefModel = 'wasteway_gemini_model';

  static String _runtimeApiKey = '';
  static bool _forceMockMode = false;
  static String _runtimeModel = defaultModel;

  /// Initializes runtime preferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeApiKey = prefs.getString(_prefApiKey) ?? '';
    _forceMockMode = prefs.getBool(_prefForceMock) ?? false;

    // Load configured model or fall back to environment / default
    final savedModel = prefs.getString(_prefModel) ?? _envModel;
    // Auto-migrate retired models if previously saved
    if (savedModel.isEmpty ||
        savedModel == 'gemini-2.0-flash' ||
        savedModel == 'gemini-1.5-flash' ||
        savedModel == 'gemini-1.5-pro') {
      _runtimeModel = defaultModel;
      await prefs.setString(_prefModel, defaultModel);
    } else {
      _runtimeModel = savedModel;
    }
  }

  /// Returns active API key (Runtime override takes precedence over compile-time environment)
  static String get apiKey {
    if (_runtimeApiKey.trim().isNotEmpty) {
      return _runtimeApiKey.trim();
    }
    return _envApiKey.trim();
  }

  /// Returns true if a valid Gemini API key is configured
  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Returns active Gemini model ID (e.g. 'gemini-3.8-flash')
  static String get modelName => _runtimeModel.trim().isNotEmpty ? _runtimeModel.trim() : defaultModel;

  /// Returns a user-friendly display label for the active model
  static String get modelDisplayName {
    switch (modelName) {
      case 'gemini-2.5-flash':
        return 'Gemini 2.5 Flash (Recommended)';
      case 'gemini-2.0-flash':
        return 'Gemini 2.0 Flash (Fast)';
      case 'gemini-1.5-flash':
        return 'Gemini 1.5 Flash (Multimodal)';
      case 'gemini-3.8-flash':
        return 'Gemini 3.8 Flash';
      case 'gemini-3.5-flash-lite':
        return 'Gemini 3.5 Flash-Lite (Fast-Lite)';
      default:
        return modelName;
    }
  }

  /// Returns true if the user or environment explicitly forces offline mock simulation
  static bool get isForceMockMode => _forceMockMode;

  /// Sets runtime API key and persists to SharedPreferences
  static Future<void> setRuntimeApiKey(String key) async {
    _runtimeApiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, _runtimeApiKey);
  }

  /// Clears stored runtime API key
  static Future<void> clearRuntimeApiKey() async {
    _runtimeApiKey = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
  }

  /// Sets configured Gemini model ID and persists to SharedPreferences
  static Future<void> setModelName(String model) async {
    final clean = model.trim().isEmpty ? defaultModel : model.trim();
    _runtimeModel = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModel, clean);
  }

  /// Resets model name to default
  static Future<void> resetModelName() async {
    await setModelName(defaultModel);
  }

  /// Toggles forced offline mock simulation mode
  static Future<void> setForceMockMode(bool force) async {
    _forceMockMode = force;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefForceMock, force);
  }
}
