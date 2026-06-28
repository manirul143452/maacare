// ============================================================
//  HealthInsightsScreen – MaaCare Premium Health Hub
//  Aesthetics: Sleek glassmorphic dark dashboard with charts
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_helper.dart';
import '../../services/maacare_backend_service.dart';
import '../../models/symptom_vaccination_model.dart';
import 'package:intl/intl.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  // Hydration state
  int _waterGlasses = 0;
  final int _waterGoal = 8;
  final List<int> _hydrationHistory = [4, 6, 8, 5, 7, 8, 0]; // past 7 days (including today at index 6)

  // Symptom checker history (mock/shared_prefs)
  List<Map<String, dynamic>> _symptomLogs = [
    {'date': 'Mon', 'count': 2},
    {'date': 'Tue', 'count': 0},
    {'date': 'Wed', 'count': 3},
    {'date': 'Thu', 'count': 1},
    {'date': 'Fri', 'count': 4},
    {'date': 'Sat', 'count': 2},
    {'date': 'Sun', 'count': 1},
  ];

  // Mood history (score 1-5)
  List<double> _moodHistory = [4.0, 5.0, 3.0, 4.0, 2.0, 5.0, 4.0]; // past 7 days

  // Task completion
  double _taskCompletionRate = 0.6; // 60%

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final user = context.read<UserProvider>().user;
    final prefs = await SharedPreferences.getInstance();
    
    // Load water intake for today
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    List<SymptomCheckModel> symptomRecords = [];
    if (user != null) {
      try {
        symptomRecords = await MaaCareBackendService.instance.fetchSymptomChecks(user.id);
      } catch (e) {
        debugPrint('Failed to fetch symptom checks from database: $e');
      }
    }

    setState(() {
      _waterGlasses = prefs.getInt('water_$todayStr') ?? 0;
      _hydrationHistory[6] = _waterGlasses;
      
      // Calculate symptoms count per day from DB if available, fallback to SharedPreferences, then to mock
      if (symptomRecords.isNotEmpty) {
        final today = DateTime.now();
        final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
        final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        final Map<String, int> countsByDateStr = {};
        for (var day in days) {
          countsByDateStr[formatter.format(day)] = 0;
        }

        for (var record in symptomRecords) {
          final recordDateStr = formatter.format(record.createdAt);
          if (countsByDateStr.containsKey(recordDateStr)) {
            countsByDateStr[recordDateStr] = (countsByDateStr[recordDateStr] ?? 0) + record.symptoms.length;
          }
        }

        _symptomLogs = days.map((day) {
          final dateStr = formatter.format(day);
          final label = weekdayNames[day.weekday - 1];
          return {
            'date': label,
            'count': countsByDateStr[dateStr] ?? 0,
          };
        }).toList();
      } else {
        final symptomRaw = prefs.getString('insights_symptom_logs');
        if (symptomRaw != null) {
          try {
            _symptomLogs = List<Map<String, dynamic>>.from(jsonDecode(symptomRaw));
          } catch (e) {
            debugPrint('Failed to parse symptom logs: $e');
          }
        }
      }

      final moodRaw = prefs.getString('insights_mood_logs');
      if (moodRaw != null) {
        try {
          final decoded = jsonDecode(moodRaw);
          if (decoded is List) {
            _moodHistory = decoded.map((e) => (e as num).toDouble()).toList();
          }
        } catch (e) {
          debugPrint('Error parsing mood log: $e');
        }
      }

      _taskCompletionRate = prefs.getDouble('insights_task_rate') ?? 0.65;
      _isLoading = false;
    });
  }

  Future<void> _incrementWater() async {
    if (_waterGlasses >= 16) return; // Cap at 16 glasses
    final userProvider = context.read<UserProvider>();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _waterGlasses++;
      _hydrationHistory[6] = _waterGlasses;
    });
    
    await prefs.setInt('water_$todayStr', _waterGlasses);
    
    // Add points for matching target
    if (_waterGlasses == _waterGoal) {
      await userProvider.addPoints(10);
      if (mounted) {
        ErrorHelper.showSuccess(context, "💧 Water Goal Met! +10 MaaPoints 🌟");
      }
    }
  }

  Future<void> _decrementWater() async {
    if (_waterGlasses <= 0) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _waterGlasses--;
      _hydrationHistory[6] = _waterGlasses;
    });
    
    await prefs.setInt('water_$todayStr', _waterGlasses);
  }

  String _getAIPrediction() {
    final user = context.watch<UserProvider>().user;
    final mood = user?.mood ?? 'Grateful';
    final week = user?.pregnancyWeek ?? 12;

    if (mood == 'Sad' || mood == 'Anxious') {
      return "I feel you, Mama. Your hormones are peaking at Week $week. Try a 5-minute prenatal meditation in the 'Self Care' tab. Don't worry, you are doing great! 💕";
    } else if (mood == 'Tired') {
      return "Fatigue is common around Week $week. Make sure you hit your daily hydration goal of 8 glasses and rest when needed. Take it easy today, Mama. 😴";
    } else {
      return "Your mood stability looks wonderful this week, Mama! Your baby is thriving. Keep logging your symptoms and drinking water! 🌟";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: const Text('MaaCare Insights 📊'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MaaColors.pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI recommendation card
                  _buildAiInsightCard(),
                  const SizedBox(height: 20),

                  // Hydration tracker widget
                  _buildHydrationWidget(),
                  const SizedBox(height: 20),

                  // Mood line chart
                  _buildMoodChartCard(),
                  const SizedBox(height: 20),

                  // Symptom history bar chart
                  _buildSymptomChartCard(),
                  const SizedBox(height: 20),

                  // Activity and task progress circle
                  _buildProgressOverview(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── AI Insights ──
  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MaaColors.pink.withAlpha(40), MaaColors.softPurple.withAlpha(25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.pink.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Text('🧠', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Consultant',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _getAIPrediction(),
                  style: GoogleFonts.poppins(color: MaaColors.white.withAlpha(220), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack);
  }

  // ── Hydration Log ──
  Widget _buildHydrationWidget() {
    final percent = (_waterGlasses / _waterGoal).clamp(0.0, 1.0);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hydration Tracker 💧',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Daily Goal: 8 Glasses (2 Liters)',
                    style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MaaColors.pink.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_waterGlasses / $_waterGoal',
                  style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Liquid meter
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MaaColors.cardLight,
                      border: Border.all(color: MaaColors.glassBorder, width: 2),
                    ),
                  ),
                  ClipOval(
                    child: AnimatedContainer(
                      duration: 500.ms,
                      width: 70,
                      height: 70,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 70 * percent,
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade300, Colors.blue.shade600],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text('💧', style: TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWaterBtn(Icons.remove, _decrementWater),
                        _buildWaterBtn(Icons.add, _incrementWater),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Match your hydration goals to support baby\'s amniotic fluid levels.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildWaterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: MaaColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MaaColors.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Mood Chart Card ──
  Widget _buildMoodChartCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Stability Trend 🌤',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Weekly mood fluctuation chart (higher is happier)',
            style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 1: return const Text('😔', style: TextStyle(fontSize: 10));
                          case 3: return const Text('😐', style: TextStyle(fontSize: 10));
                          case 5: return const Text('😊', style: TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        int index = val.toInt();
                        if (index >= 0 && index < days.length) {
                          return Text(days[index], style: const TextStyle(color: MaaColors.textMuted, fontSize: 10));
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
                    spots: _moodHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: MaaColors.gold,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [MaaColors.gold.withAlpha(50), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Symptom Chart Card ──
  Widget _buildSymptomChartCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptom Frequency Analysis 🩺',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Number of symptoms logged per day',
            style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: const TextStyle(color: MaaColors.textMuted, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int index = val.toInt();
                        if (index >= 0 && index < _symptomLogs.length) {
                          return Text(_symptomLogs[index]['date'] as String, style: const TextStyle(color: MaaColors.textMuted, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _symptomLogs.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['count'] as num).toDouble(),
                        color: MaaColors.pink,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 5,
                          color: MaaColors.cardLight,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Progress overview ──
  Widget _buildProgressOverview() {
    return GlassContainer(
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: _taskCompletionRate,
                  strokeWidth: 6,
                  backgroundColor: MaaColors.cardLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(MaaColors.success),
                ),
              ),
              Text(
                '${(_taskCompletionRate * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Self Care Checklist',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Great job! You\'ve completed most of your daily tasks today, Mama. Consistency is key.',
                  style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
