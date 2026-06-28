// ============================================================
//  MaternalTimelineConfigScreen – Step 3 Option C
//  Captures pregnancy timeline and due date for mothers.
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
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/maacare_backend_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/loading_overlay.dart';

class MaternalTimelineConfigScreen extends StatefulWidget {
  const MaternalTimelineConfigScreen({super.key});

  @override
  State<MaternalTimelineConfigScreen> createState() => _MaternalTimelineConfigScreenState();
}

class _MaternalTimelineConfigScreenState extends State<MaternalTimelineConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedTrimester = 1;
  DateTime? _dueDate;
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 280)),
      helpText: 'When is your baby due? 👶',
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
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ErrorHelper.showError(context, 'Please pick your expected due date.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = AuthService.instance.accessToken;
      final userId = AuthService.instance.getCurrentUserId();
      if (token == null || userId == null) {
        throw Exception('Session expired. Please log in again.');
      }

      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Mama';

      // 1. Call update_user_role edge function to synchronize role and trimester
      final url = Uri.parse('${AppConstants.backendUrl}/functions/update_user_role');
      final body = <String, dynamic>{
        'user_role': 'mother',
        'name': name,
        'trimester': _selectedTrimester,
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
        // 2. Save user profile (including due_date) to database
        final userModel = UserModel(
          id: userId,
          name: name,
          dueDate: _dueDate,
          userRole: 'mother',
          createdAt: DateTime.now(),
        );
        await userProvider.createOrUpdateUser(userModel);

        // Initialize empty symptoms log
        await MaaCareBackendService.instance.saveSymptomCheck(
          userId: userId,
          symptoms: [],
          riskLevel: 'low',
        );

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
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final err = ApiService.safeDecode(response);
        ErrorHelper.showError(context, err['error'] ?? 'Failed to save pregnancy details.');
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
            'Timeline Setup',
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
                    'Setup Gestational Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your expected due date and trimester to sync your daily health logs and baby development tips.',
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
                  const SizedBox(height: 24),

                  // Trimester Dropdown select matrix
                  _buildDropdownLabel('Select Pregnancy Trimester'),
                  const SizedBox(height: 8),
                  _buildTrimesterDropdown(),
                  const SizedBox(height: 24),

                  // Due Date Picker
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

  Widget _buildTrimesterDropdown() {
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
            child: DropdownButtonFormField<int>(
              value: _selectedTrimester,
              dropdownColor: const Color(0xFF1F123C),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.pregnant_woman_rounded, color: const Color(0xFFFF2E93).withValues(alpha: 0.7), size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('First Trimester (Weeks 1-12)')),
                DropdownMenuItem(value: 2, child: Text('Second Trimester (Weeks 13-26)')),
                DropdownMenuItem(value: 3, child: Text('Third Trimester (Weeks 27-40)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTrimester = val);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerSection() {
    return GestureDetector(
      onTap: _pickDueDate,
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
                Icon(Icons.child_care_rounded, color: const Color(0xFFFF2E93).withValues(alpha: 0.7), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Due Date',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dueDate == null
                            ? 'Select Due Date'
                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
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
