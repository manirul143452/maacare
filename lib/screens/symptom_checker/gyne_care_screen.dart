import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models/medical_models.dart';
import '../../services/medical_data_service.dart';
import '../../widgets/maa_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/auth_service.dart';
import '../../services/maacare_backend_service.dart';
import '../../models/symptom_vaccination_model.dart' show evaluateRisk, gyneCareSymptoms;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class GyneCareScreen extends StatefulWidget {
  const GyneCareScreen({super.key});

  @override
  State<GyneCareScreen> createState() => _GyneCareScreenState();
}

class _GyneCareScreenState extends State<GyneCareScreen> {
  final MedicalDataService _medicalService = MedicalDataService();
  final List<String> _selectedSymptoms = [];
  bool _isLoading = true;
  List<DiagnosticResult> _results = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _medicalService.init();
    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {});
  }

  void _toggleSymptom(String symptomName) {
    setState(() {
      if (_selectedSymptoms.contains(symptomName)) {
        _selectedSymptoms.remove(symptomName);
      } else {
        _selectedSymptoms.add(symptomName);
      }
      _results = []; // Clear offline results on selection change
    });
  }

  void _runDiagnosis() async {
    if (_selectedSymptoms.isEmpty) return;

    final riskLevel = evaluateRisk(_selectedSymptoms);

    // Save check in the backend database
    try {
      final userId = AuthService.instance.getCurrentUserId();
      if (userId != null) {
        await MaaCareBackendService.instance.saveSymptomCheck(
          userId: userId,
          symptoms: _selectedSymptoms,
          riskLevel: riskLevel,
        );
      }

      // Add to local insights log
      final prefs = await SharedPreferences.getInstance();
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][DateTime.now().weekday - 1];
      final symptomRaw = prefs.getString('insights_symptom_logs');
      List<Map<String, dynamic>> logs = [];
      if (symptomRaw != null) {
        logs = List<Map<String, dynamic>>.from(jsonDecode(symptomRaw));
      } else {
        logs = [
          {'date': 'Mon', 'count': 0},
          {'date': 'Tue', 'count': 0},
          {'date': 'Wed', 'count': 0},
          {'date': 'Thu', 'count': 0},
          {'date': 'Fri', 'count': 0},
          {'date': 'Sat', 'count': 0},
          {'date': 'Sun', 'count': 0},
        ];
      }
      final todayIdx = logs.indexWhere((l) => l['date'] == weekday);
      if (todayIdx != -1) {
        logs[todayIdx]['count'] = (logs[todayIdx]['count'] as int) + 1;
      }
      await prefs.setString('insights_symptom_logs', jsonEncode(logs));
    } catch (e) {
      debugPrint('GyneCare: Failed to save symptom check: $e');
    }

    setState(() {
      _results = _medicalService.diagnose(_selectedSymptoms);
    });

    _showResultsModal();
  }

  void _showResultsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultsSheet(),
    );
  }

  bool get _hasHighRiskSelected {
    for (final symptomName in _selectedSymptoms) {
      try {
        final match = gyneCareSymptoms.firstWhere(
          (s) => s['name'] == symptomName,
        );
        if (match['risk'] == 'high') {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Widget _buildEmergencyAlertBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withAlpha(90), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Critical Menstrual Warning!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aapka select kiya gaya symptom ek menstrual emergency ho sakta hai. Kripya turant gynecologist se sampark karein ya niche diye gaye number par call karein.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withAlpha(220),
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 500.ms);
  }

  Widget _buildEmergencyCallSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            '🚨 Emergency Assistance Call (24/7)',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:108');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone),
                  label: Text('Call Ambulance (108)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:102');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.local_hospital),
                  label: Text('Helpline (102)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSheet() {
    final hasHighRisk = _hasHighRiskSelected;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: MaaColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MaaColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potential Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your selected symptoms, here are the most likely possibilities. Please consult a doctor for official diagnosis.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: MaaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hasHighRisk) _buildEmergencyAlertBox(),
                  if (_results.isEmpty)
                    _buildNoResults()
                  else
                    ..._results.map((r) => _buildResultCard(r)),
                  const SizedBox(height: 32),
                  if (hasHighRisk) ...[
                    _buildEmergencyCallSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildMedicalDisclaimer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.help_outline_rounded,
              size: 64, color: MaaColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'We couldn\'t find a strong match. Try adding more symptoms.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: MaaColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(DiagnosticResult result) {
    final conf = result.confidence;
    final color = conf > 70
        ? MaaColors.error
        : (conf > 40 ? MaaColors.warning : MaaColors.gold);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.disease.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(100)),
                ),
                child: Text(
                  '${conf.toInt()}% Match',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.disease.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Matched Symptoms:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MaaColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: result.matchedSymptoms
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: MaaColors.pink.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                            fontSize: 11, color: MaaColors.pink),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _buildPrecautionsSection(result.disease.precautions),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Ask AI',
                  Icons.chat_bubble_outline_rounded,
                  () {
                    Navigator.pop(context);
                    final prompt =
                        'I am showing symptoms: ${_selectedSymptoms.join(", ")}. '
                        'The checker suggested ${result.disease.name}. Can you explain more?';
                    Navigator.pushNamed(context, '/chat',
                        arguments: {'initialMessage': prompt});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Consult',
                  Icons.video_call_rounded,
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/gynecare_consultation');
                  },
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  Widget _buildPrecautionsSection(List<String> precautions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Next Steps:',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MaaColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        ...precautions.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•',
                      style: TextStyle(color: MaaColors.gold, fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: MaaColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap,
      {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? MaaColors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaaColors.pink),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isPrimary ? MaaColors.white : MaaColors.pink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? MaaColors.white : MaaColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.warning.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: MaaColors.warning),
          const SizedBox(height: 12),
          Text(
            'IMPORTANT DISCLAIMER',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MaaColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This symptom checker is for informational purposes only and is NOT a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. If you think you may have a medical emergency, call your doctor or emergency services immediately.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: MaaColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'GyneCare / Period Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectedSymptoms.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: MaaColors.pink),
              onPressed: () => setState(() {
                _selectedSymptoms.clear();
                _results = [];
              }),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildSymptomList(),
            ),
            if (_selectedSymptoms.isNotEmpty) _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling today?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MaaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select all symptoms that apply to you.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textSecondary,
            ),
          ),
          
          // WHO Menstrual Health & Hygiene Guidelines Info Card
          const SizedBox(height: 16),
          _buildWhoMenstrualHealthCard(),

          if (_selectedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedSymptoms.map((s) => _buildSelectedChip(s)).toList(),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          ],
        ],
      ),
    );
  }

  Widget _buildWhoMenstrualHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MaaColors.success.withAlpha(20),
            MaaColors.softPurple.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MaaColors.success.withAlpha(80),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MaaColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'WHO CLINICAL GUIDE',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.health_and_safety_rounded,
                color: MaaColors.success,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'WHO Menstrual Health & Hygiene Guidelines 🩺',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MaaColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Normal Cycle Length: 21–35 days\n'
            '• Normal Flow Duration: 2–7 days\n'
            '• Pain Threshold: Mild/moderate cramping is common; severe, debilitating pain that disrupts daily activities is abnormal and requires clinical assessment.\n'
            '• Consultation Criteria: Contact a doctor immediately if you experience cycles shorter than 21 days or longer than 35 days, severe pain, bleeding between periods, or extremely heavy bleeding (changing pads every 1-2 hours).',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: MaaColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(String symptom) {
    return Chip(
      label: Text(
        symptom,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: MaaColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: MaaColors.pink,
      deleteIcon: const Icon(Icons.close, size: 14, color: MaaColors.white),
      onDeleted: () => _toggleSymptom(symptom),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: MaaColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search symptoms...',
          hintStyle: const TextStyle(color: MaaColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: MaaColors.pink),
          filled: true,
          fillColor: MaaColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSymptomList() {
    final greenSymptoms = gyneCareSymptoms.where((s) => s['risk'] == 'low').toList();
    final yellowSymptoms = gyneCareSymptoms.where((s) => s['risk'] == 'medium').toList();
    final redSymptoms = gyneCareSymptoms.where((s) => s['risk'] == 'high').toList();

    final query = _searchController.text.toLowerCase();
    final filteredGreen = greenSymptoms.where((s) => s['name'].toString().toLowerCase().contains(query)).toList();
    final filteredYellow = yellowSymptoms.where((s) => s['name'].toString().toLowerCase().contains(query)).toList();
    final filteredRed = redSymptoms.where((s) => s['name'].toString().toLowerCase().contains(query)).toList();

    if (filteredGreen.isEmpty && filteredYellow.isEmpty && filteredRed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: MaaColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No symptoms found',
              style: GoogleFonts.poppins(color: MaaColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          if (filteredGreen.isNotEmpty) ...[
            _buildZoneSection(
              title: 'Period Comfort & Hygiene (GREEN ZONE)',
              color: MaaColors.success,
              symptoms: filteredGreen,
            ),
            const SizedBox(height: 16),
          ],
          if (filteredYellow.isNotEmpty) ...[
            _buildZoneSection(
              title: 'Gynaecological Consultation (YELLOW ZONE)',
              color: MaaColors.warning,
              symptoms: filteredYellow,
            ),
            const SizedBox(height: 16),
          ],
          if (filteredRed.isNotEmpty) ...[
            _buildZoneSection(
              title: 'Menstrual Emergency (CRITICAL RED ZONE)',
              color: Colors.redAccent,
              symptoms: filteredRed,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneSection({
    required String title,
    required Color color,
    required List<Map<String, dynamic>> symptoms,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(150),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: symptoms.length,
            itemBuilder: (context, index) {
              final symptom = symptoms[index];
              final name = symptom['name'] as String;
              final isSelected = _selectedSymptoms.contains(name);

              return Card(
                color: isSelected ? color.withAlpha(20) : MaaColors.cardDark.withAlpha(120),
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? color : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : MaaColors.textPrimary,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSymptom(name),
                    activeColor: color,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onTap: () => _toggleSymptom(name),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: MaaButton(
          label: 'Analyze Symptoms (${_selectedSymptoms.length})',
          onPressed: _runDiagnosis,
          icon: Icons.analytics_rounded,
        ),
      ),
    );
  }
}
