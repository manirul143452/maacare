// ============================================================
//  DoctorOnboardingScreen – Step 3 Option A
//  Captures professional credentials for doctors.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import '../../app_theme.dart';
import '../../constants.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/loading_overlay.dart';

class DoctorOnboardingScreen extends StatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from UserProvider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null && user.name.isNotEmpty && user.name != 'Mama') {
        _nameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = AuthService.instance.accessToken;
      if (token == null) {
        throw Exception('Session expired. Please log in again.');
      }

      final url = Uri.parse('${AppConstants.backendUrl}/functions/update_user_role');
      final body = <String, dynamic>{
        'user_role': 'doctor',
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Doctor',
        'medical_registration_no': _regNoController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'hospital_affiliation': _hospitalController.text.trim(),
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': AppConstants.backendAnonKey,
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Reload user profile
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUser();

        // Mark onboarding complete locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);
        if (userProvider.user != null) {
          await prefs.setString('user_id', userProvider.user!.id);
          await prefs.setString('user_name', userProvider.user!.name);
        }

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/doctor_dashboard', (route) => false);
      } else {
        final err = ApiService.safeDecode(response);
        ErrorHelper.showError(context, err['error'] ?? 'Failed to save doctor details.');
      }
    } catch (e) {
      if (mounted) ErrorHelper.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: MaaColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Doctor Credentials',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verification Details',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    'Please fill in your medical licensing information. These details will be verified before you can access clinical workflows.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),

                  _buildGlassField(
                    controller: _nameController,
                    label: 'Display Name (e.g. Dr. Jane Smith)',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Display name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildGlassField(
                    controller: _regNoController,
                    label: 'Medical Registration Number *',
                    icon: Icons.badge_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Registration number is required' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildGlassField(
                    controller: _specializationController,
                    label: 'Specialization (e.g. Gynecologist) *',
                    icon: Icons.medical_services_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Specialization is required' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildGlassField(
                    controller: _hospitalController,
                    label: 'Hospital Affiliation (e.g. City Hospital)',
                    icon: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: 40),

                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFFFF2E93).withValues(alpha: 0.7), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFF2E93),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2E93).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Complete Registration',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
