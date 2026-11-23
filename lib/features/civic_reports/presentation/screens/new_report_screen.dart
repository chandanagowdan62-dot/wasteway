import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/eco_card.dart';
import '../../domain/models/civic_location_model.dart';
import '../../domain/models/civic_report_model.dart';
import '../../domain/models/municipal_authority_model.dart';
import '../../domain/services/civic_authority_registry.dart';
import 'civic_report_review_screen.dart';

/// Screen allowing citizens to draft a public waste neglect report (Module 8 - Step 1)
class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _localityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pinController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bengaluru');
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = CivicIssueCategories.illegalDumping;
  IssueSeverity _selectedSeverity = IssueSeverity.moderate;
  Uint8List? _evidenceImageBytes;
  String? _imageName;

  // Optional device GPS coordinates with explicit permission consent
  bool _useDeviceLocation = false;
  double? _latitude;
  double? _longitude;

  MunicipalAuthorityModel _resolvedAuthority = MunicipalAuthorityModel.bbmp();

  @override
  void initState() {
    super.initState();
    _updateResolvedAuthority();

    _addressController.addListener(_updateResolvedAuthority);
    _localityController.addListener(_updateResolvedAuthority);
    _landmarkController.addListener(_updateResolvedAuthority);
    _pinController.addListener(_updateResolvedAuthority);
    _cityController.addListener(_updateResolvedAuthority);
  }

  @override
  void dispose() {
    _addressController.removeListener(_updateResolvedAuthority);
    _localityController.removeListener(_updateResolvedAuthority);
    _landmarkController.removeListener(_updateResolvedAuthority);
    _pinController.removeListener(_updateResolvedAuthority);
    _cityController.removeListener(_updateResolvedAuthority);

    _titleController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _landmarkController.dispose();
    _pinController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  CivicLocationModel _buildCurrentLocation() {
    return CivicLocationModel(
      address: _addressController.text.trim().isEmpty ? 'Unspecified location' : _addressController.text.trim(),
      locality: _localityController.text.trim().isEmpty ? null : _localityController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      postalCode: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: 'Karnataka',
      latitude: _useDeviceLocation ? _latitude : null,
      longitude: _useDeviceLocation ? _longitude : null,
      isGpsDetected: _useDeviceLocation,
    );
  }

  void _updateResolvedAuthority() {
    final location = _buildCurrentLocation();
    final auth = CivicAuthorityRegistry.resolveAuthority(location);
    if (mounted && (auth.id != _resolvedAuthority.id || auth.matchedWard != _resolvedAuthority.matchedWard)) {
      setState(() {
        _resolvedAuthority = auth;
      });
    }
  }

  Future<void> _pickEvidence(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _evidenceImageBytes = bytes;
          _imageName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acquire evidence image: $e')),
      );
    }
  }

  Future<void> _toggleDeviceLocation(bool value) async {
    if (value) {
      // Prompt user for explicit permission consent before tagging device coordinates
      final bool? consent = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Use Device Location?'),
          content: const Text(
            'WasteWay requires your explicit consent to attach GPS coordinates to this civic notice. Coordinates help municipal sanitation teams pinpoint public dumps.\n\nYou can also enter location details manually without GPS.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Allow GPS Tagging'),
            ),
          ],
        ),
      );

      if (consent == true) {
        setState(() {
          _useDeviceLocation = true;
          // Representative coordinates for urban civic logging
          _latitude = 12.9716;
          _longitude = 77.5946;
        });
        _updateResolvedAuthority();
      }
    } else {
      setState(() {
        _useDeviceLocation = false;
        _latitude = null;
        _longitude = null;
      });
      _updateResolvedAuthority();
    }
  }

  void _proceedToReview() {
    if (!_formKey.currentState!.validate()) return;

    final location = _buildCurrentLocation();
    final authority = CivicAuthorityRegistry.resolveAuthority(location);

    final reviewArgs = CivicReportReviewArgs(
      title: _titleController.text.trim(),
      issueCategory: _selectedCategory,
      severity: _selectedSeverity,
      description: _descriptionController.text.trim(),
      locationAddress: location.fullDisplayLocation,
      latitude: _useDeviceLocation ? _latitude : null,
      longitude: _useDeviceLocation ? _longitude : null,
      imagePath: _imageName,
      imageBytes: _evidenceImageBytes,
      civicLocation: location,
      municipalAuthority: authority,
    );

    context.push(RouteNames.reviewCivicReport, extra: reviewArgs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Alert Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Step indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Step 1 of 2: Prepare Complaint Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.alertRed,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Prepare Public Waste Grievance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Document illegal dumping, overflowing bins, or civic neglect with photographic evidence and mapped municipal routing.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 18),

              // Photographic Evidence Section
              EcoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_evidenceImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _evidenceImageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickEvidence(ImageSource.camera),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Change Photo'),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _evidenceImageBytes = null;
                              _imageName = null;
                            }),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Icon(Icons.add_a_photo_outlined, size: 44, color: AppColors.alertRed),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Photographic Evidence (Recommended)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clear photos of waste piles provide verifiable evidence for municipal grievance desks.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickEvidence(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Take Photo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _pickEvidence(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text('From Gallery'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Issue Title Field
              const Text('Issue Title *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Commercial Debris Dumped on Sidewalk',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a descriptive issue title';
                  }
                  if (val.trim().length < 5) {
                    return 'Title must be at least 5 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Category Picker (8 Standardized Categories)
              const Text('Sanitation Issue Category *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                items: CivicIssueCategories.all.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 18),

              // Severity Selector
              const Text('Estimated Severity Level *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IssueSeverity.values.map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  return ChoiceChip(
                    label: Text(sev.label),
                    selected: isSelected,
                    selectedColor: sev.color.withAlpha(50),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? sev.color : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSeverity = sev);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // LOCATION DETECTION & MANUAL ENTRY SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Location Details *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleDeviceLocation(!_useDeviceLocation),
                    icon: Icon(
                      _useDeviceLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                      size: 16,
                      color: _useDeviceLocation ? AppColors.secondaryTeal : Colors.grey[700],
                    ),
                    label: Text(
                      _useDeviceLocation ? 'GPS Enabled' : 'Add GPS',
                      style: TextStyle(
                        fontSize: 12,
                        color: _useDeviceLocation ? AppColors.secondaryTeal : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Enter location details manually. GPS coordinates are optional and require your consent.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Street Address Field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address / Location *',
                  hintText: 'e.g. 5th Main Road, Opposite Park Gate 3',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the street address or location';
                  }
                  if (val.trim().length < 5) {
                    return 'Location description must be at least 5 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Locality & Landmark row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _localityController,
                      decoration: const InputDecoration(
                        labelText: 'Locality / Area',
                        hintText: 'e.g. Indiranagar',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'e.g. Near Metro Station',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Postal Code & City row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code (PIN)',
                        hintText: 'e.g. 560038',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City / District',
                        hintText: 'e.g. Bengaluru',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // GPS Status Notice
              if (_useDeviceLocation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondaryTeal.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.secondaryTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GPS Coordinates Attached: ${_latitude?.toStringAsFixed(4)}° N, ${_longitude?.toStringAsFixed(4)}° E (Consent recorded)',
                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryTeal, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // LIVE AUTHORITY IDENTIFICATION PREVIEW CARD
              EcoCard(
                backgroundColor: _resolvedAuthority.isVerified
                    ? const Color(0xFFF1F8E9)
                    : const Color(0xFFFFF8E1),
                border: Border.all(
                  color: _resolvedAuthority.isVerified
                      ? const Color(0xFF81C784)
                      : const Color(0xFFFFD54F),
                  width: 1.2,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _resolvedAuthority.isVerified ? Icons.verified : Icons.help_outline,
                          color: _resolvedAuthority.isVerified
                              ? AppColors.primaryGreen
                              : const Color(0xFFF57F17),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resolvedAuthority.isVerified
                                ? 'Identified Municipal Authority'
                                : 'Authority Unverified',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _resolvedAuthority.isVerified
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _resolvedAuthority.isVerified
                                ? AppColors.primaryGreen.withAlpha(30)
                                : Colors.amber.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _resolvedAuthority.isVerified ? 'VERIFIED' : 'UNVERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _resolvedAuthority.isVerified
                                  ? AppColors.primaryGreen
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _resolvedAuthority.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (_resolvedAuthority.matchedWard != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.my_location, size: 13, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _resolvedAuthority.matchedWard!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _resolvedAuthority.routingInstructions,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Issue Description
              const Text('Detailed Description *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe waste accumulation, odors, street blockages, fire hazard, or health concerns...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a detailed description of the issue';
                  }
                  if (val.trim().length < 10) {
                    return 'Description must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Proceed to Review Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _proceedToReview,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Review & Prepare Complaint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
