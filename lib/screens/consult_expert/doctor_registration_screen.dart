// ============================================================
//  Doctor Registration Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/maacare_backend_service.dart';
import '../../widgets/maa_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/error_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _expController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();
  final _hoursController = TextEditingController();
  final _locationController = TextEditingController();
  final _licenseController = TextEditingController();

  // Media State
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  String? _licenseImageUrl;
  bool _isUploadingAvatar = false;
  bool _isUploadingLicense = false;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() {
      if (isAvatar) {
        _isUploadingAvatar = true;
      } else {
        _isUploadingLicense = true;
      }
    });

    final bytes = await image.readAsBytes();
    final sanitizedName = image.name.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    final url = await MaaCareBackendService.instance.uploadFile(
      bucket: 'community_media',
      fileName: fileName,
      bytes: bytes,
      contentType: image.mimeType ?? 'image/jpeg',
    );

    if (mounted) {
      setState(() {
        if (isAvatar) {
          _avatarUrl = url;
          _isUploadingAvatar = false;
        } else {
          _licenseImageUrl = url;
          _isUploadingLicense = false;
        }
      });
      if (url == null) {
        ErrorHelper.showError(
            context, 'Failed to upload image. Please try again.');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_licenseImageUrl == null) {
      ErrorHelper.showError(
          context, 'Please upload your medical license for verification.');
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) {
      ErrorHelper.showError(
          context, 'You must be logged in to register as a doctor.');
      return;
    }

    setState(() => _isLoading = true);

    String name = _nameController.text.trim();
    if (!name.toLowerCase().startsWith('dr.')) {
      name = 'Dr. $name';
    }

    final doctor = DoctorModel(
      id: '',
      userId: user.id,
      name: name,
      specialization: _specController.text.trim(),
      experience: _expController.text.trim(),
      rating: '5.0',
      fee: _feeController.text.trim().startsWith('₹')
          ? _feeController.text.trim()
          : '₹${_feeController.text.trim()}',
      bio: _bioController.text.trim(),
      availableHours: _hoursController.text.trim(),
      avatarUrl: _avatarUrl,
      licenseUrl: _licenseImageUrl,
      emoji: '👩‍⚕️',
      isVerified: true,
      status: 'verified',
      clinicLocation: _locationController.text.trim(),
    );

    final success = await MaaCareBackendService.instance.registerDoctor(doctor);

    if (success) {
      await MaaCareBackendService.instance.updateUserRole(user.id, 'doctor');
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      try {
        await context.read<UserProvider>().loadUser();
      } catch (e) {
        debugPrint('Failed to load user profile after doctor registration: $e');
      }
      _showSuccessDialog();
    } else if (mounted) {
      ErrorHelper.showError(context, 'Registration failed. Please try again.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Application Received! 🎉',
            style: GoogleFonts.poppins(color: MaaColors.white)),
        content: Text(
          'Thank you for joining MaaCare. Our team will verify your credentials and activate your profile within 24-48 hours.',
          style: GoogleFonts.poppins(color: MaaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to Consult Screen
            },
            child: const Text('Understood',
                style: TextStyle(color: MaaColors.pink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expert Registration 👩‍⚕️')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _submit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    MaaButton(
                      label: _currentStep == 3
                          ? 'Submit Application'
                          : 'Next Step',
                      onPressed: details.onStepContinue,
                      width: 180,
                    ),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back',
                            style: TextStyle(color: MaaColors.textMuted)),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text('Professional Bio',
                    style: GoogleFonts.poppins(
                        color: MaaColors.white, fontWeight: FontWeight.bold)),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    _buildTextField(_nameController,
                        'Full Name (e.g. Dr. Priya Sharma)', Icons.person),
                    _buildTextField(
                        _specController,
                        'Specialization (e.g. Gynecologist)',
                        Icons.medical_services),
                    _buildTextField(_expController, 'Experience (e.g. 12 yrs)',
                        Icons.history),
                    _buildTextField(
                        _bioController, 'Professional Bio', Icons.description,
                        maxLines: 3),
                  ],
                ),
              ),
              Step(
                title: Text('Clinic & Logistics',
                    style: GoogleFonts.poppins(
                        color: MaaColors.white, fontWeight: FontWeight.bold)),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    _buildTextField(_feeController,
                        'Consultation Fee (e.g. 500, or 0 for FREE)', Icons.payments),
                    _buildTextField(
                        _hoursController,
                        'Available Hours (e.g. Mon-Fri 9AM-5PM)',
                        Icons.access_time),
                    _buildTextField(_locationController,
                        'Clinic Location / Online', Icons.location_on),
                  ],
                ),
              ),
              Step(
                title: Text('Verification',
                    style: GoogleFonts.poppins(
                        color: MaaColors.white, fontWeight: FontWeight.bold)),
                isActive: _currentStep >= 2,
                state:
                    _currentStep == 2 ? StepState.editing : StepState.indexed,
                content: Column(
                  children: [
                    _buildTextField(_licenseController,
                        'Medical Registration Number', Icons.verified_user),
                    const SizedBox(height: 16),
                    _buildUploadCard(
                      label: 'Upload Medical License',
                      onTap: () => _pickImage(false),
                      url: _licenseImageUrl,
                      isUploading: _isUploadingLicense,
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Profile Preview',
                    style: GoogleFonts.poppins(
                        color: MaaColors.white, fontWeight: FontWeight.bold)),
                isActive: _currentStep >= 3,
                state:
                    _currentStep == 3 ? StepState.editing : StepState.indexed,
                content: Column(
                  children: [
                    _buildUploadCard(
                      label: 'Professional Profile Photo',
                      onTap: () => _pickImage(true),
                      url: _avatarUrl,
                      isUploading: _isUploadingAvatar,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MaaColors.pink.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MaaColors.pink.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: MaaColors.pink, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'By submitting, you agree to our expert Terms and Conditions. Our team will verify your credentials shortly.',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: MaaColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: MaaColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: MaaColors.textMuted),
          prefixIcon: Icon(icon, color: MaaColors.pink),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: MaaColors.white.withAlpha(20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MaaColors.pink),
          ),
          filled: true,
          fillColor: MaaColors.cardDark,
        ),
        validator: (v) => v!.isEmpty ? 'This field is required' : null,
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildUploadCard({
    required String label,
    required VoidCallback onTap,
    String? url,
    bool isUploading = false,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MaaColors.cardLight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: url != null
                ? MaaColors.success.withAlpha(100)
                : MaaColors.white.withAlpha(10),
          ),
        ),
        child: Column(
          children: [
            if (isUploading)
              const CircularProgressIndicator(color: MaaColors.pink)
            else if (url != null)
              Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: MaaColors.success, size: 32),
                  const SizedBox(height: 8),
                  Text('Document Uploaded Successfully!',
                      style: GoogleFonts.poppins(
                          color: MaaColors.white, fontSize: 13)),
                  TextButton(
                      onPressed: onTap,
                      child: const Text('Replace',
                          style: TextStyle(color: MaaColors.textMuted))),
                ],
              )
            else
              Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: MaaColors.pink.withAlpha(150), size: 32),
                  const SizedBox(height: 8),
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: MaaColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text('Tap to select image',
                      style: GoogleFonts.poppins(
                          color: MaaColors.textMuted, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
