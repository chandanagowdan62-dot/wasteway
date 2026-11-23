import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../../../core/config/ai_config.dart';
import '../../data/services/gemini_vision_service.dart';
import '../../data/services/mock_waste_sample_image.dart';
import '../providers/scanner_provider.dart';
import '../../../passport/presentation/providers/passport_provider.dart';
import '../../../passport/domain/models/waste_passport_model.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final scannerProvider = context.read<ScannerProvider>();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        scannerProvider.onImageSelected(bytes, file.name);
      }
    } catch (e) {
      scannerProvider.setError('Image selection error: ${e.toString()}');
    }
  }

  Future<bool?> _showSetupApiKeyPrompt() async {
    final controller = TextEditingController();
    bool isValidating = false;
    String? validationError;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text('Live AI Vision Setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WasteWay uses Google Gemini Multimodal AI Vision to inspect waste images for resin codes, polymers, and recycling pathways.',
                  style: TextStyle(fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Get a free Gemini API key in 30 seconds at aistudio.google.com and paste it below.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste, size: 20),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          controller.text = data!.text!.trim();
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationError!,
                            style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isValidating ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: isValidating
                  ? null
                  : () async {
                      Navigator.pop(ctx, null);
                      await _runOfflineSimulationAction();
                    },
              child: const Text('Run Offline Demo'),
            ),
            ElevatedButton(
              onPressed: isValidating
                  ? null
                  : () async {
                      final key = controller.text.trim();
                      if (key.isEmpty) {
                        setDialogState(() {
                          validationError = 'Please paste a valid Gemini API key or choose Run Offline Demo.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isValidating = true;
                        validationError = null;
                      });

                      final validation = await GeminiVisionService().validateModelAccess(
                        apiKey: key,
                        targetModel: AIConfig.modelName,
                      );

                      if (!validation.isValid) {
                        setDialogState(() {
                          isValidating = false;
                          validationError = validation.errorMessage ??
                              'API key validation failed. Please check your key from Google AI Studio.';
                        });
                        return;
                      }

                      // Persist validated key and active model
                      await AIConfig.setRuntimeApiKey(key);
                      if (validation.activeModel != null) {
                        await AIConfig.setModelName(validation.activeModel!);
                      }
                      await AIConfig.setForceMockMode(false);

                      if (ctx.mounted) {
                        Navigator.pop(ctx, true);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save & Run Live AI'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runPipeline() async {
    final scannerProvider = context.read<ScannerProvider>();
    final passportProvider = context.read<PassportProvider>();

    if (!AIConfig.hasApiKey && !AIConfig.isForceMockMode) {
      final shouldProceed = await _showSetupApiKeyPrompt();
      if (shouldProceed != true) {
        return;
      }
      if (mounted) setState(() {});
    }

    final passport = await scannerProvider.processAndClassify();
    if (passport != null && mounted) {
      if (passport.isAmbiguous || passport.confidenceScore < 0.75 || passport.isMixedWaste || passport.isSimulated) {
        await _showPrePassportConfirmationSheet(passport);
      } else {
        passportProvider.addPassport(passport);
        context.push(RouteNames.passportDetail);
      }
    }
  }

  Future<void> _runOfflineSimulationAction() async {
    final scannerProvider = context.read<ScannerProvider>();

    final passport = await scannerProvider.runOfflineSimulation();
    if (passport != null && mounted) {
      await _showPrePassportConfirmationSheet(passport);
    }
  }

  Future<void> _showPrePassportConfirmationSheet(WastePassportModel preliminaryPassport) async {
    final scannerProvider = context.read<ScannerProvider>();
    final passportProvider = context.read<PassportProvider>();

    String selectedItem = preliminaryPassport.itemName;
    String selectedMaterial = preliminaryPassport.primaryMaterial;
    String selectedSub = preliminaryPassport.subType;
    RecyclabilityGrade selectedGrade = preliminaryPassport.recyclabilityGrade;
    bool isMixed = preliminaryPassport.isMixedWaste;

    final candidateCategories = [
      {
        'label': 'Paper Tissue / Napkin',
        'itemName': 'Used Paper Tissue / Napkin',
        'material': 'Paper & Cardboard',
        'subType': 'Cellulose Tissue Fiber',
        'grade': RecyclabilityGrade.D,
      },
      {
        'label': 'Multi-Layer Chips / Snack Pouch',
        'itemName': 'Multi-Layer Chips & Snack Wrapper',
        'material': 'Multi-Layer / Composite Materials',
        'subType': 'Metallized BOPP / Polyethylene Film',
        'grade': RecyclabilityGrade.C,
      },
      {
        'label': 'Plastic Water Bottle (PET)',
        'itemName': 'Single-Use Water Bottle',
        'material': 'Plastic',
        'subType': 'PET (Type 1)',
        'grade': RecyclabilityGrade.A,
      },
      {
        'label': 'Corrugated Cardboard Box',
        'itemName': 'Corrugated Shipping Box',
        'material': 'Paper & Cardboard',
        'subType': 'Unbleached Kraft Pulp',
        'grade': RecyclabilityGrade.A,
      },
      {
        'label': 'Aluminium Beverage Can',
        'itemName': 'Aluminium Beverage Can',
        'material': 'Metals',
        'subType': 'Aluminium Alloy 3004',
        'grade': RecyclabilityGrade.A,
      },
      {
        'label': 'Glass Food Jar / Bottle',
        'itemName': 'Preserve Glass Jam Jar',
        'material': 'Glass',
        'subType': 'Soda-Lime Container Glass',
        'grade': RecyclabilityGrade.B,
      },
      {
        'label': 'Textile / Cotton Fabric',
        'itemName': 'Worn Cotton Garment / Fabric',
        'material': 'Textiles & Fabrics',
        'subType': '100% Spun Cotton Fiber',
        'grade': RecyclabilityGrade.B,
      },
      {
        'label': 'Food / Fruit Scrap',
        'itemName': 'Vegetable & Fruit Food Scraps',
        'material': 'Biodegradable / Organic',
        'subType': 'Organic Kitchen Biomass',
        'grade': RecyclabilityGrade.A,
      },
      {
        'label': 'Rechargeable Battery Cell',
        'itemName': 'Rechargeable Battery Cell',
        'material': 'Electronic Waste (E-Waste)',
        'subType': 'Lithium-Cobalt Secondary Cell',
        'grade': RecyclabilityGrade.E,
      },
      {
        'label': 'Mixed Dry Packaging Waste',
        'itemName': 'Mixed Municipal Packaging Waste',
        'material': 'Multi-Layer / Composite Materials',
        'subType': 'Mixed Dry Packaging',
        'grade': RecyclabilityGrade.C,
      },
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fact_check_outlined, color: AppColors.primaryGreen, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verify Waste Item',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              Text(
                                'Confirm or select the item before passport creation',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // AI Detection Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: preliminaryPassport.isSimulated
                            ? const Color(0xFFFFF8E1)
                            : const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: preliminaryPassport.isSimulated
                              ? const Color(0xFFFFB300)
                              : const Color(0xFFA5D6A7),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    preliminaryPassport.isSimulated
                                        ? Icons.science_outlined
                                        : Icons.verified,
                                    size: 16,
                                    color: preliminaryPassport.isSimulated
                                        ? const Color(0xFFE65100)
                                        : AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    preliminaryPassport.isSimulated
                                        ? 'OFFLINE SIMULATION (DEMO)'
                                        : 'LIVE AI CLASSIFICATION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: preliminaryPassport.isSimulated
                                          ? const Color(0xFFE65100)
                                          : AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                preliminaryPassport.isSimulated
                                    ? 'Demo Output'
                                    : '${(preliminaryPassport.confidenceScore * 100).toInt()}% Confidence',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: preliminaryPassport.isSimulated
                                      ? const Color(0xFFE65100)
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedItem,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$selectedMaterial • $selectedSub',
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                          ),
                          if (preliminaryPassport.isSimulated) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Offline demonstration output. Not classified by live AI vision.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (preliminaryPassport.isMixedWaste) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_outlined, size: 16, color: Color(0xFFE65100)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Mixed Waste: ${preliminaryPassport.detectedItems.join(", ")}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (preliminaryPassport.isAmbiguous && preliminaryPassport.ambiguityReason != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              preliminaryPassport.ambiguityReason!,
                              style: const TextStyle(fontSize: 11, color: Colors.brown, fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (preliminaryPassport.visualEvidence != null && preliminaryPassport.visualEvidence!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Visual Evidence: ${preliminaryPassport.visualEvidence!}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Manual Category Correction (Optional):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a verified category below if visual appearance requires correction:',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: candidateCategories.map((c) {
                        final isSelected = selectedItem == c['itemName'];
                        return ChoiceChip(
                          label: Text(c['label'] as String),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedItem = c['itemName'] as String;
                                selectedMaterial = c['material'] as String;
                                selectedSub = c['subType'] as String;
                                selectedGrade = c['grade'] as RecyclabilityGrade;
                                isMixed = (c['itemName'] as String).contains('Mixed');
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              scannerProvider.clearImage();
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retake Photo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // Construct finalized passport
                              final finalized = preliminaryPassport.copyWith(
                                itemName: selectedItem,
                                primaryMaterial: selectedMaterial,
                                subType: selectedSub,
                                recyclabilityGrade: selectedGrade,
                                isMixedWaste: isMixed,
                                isAmbiguous: false,
                                confidenceScore: preliminaryPassport.isSimulated
                                    ? preliminaryPassport.confidenceScore
                                    : (selectedItem == preliminaryPassport.itemName
                                        ? preliminaryPassport.confidenceScore
                                        : 0.95),
                              );
                              passportProvider.addPassport(finalized);
                              context.push(RouteNames.passportDetail);
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Create Waste Passport'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApiKeySettingsDialog() {
    final controller = TextEditingController(text: AIConfig.apiKey);
    bool forceMock = AIConfig.isForceMockMode;
    String selectedModel = AIConfig.modelName;
    bool isValidating = false;
    String? validationError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('AI Engine Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Gemini Multimodal Vision API',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter a Gemini API key for live multimodal vision identification from image pixels. Get a free key at aistudio.google.com.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste, size: 20),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          controller.text = data!.text!.trim();
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                  ),
                  obscureText: true,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                if (controller.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        controller.clear();
                        setDialogState(() => validationError = null);
                      },
                      icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                      label: const Text('Clear Key', style: TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Gemini Model ID',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: AIConfig.supportedModels.contains(selectedModel) ? selectedModel : AIConfig.defaultModel,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'gemini-2.5-flash',
                      child: Text('gemini-2.5-flash (Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-2.0-flash',
                      child: Text('gemini-2.0-flash (Fast)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-1.5-flash',
                      child: Text('gemini-1.5-flash (Multimodal)'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-3.8-flash',
                      child: Text('gemini-3.8-flash'),
                    ),
                    DropdownMenuItem(
                      value: 'gemini-3.5-flash-lite',
                      child: Text('gemini-3.5-flash-lite (Fast-Lite)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedModel = val;
                        validationError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Force Offline Simulation Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Uses local pre-configured demo templates without internet or API quotas', style: TextStyle(fontSize: 11)),
                  value: forceMock,
                  onChanged: (val) {
                    setDialogState(() {
                      forceMock = val;
                      validationError = null;
                    });
                  },
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationError!,
                            style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isValidating
                  ? null
                  : () async {
                      final key = controller.text.trim();
                      if (key.isNotEmpty && !forceMock) {
                        setDialogState(() {
                          isValidating = true;
                          validationError = null;
                        });

                        final validation = await GeminiVisionService().validateModelAccess(
                          apiKey: key,
                          targetModel: selectedModel,
                        );

                        if (!validation.isValid) {
                          setDialogState(() {
                            isValidating = false;
                            validationError = validation.errorMessage ??
                                'Configured model ($selectedModel) is not available to this API key.';
                          });
                          return;
                        }

                        // Use active model confirmed by validation
                        if (validation.activeModel != null) {
                          selectedModel = validation.activeModel!;
                        }
                      }

                      await AIConfig.setRuntimeApiKey(key);
                      await AIConfig.setModelName(selectedModel);
                      await AIConfig.setForceMockMode(forceMock);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
              child: isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save & Validate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerProvider = context.watch<ScannerProvider>();
    final isForcedMock = AIConfig.isForceMockMode;
    final hasKey = AIConfig.hasApiKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Identification'),
        actions: [
          IconButton(
            tooltip: 'AI Engine Settings',
            icon: const Icon(Icons.tune_outlined),
            onPressed: _showApiKeySettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isForcedMock
                    ? const Color(0xFFFBE9E7)
                    : (!hasKey
                        ? const Color(0xFFFFF8E1)
                        : const Color(0xFFE8F5E9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isForcedMock
                      ? const Color(0xFFFF8A65)
                      : (!hasKey
                          ? const Color(0xFFFFB300)
                          : const Color(0xFFA5D6A7)),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isForcedMock
                        ? Icons.offline_bolt_outlined
                        : (!hasKey
                            ? Icons.vpn_key_outlined
                            : Icons.verified),
                    size: 26,
                    color: isForcedMock
                        ? const Color(0xFFD84315)
                        : (!hasKey
                            ? const Color(0xFFE65100)
                            : AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isForcedMock
                              ? 'Offline Simulation Mode Active'
                              : (!hasKey
                                  ? 'Live AI Vision: API Key Required'
                                  : 'Live AI Active (${AIConfig.modelDisplayName})'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isForcedMock
                                ? const Color(0xFFD84315)
                                : (!hasKey
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF1B5E20)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isForcedMock
                              ? 'Using local demo templates without internet or live API vision.'
                              : (!hasKey
                                  ? 'Tap to paste your Google Gemini API key or switch to demo mode.'
                                  : 'Real-time multimodal AI analysis enabled for captured waste photos.'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isForcedMock
                                ? const Color(0xFF5D4037)
                                : (!hasKey
                                    ? const Color(0xFF5D4037)
                                    : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _showApiKeySettingsDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isForcedMock
                          ? const Color(0xFFD84315)
                          : (!hasKey
                              ? const Color(0xFFE65100)
                              : AppColors.primaryGreen),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      !hasKey ? 'Set Key' : 'Settings',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Image Preview / Frame
            EcoCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: scannerProvider.rawImageBytes != null
                  ? Colors.white
                  : const Color(0xFFF1F5F2),
              border: Border.all(
                color: scannerProvider.rawImageBytes != null
                    ? AppColors.primaryGreen
                    : const Color(0xFFCFD8D3),
                width: 1.5,
              ),
              child: SizedBox(
                width: double.infinity,
                child: scannerProvider.rawImageBytes != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              scannerProvider.rawImageBytes!,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  scannerProvider.imageFileName ?? 'Selected Waste Photo',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                tooltip: 'Remove Photo',
                                onPressed: scannerProvider.reset,
                              ),
                            ],
                          ),
                          // Preprocessing Stats Badge if available
                          if (scannerProvider.preprocessingResult != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    'Original: ${scannerProvider.preprocessingResult!.originalSizeFormatted}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                                  Text(
                                    'Compressed: ${scannerProvider.preprocessingResult!.processedSizeFormatted} (-${scannerProvider.preprocessingResult!.compressionRatioPercent.toStringAsFixed(0)}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_enhance_outlined,
                              size: 46,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Capture or Upload Waste Photo',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Optimizes and compresses image before AI classification',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),

            // Selection Buttons (Camera / Gallery)
            if (!scannerProvider.isProcessing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose File'),
                    ),
                  ),
                ],
              ),
              if (scannerProvider.rawImageBytes != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _runPipeline,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Run WasteWay AI Classification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Live Preprocessing and Classification Pipeline State
              EcoCard(
                backgroundColor: const Color(0xFFF1F8E9),
                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryGreen),
                    const SizedBox(height: 16),
                    Text(
                      scannerProvider.currentStep == ScanStep.preprocessing
                          ? 'Module 2: Resizing & Compressing Image...'
                          : 'Module 3: AI Vision Classification & Passport Generation...',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scannerProvider.currentStep == ScanStep.preprocessing
                          ? 'Downscaling to 1024px JPEG to minimize bandwidth payload'
                          : 'Extracting polymers, recyclability score and circularity pathways',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // Error Display & Retry Options
            if (scannerProvider.currentStep == ScanStep.error) ...[
              const SizedBox(height: 16),
              EcoCard(
                backgroundColor: const Color(0xFFFFEBEE),
                border: Border.all(color: AppColors.alertRed),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.alertRed, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Classification Failed',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.alertRed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scannerProvider.errorMessage ?? 'An unexpected error occurred during classification.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7F0000)),
                    ),
                    const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _runPipeline,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry Analysis'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showApiKeySettingsDialog,
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Update API Key'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _runOfflineSimulationAction,
                            icon: const Icon(Icons.offline_bolt_outlined, size: 16),
                            label: const Text('Run Offline Simulation'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Last Execution Fallback notice
            if (scannerProvider.lastResult != null && scannerProvider.lastResult!.isFallback) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.brown[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scannerProvider.lastResult!.fallbackReason ?? 'Simulation fallback used.',
                        style: TextStyle(fontSize: 11, color: Colors.brown[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Guaranteed Quick-Demo Section for College Presentations
            const Divider(),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.bolt, size: 18, color: AppColors.accentAmber),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'One-Tap Presentation Classifiers',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Instantly test circularity pipelines for common material types without requiring camera capture:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.fastfood, size: 16, color: Colors.orange),
                  label: const Text('Chips / Snack Pouch'),
                  onPressed: () => _simulateQuickDemo('chips_wrapper.jpg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.cleaning_services, size: 16, color: Colors.teal),
                  label: const Text('Paper Tissue / Napkin'),
                  onPressed: () => _simulateQuickDemo('tissue_paper.jpg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.local_drink, size: 16, color: Colors.blue),
                  label: const Text('PET Plastic Bottle'),
                  onPressed: () => _simulateQuickDemo('bottle.jpg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.inventory_2, size: 16, color: Colors.brown),
                  label: const Text('Cardboard Box'),
                  onPressed: () => _simulateQuickDemo('shipping_box.jpg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.sports_bar, size: 16, color: Colors.blueGrey),
                  label: const Text('Aluminium Can'),
                  onPressed: () => _simulateQuickDemo('soda_can.jpg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.battery_alert, size: 16, color: Colors.red),
                  label: const Text('Li-Ion Battery'),
                  onPressed: () => _simulateQuickDemo('battery.jpg'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _simulateQuickDemo(String mockFileName) async {
    final scannerProvider = context.read<ScannerProvider>();
    final passportProvider = context.read<PassportProvider>();

    // Standards-compliant JPEG bytes ensuring cross-platform CanvasKit decodability
    final validBytes = MockWasteSampleImage.getSampleImageBytes(mockFileName);
    scannerProvider.onImageSelected(validBytes, mockFileName);

    final passport = await scannerProvider.runOfflineSimulation();
    if (passport != null && mounted) {
      passportProvider.addPassport(passport);
      context.push(RouteNames.passportDetail);
    }
  }
}
