// ============================================================
//  ChildGrowthScreen – MaaCare Premium Baby Tracker
//  Beautiful dark themed analytics and milestone tracker
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_helper.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChildGrowthScreen extends StatefulWidget {
  const ChildGrowthScreen({super.key});

  @override
  State<ChildGrowthScreen> createState() => _ChildGrowthScreenState();
}

class _ChildGrowthScreenState extends State<ChildGrowthScreen> with SingleTickerProviderStateMixin {
  // Baby Profile State
  String _babyName = "";
  DateTime? _babyBirthDate;
  String _babyGender = "Boy"; // Boy / Girl
  bool _profileCreated = false;

  // Growth logs
  List<Map<String, dynamic>> _weightLogs = [];
  List<Map<String, dynamic>> _heightLogs = [];

  // Completed Milestones (list of milestone IDs)
  List<String> _completedMilestones = [];

  bool _isLoading = true;
  late ConfettiController _confettiController;
  late TabController _tabController;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  // Milestones list
  final List<Map<String, dynamic>> _milestones = [
    // 0-2 Months
    {'id': 'm1', 'ageGroup': '0-2 Months', 'title': 'Social Smile (Muskurana)', 'description': 'Smiles in response to your voice or smile.', 'emoji': '😊', 'points': 15},
    {'id': 'm2', 'ageGroup': '0-2 Months', 'title': 'Lift Head (Sir Uthana)', 'description': 'Lifts head briefly when lying on tummy.', 'emoji': '👶', 'points': 15},
    {'id': 'm3', 'ageGroup': '0-2 Months', 'title': 'Track Objects', 'description': 'Tracks moving objects with eyes.', 'emoji': '👀', 'points': 15},
    
    // 3-4 Months
    {'id': 'm4', 'ageGroup': '3-4 Months', 'title': 'Cooing & Babbling', 'description': 'Makes cooing, gurgling sounds.', 'emoji': '🗣️', 'points': 15},
    {'id': 'm5', 'ageGroup': '3-4 Months', 'title': 'Grab Toys', 'description': 'Reaches out and grabs hanging toys.', 'emoji': '🧸', 'points': 15},
    {'id': 'm6', 'ageGroup': '3-4 Months', 'title': 'Roll Over (Palatna)', 'description': 'Rolls from tummy to back.', 'emoji': '🔄', 'points': 15},
    
    // 5-6 Months
    {'id': 'm7', 'ageGroup': '5-6 Months', 'title': 'Sit with Support', 'description': 'Sits upright with cushions or help.', 'emoji': '🧘', 'points': 15},
    {'id': 'm8', 'ageGroup': '5-6 Months', 'title': 'Pass Objects', 'description': 'Passes a toy from one hand to the other.', 'emoji': '✋', 'points': 15},
    {'id': 'm9', 'ageGroup': '5-6 Months', 'title': 'Recognize Faces', 'description': 'Recognizes familiar faces and places.', 'emoji': '💖', 'points': 15},
    
    // 7-9 Months
    {'id': 'm10', 'ageGroup': '7-9 Months', 'title': 'Sit Alone', 'description': 'Sits steadily without any support.', 'emoji': '🌟', 'points': 15},
    {'id': 'm11', 'ageGroup': '7-9 Months', 'title': 'Crawl (Ghutno chalna)', 'description': 'Starts crawling or scooting around.', 'emoji': '🚼', 'points': 15},
    {'id': 'm12', 'ageGroup': '7-9 Months', 'title': 'Babble Words', 'description': 'Says repetitive sounds like ba-ba, ma-ma.', 'emoji': '🗣️', 'points': 15},
    
    // 10-12 Months
    {'id': 'm13', 'ageGroup': '10-12 Months', 'title': 'Stand with Support', 'description': 'Pulls up to stand holding furniture.', 'emoji': '🪑', 'points': 15},
    {'id': 'm14', 'ageGroup': '10-12 Months', 'title': 'Pincer Grasp', 'description': 'Picks up small food items with thumb & finger.', 'emoji': '👌', 'points': 15},
    {'id': 'm15', 'ageGroup': '10-12 Months', 'title': 'First Steps (Pehla Kadam)', 'description': 'Takes a few steps independently.', 'emoji': '👣', 'points': 25},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _tabController = TabController(length: 3, vsync: this);
    _loadState();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final userId = AuthService.instance.getCurrentUserId();
    final prefs = await SharedPreferences.getInstance();

    // Try loading from InsForge DB first
    if (userId != null) {
      try {
        final dbProfile = await MaaCareBackendService.instance.fetchChildProfile(userId);
        if (dbProfile != null) {
          setState(() {
            _babyName = (dbProfile['name'] as String?) ?? '';
            final dobStr = dbProfile['date_of_birth'] as String?;
            _babyBirthDate = dobStr != null ? DateTime.tryParse(dobStr) : null;
            _babyGender = () {
                final g = (dbProfile['gender'] as String? ?? 'boy');
                return g.isNotEmpty ? g[0].toUpperCase() + g.substring(1) : 'Boy';
              }();
            _profileCreated = _babyName.isNotEmpty && _babyBirthDate != null;

            // Load JSONB growth logs from DB
            final weightRaw = dbProfile['weight_logs'];
            _weightLogs = weightRaw != null
                ? List<Map<String, dynamic>>.from(weightRaw)
                : <Map<String, dynamic>>[];

            final heightRaw = dbProfile['height_logs'];
            _heightLogs = heightRaw != null
                ? List<Map<String, dynamic>>.from(heightRaw)
                : <Map<String, dynamic>>[];

            final milestonesRaw = dbProfile['completed_milestones'];
            _completedMilestones = milestonesRaw != null
                ? List<String>.from(milestonesRaw)
                : <String>[];

            // Seed demo data if logs are empty
            if (_weightLogs.isEmpty) {
              _weightLogs = [
                {'date': '2026-01-01', 'weight': 3.2},
                {'date': '2026-02-01', 'weight': 4.5},
                {'date': '2026-03-01', 'weight': 5.8},
              ];
            }
            if (_heightLogs.isEmpty) {
              _heightLogs = [
                {'date': '2026-01-01', 'height': 50.0},
                {'date': '2026-02-01', 'height': 54.0},
                {'date': '2026-03-01', 'height': 58.5},
              ];
            }
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('DB load failed, falling back to prefs: $e');
      }
    }

    // Fallback: SharedPreferences
    setState(() {
      _babyName = prefs.getString('baby_name') ?? '';
      final birthTimeStr = prefs.getString('baby_birthdate');
      _babyBirthDate = birthTimeStr != null ? DateTime.parse(birthTimeStr) : null;
      _babyGender = prefs.getString('baby_gender') ?? 'Boy';
      _profileCreated = _babyName.isNotEmpty && _babyBirthDate != null;

      final weightRaw = prefs.getString('baby_weight_logs');
      _weightLogs = weightRaw != null
          ? List<Map<String, dynamic>>.from(jsonDecode(weightRaw))
          : [
              {'date': '2026-01-01', 'weight': 3.2},
              {'date': '2026-02-01', 'weight': 4.5},
              {'date': '2026-03-01', 'weight': 5.8},
            ];

      final heightRaw = prefs.getString('baby_height_logs');
      _heightLogs = heightRaw != null
          ? List<Map<String, dynamic>>.from(jsonDecode(heightRaw))
          : [
              {'date': '2026-01-01', 'height': 50.0},
              {'date': '2026-02-01', 'height': 54.0},
              {'date': '2026-03-01', 'height': 58.5},
            ];

      _completedMilestones = prefs.getStringList('completed_milestones') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveBabyProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _babyBirthDate == null) {
      ErrorHelper.showError(context, "Please enter baby name & select birthdate");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baby_name', _nameCtrl.text.trim());
    await prefs.setString('baby_birthdate', _babyBirthDate!.toIso8601String());
    await prefs.setString('baby_gender', _babyGender);

    setState(() {
      _babyName = _nameCtrl.text.trim();
      _profileCreated = true;
    });

    if (mounted) {
      ErrorHelper.showSuccess(context, "Baby profile created! Welcome, $_babyName 💕");
    }
  }

  Future<void> _saveLogs() async {
    // 1. Save locally (fast, offline backup)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baby_weight_logs', jsonEncode(_weightLogs));
    await prefs.setString('baby_height_logs', jsonEncode(_heightLogs));
    await prefs.setStringList('completed_milestones', _completedMilestones);

    // 2. Persist to InsForge DB if user is logged in and profile exists
    if (_profileCreated && _babyBirthDate != null) {
      final userId = AuthService.instance.getCurrentUserId();
      if (userId != null) {
        try {
          await MaaCareBackendService.instance.upsertChildProfile(
            userId: userId,
            name: _babyName,
            dateOfBirth: _babyBirthDate!.toIso8601String().split('T').first,
            gender: _babyGender.toLowerCase(),
            weightLogs: _weightLogs,
            heightLogs: _heightLogs,
            completedMilestones: _completedMilestones,
          );
        } catch (e) {
          debugPrint('Child growth DB save error: $e');
        }
      }
    }
  }

  Future<void> _addWeightHeightLog(double? weight, double? height) async {
    final nowStr = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      if (weight != null) {
        _weightLogs.add({'date': nowStr, 'weight': weight});
        _weightLogs.sort((a, b) => a['date'].compareTo(b['date']));
      }
      if (height != null) {
        _heightLogs.add({'date': nowStr, 'height': height});
        _heightLogs.sort((a, b) => a['date'].compareTo(b['date']));
      }
    });
    await _saveLogs();
  }

  int _calculateAgeInMonths() {
    if (_babyBirthDate == null) return 0;
    final now = DateTime.now();
    int months = (now.year - _babyBirthDate!.year) * 12 + now.month - _babyBirthDate!.month;
    if (now.day < _babyBirthDate!.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  Future<void> _toggleMilestone(String id, int points) async {
    final userProvider = context.read<UserProvider>();
    setState(() {
      if (_completedMilestones.contains(id)) {
        _completedMilestones.remove(id);
      } else {
        _completedMilestones.add(id);
        _confettiController.play();
        userProvider.addPoints(points);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Milestone Achieved! +$points MaaPoints for $_babyName! 🌟'),
            backgroundColor: MaaColors.success,
          ),
        );
      }
    });
    // Also save milestones to DB
    await _saveLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).childGrowthTracker),
        bottom: _profileCreated
            ? TabBar(
                controller: _tabController,
                indicatorColor: MaaColors.pink,
                labelColor: MaaColors.pink,
                unselectedLabelColor: MaaColors.textMuted,
                tabs: const [
                  Tab(icon: Icon(Icons.show_chart_rounded), text: 'Growth'),
                  Tab(icon: Icon(Icons.checklist_rounded), text: 'Milestones'),
                  Tab(icon: Icon(Icons.cookie_outlined), text: 'Nutrition'),
                ],
              )
            : null,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: MaaColors.pink))
              : !_profileCreated
                  ? _buildProfileSetupView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGrowthTab(),
                        _buildMilestonesTab(),
                        _buildNutritionTab(),
                      ],
                    ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [MaaColors.pink, MaaColors.gold, MaaColors.softPurple],
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  // ── Baby Profile Setup ──
  Widget _buildProfileSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Let\'s build Baby\'s Nest 🏡',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: MaaColors.white),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Enter details to start tracking developmental milestones & weight/height charts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context).babysName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: MaaColors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'E.g., Aarav, Diya',
              ),
              style: const TextStyle(color: MaaColors.white),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).birthdate, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: MaaColors.white)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: MaaColors.pink,
                          surface: MaaColors.cardDark,
                          onSurface: MaaColors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _babyBirthDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaaColors.glassBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _babyBirthDate == null
                          ? AppLocalizations.of(context).selectDate
                          : '${_babyBirthDate!.day}/${_babyBirthDate!.month}/${_babyBirthDate!.year}',
                      style: TextStyle(
                        color: _babyBirthDate == null ? MaaColors.textMuted : MaaColors.white,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: MaaColors.pink, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).gender, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: MaaColors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text('👦 ${AppLocalizations.of(context).boy}')),
                    selected: _babyGender == 'Boy',
                    selectedColor: MaaColors.pink.withAlpha(80),
                    labelStyle: TextStyle(
                      color: _babyGender == 'Boy' ? MaaColors.pink : MaaColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: MaaColors.cardDark,
                    onSelected: (val) {
                      if (val) setState(() => _babyGender = 'Boy');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text('👧 ${AppLocalizations.of(context).girl}')),
                    selected: _babyGender == 'Girl',
                    selectedColor: MaaColors.pink.withAlpha(80),
                    labelStyle: TextStyle(
                      color: _babyGender == 'Girl' ? MaaColors.pink : MaaColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: MaaColors.cardDark,
                    onSelected: (val) {
                      if (val) setState(() => _babyGender = 'Girl');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveBabyProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: MaaColors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(AppLocalizations.of(context).startTracking, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Growth Tab ──
  Widget _buildGrowthTab() {
    final ageMonths = _calculateAgeInMonths();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baby Info Banner
          _buildBabyBanner(ageMonths),
          const SizedBox(height: 20),

          // Log Metrics Trigger
          _buildLogMetricsCard(),
          const SizedBox(height: 24),

          // Weight Progression Chart
          _buildChartSection(
            title: 'Weight Development (kg) ⚖️',
            chart: _buildWeightLineChart(),
            legendText: 'WHO Standard Range: 3.2 - 11.5 kg',
          ),
          const SizedBox(height: 24),

          // Height Progression Chart
          _buildChartSection(
            title: 'Height Development (cm) 📏',
            chart: _buildHeightLineChart(),
            legendText: 'WHO Standard Range: 50 - 78 cm',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBabyBanner(int ageMonths) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MaaColors.pink.withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Text(
              _babyGender == 'Boy' ? '👦' : '👧',
              style: const TextStyle(fontSize: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _babyName,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  '$ageMonths months old • $_babyGender',
                  style: GoogleFonts.poppins(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                _nameCtrl.text = _babyName;
                _profileCreated = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.pink.withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Baby Growth',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: MaaColors.white, fontSize: 15),
              ),
              Text(
                'Log weight & height regularly',
                style: GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _showAddLogDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget chart, required String legendText}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            legendText,
            style: GoogleFonts.poppins(color: MaaColors.pink, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }

  Widget _buildWeightLineChart() {
    if (_weightLogs.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noLogsYet, style: const TextStyle(color: MaaColors.textMuted)));
    }
    List<FlSpot> spots = [];
    for (int i = 0; i < _weightLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_weightLogs[i]['weight'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(color: MaaColors.glassBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) => Text('${val.toStringAsFixed(0)}kg', style: const TextStyle(color: MaaColors.textMuted, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < _weightLogs.length) {
                  final date = _weightLogs[index]['date'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(date.substring(5), style: const TextStyle(color: MaaColors.textMuted, fontSize: 9)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Baby Weight Line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: MaaColors.pink,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [MaaColors.pink.withAlpha(80), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightLineChart() {
    if (_heightLogs.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noLogsYet, style: const TextStyle(color: MaaColors.textMuted)));
    }
    List<FlSpot> spots = [];
    for (int i = 0; i < _heightLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_heightLogs[i]['height'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(color: MaaColors.glassBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) => Text('${val.toStringAsFixed(0)}cm', style: const TextStyle(color: MaaColors.textMuted, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < _heightLogs.length) {
                  final date = _heightLogs[index]['date'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(date.substring(5), style: const TextStyle(color: MaaColors.textMuted, fontSize: 9)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: MaaColors.softPurple,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [MaaColors.softPurple.withAlpha(80), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLogDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          decoration: const BoxDecoration(
            color: MaaColors.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: MaaColors.textMuted.withAlpha(100), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Baby Parameters 📈',
                style: GoogleFonts.poppins(color: MaaColors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).weightKg, style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'E.g., 6.4'),
                          style: const TextStyle(color: MaaColors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).heightCm, style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'E.g., 62.5'),
                          style: const TextStyle(color: MaaColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  final w = double.tryParse(_weightCtrl.text.trim());
                  final h = double.tryParse(_heightCtrl.text.trim());
                  if (w == null && h == null) {
                    ErrorHelper.showError(context, "Please enter at least one log parameter");
                    return;
                  }
                  _addWeightHeightLog(w, h);
                  _weightCtrl.clear();
                  _heightCtrl.clear();
                  Navigator.pop(context);
                  ErrorHelper.showSuccess(context, "Growth logged successfully!");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaaColors.pink,
                ),
                child: Text(AppLocalizations.of(context).addLogs, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Milestones Tab ──
  Widget _buildMilestonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developmental Milestones 🏆',
            style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Check off milestones completed by $_babyName to earn MaaPoints!',
            style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._buildMilestoneGroups(),
        ],
      ),
    );
  }

  List<Widget> _buildMilestoneGroups() {
    final ageInMonths = _calculateAgeInMonths();

    // Age-group ranges to display (show current + all past groups)
    bool groupInRange(String ageGroup) {
      switch (ageGroup) {
        case '0-2 Months': return ageInMonths >= 0;
        case '3-4 Months': return ageInMonths >= 3;
        case '5-6 Months': return ageInMonths >= 5;
        case '7-9 Months': return ageInMonths >= 7;
        case '10-12 Months': return ageInMonths >= 10;
        default: return true;
      }
    }

    // Filter milestones to age-appropriate groups only
    final filteredMilestones = _babyBirthDate != null
        ? _milestones.where((m) => groupInRange(m['ageGroup'] as String)).toList()
        : _milestones; // Show all if no birth date

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final m in filteredMilestones) {
      final group = m['ageGroup'] as String;
      grouped.putIfAbsent(group, () => []).add(m);
    }

    return grouped.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              entry.key,
              style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          ...entry.value.map((m) {
            final completed = _completedMilestones.contains(m['id']);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: completed ? MaaColors.success.withAlpha(20) : MaaColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed ? MaaColors.success.withAlpha(60) : MaaColors.glassBorder,
                  width: completed ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: completed,
                    activeColor: MaaColors.success,
                    checkColor: Colors.white,
                    onChanged: (val) {
                      _toggleMilestone(m['id'] as String, m['points'] as int);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(m['emoji'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: GoogleFonts.poppins(
                            color: completed ? MaaColors.success : MaaColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          m['description'] as String,
                          style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MaaColors.gold.withAlpha(completed ? 50 : 20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${m['points']}',
                      style: GoogleFonts.poppins(color: MaaColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }).toList();
  }

  // ── Weaning Nutrition Tab ──
  Widget _buildNutritionTab() {
    final weaningMeals = [
      {
        'title': 'Ragi Apple Porridge (6-7 Months) 🍎',
        'ingredients': 'Ragi flour, half apple, 1 tsp ghee, water.',
        'method': 'Peel and puree apple. Cook ragi flour in water on low flame for 5-8 mins until thick, mix apple puree & ghee. No salt/sugar.'
      },
      {
        'title': 'Moong Dal Khichdi (8+ Months) 🍚',
        'ingredients': 'Rice (2 tbsp), Moong dal (1 tbsp), pinch of turmeric, ghee.',
        'method': 'Wash and pressure cook rice/dal with 1 cup of water and turmeric until soft. Mash well with ghee before serving.'
      },
      {
        'title': 'Teething Carrot Stick (Home Remedy) 🥕',
        'ingredients': '1 thick carrot stick.',
        'method': 'Peel and clean carrot. Keep it in the refrigerator for 20 mins to cool down. Let baby chew under close supervision.'
      },
      {
        'title': 'Banana Mash (First Food - 6 Months) 🍌',
        'ingredients': '1 ripe Elaichi banana.',
        'method': 'Peel banana and mash with fork till super smooth. You can add a tablespoon of breast milk or formula to dilute.'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: weaningMeals.length + 1,
      itemBuilder: (context, idx) {
        if (idx == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indian Weaning Guide 🍱',
                  style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Nutritious Indian baby recipes and home remedies (Ghar ke Nuskhe) approved by pediatrician guidelines.',
                  style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final meal = weaningMeals[idx - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MaaColors.cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: MaaColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal['title']!,
                style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Ingredients: ', style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    TextSpan(text: meal['ingredients']!, style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Preparation: ', style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    TextSpan(text: meal['method']!, style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (idx * 100).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
