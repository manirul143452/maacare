// ============================================================
//  SymptomCheckerScreen – Offline Medical Diagnosis Support
//  Aesthetics: Premium, trust-inspiring, dark medical theme
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models/medical_models.dart';
import '../../services/medical_data_service.dart';
import '../../widgets/maa_button.dart';
import '../../widgets/loading_overlay.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final MedicalDataService _medicalService = MedicalDataService();
  final List<String> _selectedSymptoms = [];
  List<String> _allSymptoms = [];
  List<String> _filteredSymptoms = [];
  List<DiagnosticResult> _results = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _medicalService.init();
    setState(() {
      _allSymptoms = _medicalService.getAllSymptoms();
      _filteredSymptoms = _allSymptoms;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredSymptoms = _allSymptoms
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
      _results = []; // Clear results if selection changes
    });
  }

  void _runDiagnosis() {
    if (_selectedSymptoms.isEmpty) return;

    setState(() {
      _results = _medicalService.diagnose(_selectedSymptoms);
    });

    if (_results.isNotEmpty) {
      _showResultsModal();
    }
  }

  void _showResultsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultsSheet(),
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
          'Symptom Checker',
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
    if (_filteredSymptoms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: MaaColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No symptoms found',
              style: GoogleFonts.poppins(color: MaaColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _filteredSymptoms.length,
      itemBuilder: (context, index) {
        final symptom = _filteredSymptoms[index];
        final isSelected = _selectedSymptoms.contains(symptom);

        return Card(
          color: isSelected ? MaaColors.pink.withAlpha(20) : MaaColors.cardDark,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? MaaColors.pink : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            title: Text(
              symptom,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? MaaColors.white : MaaColors.textPrimary,
              ),
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSymptom(symptom),
              activeColor: MaaColors.pink,
              checkColor: MaaColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            onTap: () => _toggleSymptom(symptom),
          ),
        );
      },
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

  Widget _buildResultsSheet() {
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
                  if (_results.isEmpty)
                    _buildNoResults()
                  else
                    ..._results.map((r) => _buildResultCard(r)),
                  const SizedBox(height: 32),
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
                  () => Navigator.pushNamed(context, '/consult'),
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
}
