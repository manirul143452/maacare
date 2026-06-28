// ============================================================
//  EditProfileScreen – MaaCare Premium Glassmorphic Editor
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_theme.dart';
import '../../models/user_model.dart';
import '../../models/doctor_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/menstrual_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/maacare_backend_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Global fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedLanguage = 'en';

  // Photo state
  Uint8List? _localAvatarBytes;
  String? _localAvatarExt;

  // Mother fields
  int _gestationalWeeks = 12;
  DateTime? _dueDate;

  // Unmarried Girl fields
  int _averageCycleLength = 28;
  String _ageBracket = '20-29';
  DateTime? _lastPeriodDate;

  // Doctor fields
  DoctorModel? _doctorModel;
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _feeController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isSaving = false;
  bool _isLoadingDoctor = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedLanguage = user?.language ?? 'en';

    if (user != null) {
      if (user.userRole == 'mother') {
        _gestationalWeeks = user.pregnancyWeek > 0 ? user.pregnancyWeek : 12;
        _dueDate = user.dueDate;
      } else if (user.userRole == 'unmarried_girl') {
        _ageBracket = user.ageBracket ?? '20-29';
        // Load menstrual logs in post frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final menstrualProvider = context.read<MenstrualProvider>();
          await menstrualProvider.loadMenstrualLogs(user.id);
          setState(() {
            _averageCycleLength = menstrualProvider.averageCycleLength;
            _lastPeriodDate = menstrualProvider.lastPeriodStartDate;
          });
        });
      } else if (user.userRole == 'doctor') {
        _loadDoctorDetails(user.id);
      }
    }
  }

  Future<void> _loadDoctorDetails(String userId) async {
    setState(() => _isLoadingDoctor = true);
    try {
      final doc = await MaaCareBackendService.instance.fetchDoctorByUserId(userId);
      if (doc != null) {
        setState(() {
          _doctorModel = doc;
          _specializationController.text = doc.specialization;
          _hospitalController.text = doc.clinicLocation;
          _feeController.text = doc.fee.replaceAll(RegExp(r'[^\d]'), '');

          // Parse start/end times
          try {
            final startParts = doc.dailyStartTime.split(':');
            _startTime = TimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            );
            final endParts = doc.dailyEndTime.split(':');
            _endTime = TimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            );
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('Error loading doctor details: $e');
    } finally {
      setState(() => _isLoadingDoctor = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      String ext = 'jpg';
      if (file.path.contains('.')) {
        ext = file.path.split('.').last;
      }
      setState(() {
        _localAvatarBytes = bytes;
        _localAvatarExt = ext;
      });
    } catch (_) {
      _showSnackBar('Failed to read image. Please try again! 😅', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : MaaColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min:00';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final menstrualProvider = context.read<MenstrualProvider>();
    final communityProvider = context.read<CommunityProvider>();
    var user = userProvider.user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload photo if changed
      String? avatarUrl = user.avatarUrl;
      if (_localAvatarBytes != null && _localAvatarExt != null) {
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$_localAvatarExt';
        final url = await communityProvider.uploadMedia(
              fileName,
              _localAvatarBytes!,
            );
        if (url != null) {
          avatarUrl = url;
        } else {
          // Fallback to base64 encoding if upload fails (CORS or server-config fallbacks)
          final base64String = base64Encode(_localAvatarBytes!);
          final mimeType = _localAvatarExt == 'png' ? 'image/png' : 'image/jpeg';
          avatarUrl = 'data:$mimeType;base64,$base64String';
        }
      }

      // 2. Computed values based on role
      DateTime? computedDueDate = _dueDate;
      if (user.userRole == 'mother' && _dueDate == null) {
        // If gestational weeks modified, back-compute due date (40 weeks = 280 days total)
        final daysPregnant = _gestationalWeeks * 7;
        final daysRemaining = 280 - daysPregnant;
        computedDueDate = DateTime.now().add(Duration(days: daysRemaining));
      }

      // 3. Update main User model
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        language: _selectedLanguage,
        avatarUrl: avatarUrl,
        dueDate: computedDueDate,
        ageBracket: user.userRole == 'unmarried_girl' ? _ageBracket : null,
      );

      await userProvider.createOrUpdateUser(updatedUser);

      // 4. Update role-specific databases
      if (user.userRole == 'unmarried_girl') {
        await menstrualProvider.saveCycleParameters(
          user.id,
          averageCycleLength: _averageCycleLength,
          lastPeriodStartDate: _lastPeriodDate,
        );
      } else if (user.userRole == 'doctor' && _doctorModel != null) {
        final updates = {
          'name': _nameController.text.trim(),
          'specialization': _specializationController.text.trim(),
          'clinic_location': _hospitalController.text.trim(),
          'fee': '₹${_feeController.text.trim()}',
          'daily_start_time': _formatTimeOfDay(_startTime),
          'daily_end_time': _formatTimeOfDay(_endTime),
          'profile_photo_url': avatarUrl,
          'avatar_url': avatarUrl,
        };
        await MaaCareBackendService.instance.updateDoctorProfile(_doctorModel!.id, updates);

        // Also sync registration metadata
        await MaaCareBackendService.instance.upsertDoctorProfile(
          userId: user.id,
          medicalRegistrationNo: _doctorModel!.licenseUrl ?? 'REG-12345',
          specialization: _specializationController.text.trim(),
          hospitalAffiliation: _hospitalController.text.trim(),
        );
      }

      _showSnackBar('Profile saved successfully! 🌸');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Failed to save profile details. Try again! 😅', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _triggerPasswordReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password 🔒', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'We will send a password reset link to your email associated with this account. Proceed?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: MaaColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Password reset link sent! Check your inbox. 💌');
            },
            child: const Text('Send Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _switchLifecycleState() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final currentRole = user.userRole;
    if (currentRole == 'doctor') {
      _showSnackBar('Doctor profiles cannot switch lifecycle tracking modes.');
      return;
    }

    final targetRole = currentRole == 'mother' ? 'unmarried_girl' : 'mother';
    final targetModeName = targetRole == 'mother' ? 'Pregnant Mother mode' : 'Period Support mode';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaaColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Switch Tracking Experience?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            'Are you switching your tracking experience to Pregnant Mother mode or Period Support mode?\n\nThis will adjust your home dashboard, tips, and cycle calculators to match your selection.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm Switch', style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final success = await MaaCareBackendService.instance.updateUserRole(user.id, targetRole);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', targetRole);

        // Reload user in UserProvider to get updated model
        await userProvider.loadUser();

        if (mounted) {
          _showSnackBar('Switched tracking mode to $targetModeName successfully! 🌸');
          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to update tracking state in database. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check_rounded, color: MaaColors.pink, size: 28),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoadingDoctor
          ? const Center(child: CircularProgressIndicator(color: MaaColors.pink))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // Profile Photo Selector
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: MaaColors.pink, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: MaaColors.pink.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _localAvatarBytes != null
                                ? Image.memory(_localAvatarBytes!, fit: BoxFit.cover)
                                : user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                    ? user.avatarUrl!.startsWith('data:')
                                        ? Image.memory(
                                            base64Decode(user.avatarUrl!.split(',').last),
                                            fit: BoxFit.cover,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: user.avatarUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => _buildInitialAvatar(user),
                                            errorWidget: (_, __, ___) => _buildInitialAvatar(user),
                                          )
                                    : _buildInitialAvatar(user),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: MaaColors.pink,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Base Fields Card
                  _buildSectionHeader('Base Information 📁'),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildLanguageDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Conditional Sheets
                  if (user?.userRole == 'mother') ...[
                    _buildSectionHeader('Maternal Metrics 🤰'),
                    _buildGlassCard(child: _buildMotherSheet()),
                  ] else if (user?.userRole == 'unmarried_girl') ...[
                    _buildSectionHeader('Cycle Configuration 🌸'),
                    _buildGlassCard(child: _buildSakhiSheet()),
                  ] else if (user?.userRole == 'doctor') ...[
                    _buildSectionHeader('Practice Setup 🩺'),
                    _buildGlassCard(child: _buildDoctorSheet()),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  _buildSectionHeader('Account Actions 🔒'),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          onTap: _triggerPasswordReset,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaaColors.pink.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: MaaColors.pink),
                          ),
                          title: Text('Reset Account Password', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('Receive password reset instructions', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        ListTile(
                          onTap: _switchLifecycleState,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaaColors.pink.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.swap_horiz_rounded, color: MaaColors.pink),
                          ),
                          title: Text('Switch Lifecycle State', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('Switch between Mother and Period Support tracking modes', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaaColors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: MaaColors.pink.withValues(alpha: 0.4),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Save Settings 💾',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildInitialAvatar(UserModel? user) {
    return Container(
      color: MaaColors.pink.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
        style: const TextStyle(color: MaaColors.pink, fontSize: 42, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: MaaColors.pink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.glassBorder.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white54),
        prefixIcon: Icon(icon, color: MaaColors.pink),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.glassBorder.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaaColors.pink),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      dropdownColor: MaaColors.cardDark,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Preferred Language',
        labelStyle: GoogleFonts.poppins(color: Colors.white54),
        prefixIcon: const Icon(Icons.language_rounded, color: MaaColors.pink),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.glassBorder.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaaColors.pink),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'hi', child: Text('Hindi (हिंदी)')),
        DropdownMenuItem(value: 'hinglish', child: Text('Hinglish')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedLanguage = val);
        }
      },
    );
  }

  // --- MOTHER CONDITIONAL SHEET ---
  Widget _buildMotherSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestational Progress Tracker',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gestational Weeks:', style: GoogleFonts.poppins(color: Colors.white70)),
            Text(
              '$_gestationalWeeks Weeks',
              style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _gestationalWeeks.toDouble(),
          min: 1,
          max: 42,
          divisions: 41,
          activeColor: MaaColors.pink,
          inactiveColor: Colors.white24,
          onChanged: (val) {
            setState(() {
              _gestationalWeeks = val.toInt();
              // Auto recalculate estimated due date
              final daysRemaining = (40 - _gestationalWeeks) * 7;
              _dueDate = DateTime.now().add(Duration(days: daysRemaining));
            });
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Estimated Due Date', style: GoogleFonts.poppins(color: Colors.white70)),
          subtitle: Text(
            _dueDate == null ? 'Not set' : DateFormat('dd MMM yyyy').format(_dueDate!),
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.calendar_month_rounded, color: MaaColors.pink),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 180)),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 300)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: MaaColors.pink,
                    onPrimary: Colors.white,
                    surface: MaaColors.cardDark,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() {
                _dueDate = picked;
                // Auto compute gestational week based on due date
                final totalDays = _dueDate!.difference(DateTime.now()).inDays;
                final daysPregnant = 280 - totalDays;
                _gestationalWeeks = (daysPregnant / 7).clamp(1, 42).toInt();
              });
            }
          },
        ),
      ],
    );
  }

  // --- SAKHI CONDITIONAL SHEET ---
  Widget _buildSakhiSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cycle Parameters fine-tuning',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Average Cycle Length:', style: GoogleFonts.poppins(color: Colors.white70)),
            Text(
              '$_averageCycleLength Days',
              style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _averageCycleLength.toDouble(),
          min: 21,
          max: 45,
          divisions: 24,
          activeColor: MaaColors.pink,
          inactiveColor: Colors.white24,
          onChanged: (val) {
            setState(() => _averageCycleLength = val.toInt());
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _ageBracket,
          dropdownColor: MaaColors.cardDark,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Age Bracket',
            labelStyle: GoogleFonts.poppins(color: Colors.white54),
            prefixIcon: const Icon(Icons.face_rounded, color: MaaColors.pink),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: MaaColors.glassBorder.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: MaaColors.pink),
            ),
          ),
          items: const [
            DropdownMenuItem(value: '13-19', child: Text('Teenage (13-19)')),
            DropdownMenuItem(value: '20-29', child: Text('Young Adult (20-29)')),
            DropdownMenuItem(value: '30-39', child: Text('Adult (30-39)')),
            DropdownMenuItem(value: '40+', child: Text('Mature (40+)')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _ageBracket = val);
            }
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Last Period Start Date', style: GoogleFonts.poppins(color: Colors.white70)),
          subtitle: Text(
            _lastPeriodDate == null ? 'Not set' : DateFormat('dd MMM yyyy').format(_lastPeriodDate!),
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.calendar_month_rounded, color: MaaColors.pink),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _lastPeriodDate ?? DateTime.now().subtract(const Duration(days: 10)),
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: MaaColors.pink,
                    onPrimary: Colors.white,
                    surface: MaaColors.cardDark,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() => _lastPeriodDate = picked);
            }
          },
        ),
      ],
    );
  }

  // --- DOCTOR CONDITIONAL SHEET ---
  Widget _buildDoctorSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _specializationController,
          label: 'Specialization / Field',
          icon: Icons.assignment_ind_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _hospitalController,
          label: 'Hospital / Clinic Affiliation',
          icon: Icons.local_hospital_rounded,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _feeController,
          label: 'Consultation Slot Cost (₹)',
          icon: Icons.currency_rupee_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        Text(
          'Shift Timings (Start - End Boundary)',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start Shift', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                subtitle: Text(
                  _startTime.format(context),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.access_time_filled_rounded, color: MaaColors.pink),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
              ),
            ),
            Container(width: 1, height: 40, color: MaaColors.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('End Shift', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                subtitle: Text(
                  _endTime.format(context),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.access_time_filled_rounded, color: MaaColors.pink),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (picked != null) {
                    setState(() => _endTime = picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
