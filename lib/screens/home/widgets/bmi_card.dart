// ============================================================
//  BmiCard – Premium Glassmorphic BMI Tracker Widget
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app_theme.dart';
import '../../../theme/menstrual_medical_theme.dart';
import '../../../providers/user_provider.dart';
import '../../../services/bmi_helper.dart';

class BmiCard extends StatefulWidget {
  const BmiCard({super.key});

  @override
  State<BmiCard> createState() => _BmiCardState();
}

class _BmiCardState extends State<BmiCard> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();

  double _localHeight = 0.0;
  double _localWeight = 0.0;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _localHeight = user.heightCm ?? 0.0;
      _localWeight = user.weightKg ?? 0.0;
      if (_localHeight > 0) _heightController.text = _localHeight.toStringAsFixed(1);
      if (_localWeight > 0) _weightController.text = _localWeight.toStringAsFixed(1);
    }

    _heightFocusNode.addListener(_onFocusChange);
    _weightFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_heightFocusNode.hasFocus && !_weightFocusNode.hasFocus) {
      _autoSave();
    }
  }

  void _onValuesChanged() {
    final h = double.tryParse(_heightController.text) ?? 0.0;
    final w = double.tryParse(_weightController.text) ?? 0.0;
    if (h != _localHeight || w != _localWeight) {
      setState(() {
        _localHeight = h;
        _localWeight = w;
      });
    }
  }

  Future<void> _autoSave() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    if (_localHeight <= 0 || _localWeight <= 0) return;

    // Only save if values actually changed from the DB
    if (_localHeight == user.heightCm && _localWeight == user.weightKg) return;

    setState(() {
      _saveMessage = 'Auto-saving...';
    });

    try {
      await context.read<UserProvider>().updateBmiMetrics(
        heightCm: _localHeight,
        weightKg: _localWeight,
      );
      if (mounted) {
        setState(() {
          _saveMessage = '✓ Synced to Cloud';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _saveMessage = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveMessage = '⚠️ Save failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final isUnmarried = user.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    // If database values changed externally, sync controllers
    final dbHeight = user.heightCm ?? 0.0;
    final dbWeight = user.weightKg ?? 0.0;
    if (!_heightFocusNode.hasFocus && dbHeight != _localHeight && dbHeight > 0) {
      _localHeight = dbHeight;
      _heightController.text = dbHeight.toStringAsFixed(1);
    }
    if (!_weightFocusNode.hasFocus && dbWeight != _localWeight && dbWeight > 0) {
      _localWeight = dbWeight;
      _weightController.text = dbWeight.toStringAsFixed(1);
    }

    final bmi = BmiHelper.calculateBmi(heightCm: _localHeight, weightKg: _localWeight);
    final status = BmiHelper.getBmiStatus(bmi);
    final alert = BmiHelper.getBmiAlert(bmi);

    // Linear gauge calculation: min 15, max 35
    double gaugeProgress = 0.0;
    if (bmi > 0) {
      gaugeProgress = ((bmi - 15.0) / 20.0).clamp(0.0, 1.0);
    }

    Color gaugeColor = Colors.white24;
    Color badgeColor = Colors.white12;
    Color textColor = Colors.white;

    if (bmi > 0) {
      if (status == 'Underweight') {
        gaugeColor = Colors.blueAccent;
        badgeColor = Colors.blueAccent.withValues(alpha: 0.15);
        textColor = Colors.blueAccent;
      } else if (status == 'Normal') {
        gaugeColor = isUnmarried ? MenstrualMedicalTheme.greenZoneMint : MaaColors.success;
        badgeColor = (isUnmarried ? MenstrualMedicalTheme.greenZoneMint : MaaColors.success).withValues(alpha: 0.15);
        textColor = isUnmarried ? MenstrualMedicalTheme.greenZoneMint : Colors.greenAccent;
      } else if (status == 'Overweight') {
        gaugeColor = isUnmarried ? MenstrualMedicalTheme.yellowZoneAmber : Colors.orangeAccent;
        badgeColor = (isUnmarried ? MenstrualMedicalTheme.yellowZoneAmber : Colors.orangeAccent).withValues(alpha: 0.15);
        textColor = isUnmarried ? MenstrualMedicalTheme.yellowZoneAmber : Colors.orangeAccent;
      } else {
        gaugeColor = isUnmarried ? MenstrualMedicalTheme.redZoneCrimson : Colors.redAccent;
        badgeColor = (isUnmarried ? MenstrualMedicalTheme.redZoneCrimson : Colors.redAccent).withValues(alpha: 0.15);
        textColor = isUnmarried ? MenstrualMedicalTheme.redZoneCrimson : Colors.redAccent;
      }
    }

    final childContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.scale_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Body Mass Index (BMI)',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isUnmarried ? Colors.white : MaaColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (_saveMessage != null)
              Text(
                _saveMessage!,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: _saveMessage!.startsWith('⚠️') ? Colors.redAccent : primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Inputs Row
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'Height (cm)',
                controller: _heightController,
                focusNode: _heightFocusNode,
                hint: 'e.g. 165',
                focusColor: primaryColor,
                onChanged: (val) => _onValuesChanged(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                label: 'Weight (kg)',
                controller: _weightController,
                focusNode: _weightFocusNode,
                hint: 'e.g. 60',
                focusColor: primaryColor,
                onChanged: (val) => _onValuesChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // BMI Display & Gauge (only if calculated)
        if (bmi > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Score',
                    style: GoogleFonts.outfit(fontSize: 11, color: isUnmarried ? Colors.white38 : Colors.white38),
                  ),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gaugeProgress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
            ),
          ),
          const SizedBox(height: 12),

          // Alert Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gaugeColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gaugeColor.withValues(alpha: 0.15)),
            ),
            child: Text(
              alert,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Enter height and weight to calculate your BMI and get hormonal routing plans.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isUnmarried ? Colors.white38 : Colors.white38,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (isUnmarried) {
      return GlassmorphicCard(
        borderColor: Colors.white10,
        child: childContent,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: childContent,
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required Color focusColor,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus ? focusColor : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            onSubmitted: (val) => _autoSave(),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
