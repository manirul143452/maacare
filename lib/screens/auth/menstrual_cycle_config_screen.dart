// ============================================================
//  MenstrualCycleConfigScreen – Step 3 Option B
//  Captures menstrual cycle baseline parameters for girls.
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
import '../../services/maacare_backend_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/loading_overlay.dart';

class MenstrualCycleConfigScreen extends StatefulWidget {
  const MenstrualCycleConfigScreen({super.key});

  @override
  State<MenstrualCycleConfigScreen> createState() => _MenstrualCycleConfigScreenState();
}

class _MenstrualCycleConfigScreenState extends State<MenstrualCycleConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedAgeBracket = '18-24';
  int _cycleLength = 28;
  int _periodLength = 5;
  DateTime? _lastPeriodDate;
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
    super.dispose();
  }

  Future<void> _pickLastPeriodDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 45)),
      lastDate: DateTime.now(),
      helpText: 'First Day of Last Period 🩸',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFFF2E93),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _lastPeriodDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lastPeriodDate == null) {
      ErrorHelper.showError(context, 'Please pick the start date of your last period.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = AuthService.instance.accessToken;
      if (token == null) {
        throw Exception('Session expired. Please log in again.');
      }

      final url = Uri.parse('${AppConstants.backendUrl}/functions/update_user_role');
      final body = <String, dynamic>{
        'user_role': 'unmarried_girl',
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Period Support User',
        'age_bracket': _selectedAgeBracket,
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

      final userProvider = context.read<UserProvider>();

      if (response.statusCode == 200) {
        // Save cycle configuration metrics in menstrual_logs
        final userId = AuthService.instance.getCurrentUserId();
        if (userId != null) {
          await MaaCareBackendService.instance.saveMenstrualLog(
            userId: userId,
            extraFields: {
              'cycle_length': _cycleLength,
              'period_length': _periodLength,
              'last_period_date': _lastPeriodDate!.toIso8601String(),
            },
          );
        }

        // Reload user profile
        await userProvider.loadUser();

        // Mark onboarding complete locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);
        if (userProvider.user != null) {
          await prefs.setString('user_id', userProvider.user!.id);
          await prefs.setString('user_name', userProvider.user!.name);
        }

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/period_dashboard', (route) => false);
      } else {
        final err = ApiService.safeDecode(response);
        ErrorHelper.showError(context, err['error'] ?? 'Failed to save cycle details.');
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
            'Cycle Setup',
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
                    'Setup Menstrual Tracking',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your baseline cycle parameters to receive phase-aligned health and nutrition tracking features.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),

                  _buildGlassField(
                    controller: _nameController,
                    label: 'Your Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Age Bracket Dropdown
                  _buildDropdownLabel('Select Age Bracket'),
                  const SizedBox(height: 8),
                  _buildAgeDropdown(),
                  const SizedBox(height: 24),

                  // Cycle Length Slider
                  _buildSliderLabel('Average Cycle Length', '$_cycleLength Days'),
                  Slider(
                    value: _cycleLength.toDouble(),
                    min: 21,
                    max: 45,
                    divisions: 24,
                    activeColor: const Color(0xFFFF2E93),
                    inactiveColor: Colors.white24,
                    onChanged: (val) => setState(() => _cycleLength = val.round()),
                  ),
                  const SizedBox(height: 16),

                  // Period Duration Slider
                  _buildSliderLabel('Average Period Duration', '$_periodLength Days'),
                  Slider(
                    value: _periodLength.toDouble(),
                    min: 3,
                    max: 10,
                    divisions: 7,
                    activeColor: const Color(0xFFFF2E93),
                    inactiveColor: Colors.white24,
                    onChanged: (val) => setState(() => _periodLength = val.round()),
                  ),
                  const SizedBox(height: 24),

                  // Last Period Date Picker
                  _buildDatePickerSection(),
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

  Widget _buildDropdownLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAgeDropdown() {
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
          child: Theme(
            data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1F123C)),
            child: DropdownButtonFormField<String>(
              value: _selectedAgeBracket,
              dropdownColor: const Color(0xFF1F123C),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.cake_outlined, color: const Color(0xFFFF2E93).withValues(alpha: 0.7), size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              items: const [
                DropdownMenuItem(value: 'Under 18', child: Text('Under 18')),
                DropdownMenuItem(value: '18-24', child: Text('18-24')),
                DropdownMenuItem(value: '25-34', child: Text('25-34')),
                DropdownMenuItem(value: '35+', child: Text('35+')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedAgeBracket = val);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFFFF2E93), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDatePickerSection() {
    return GestureDetector(
      onTap: _pickLastPeriodDate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: const Color(0xFFFF2E93).withValues(alpha: 0.7), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Period Date',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastPeriodDate == null
                            ? 'Select Start Date'
                            : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: Colors.white.withValues(alpha: 0.5), size: 28),
              ],
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
            'Complete Setup',
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
