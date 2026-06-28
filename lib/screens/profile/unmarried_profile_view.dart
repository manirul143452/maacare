import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/menstrual_medical_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/menstrual_provider.dart';
import '../../services/maacare_backend_service.dart';

class UnmarriedProfileView extends StatefulWidget {
  const UnmarriedProfileView({super.key});

  @override
  State<UnmarriedProfileView> createState() => _UnmarriedProfileViewState();
}

class _UnmarriedProfileViewState extends State<UnmarriedProfileView> {
  List<Map<String, dynamic>> _bmiLogs = [];
  bool _loadingBmi = false;

  @override
  void initState() {
    super.initState();
    _loadBmiLogs();
  }

  Future<void> _loadBmiLogs() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    setState(() => _loadingBmi = true);
    try {
      final logs = await MaaCareBackendService.instance.fetchBmiLogs(user.id);
      if (mounted) {
        setState(() => _bmiLogs = logs);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingBmi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final menstrual = context.watch<MenstrualProvider>();
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: MenstrualMedicalTheme.electricOrchid));
    }

    // Calculations for Regularity
    final cycleLength = menstrual.averageCycleLength;
    int regularityScore = 95; // Default base regularity
    String regularityStatus = "Highly Regular";
    if (menstrual.isPeriodLate) {
      regularityScore = (95 - (menstrual.daysLate * 3)).clamp(60, 95);
      regularityStatus = menstrual.daysLate > 7 ? "Irregular (Late)" : "Slightly Delayed";
    }

    return Theme(
      data: MenstrualMedicalTheme.themeData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Neon Glassmorphic Header Card (NO maternal references)
            GlassmorphicCard(
              borderColor: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.3),
              backgroundColor: MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.6),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.2),
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: MenstrualMedicalTheme.electricOrchid)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user.email ?? 'No email set',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      user.isPremium ? 'MaaCare Elite' : 'Freemium Member',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MenstrualMedicalTheme.electricOrchid,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // 2. Menstrual Regularity Score Card
            GlassmorphicCard(
              borderRadius: 20.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menstrual Regularity Score',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.analytics_outlined, color: MenstrualMedicalTheme.electricOrchid),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Circular indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 70,
                            width: 70,
                            child: CircularProgressIndicator(
                              value: regularityScore / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              color: MenstrualMedicalTheme.electricOrchid,
                            ),
                          ),
                          Text(
                            '$regularityScore%',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              regularityStatus,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: MenstrualMedicalTheme.electricOrchid,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cycle Consistency is based on average length of $cycleLength days.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 450.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // 3. Cumulative Symptom Logs Card
            GlassmorphicCard(
              borderRadius: 20.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cumulative Symptom Logs',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.favorite_border, color: MenstrualMedicalTheme.electricOrchid),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (menstrual.loggedSymptoms.isEmpty)
                    Text(
                      'No symptoms logged recently. Track your daily symptoms on the dashboard to get analytics here!',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: menstrual.loggedSymptoms.map((sym) {
                        final formattedSym = sym
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '')
                            .join(' ');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            formattedSym,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // 4. Historical BMI Trend Chart Card
            GlassmorphicCard(
              borderRadius: 20.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BMI Trend Charts',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.show_chart, color: MenstrualMedicalTheme.electricOrchid),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingBmi)
                    const Center(child: CircularProgressIndicator(color: MenstrualMedicalTheme.electricOrchid))
                  else if (_bmiLogs.isEmpty)
                    Text(
                      'No BMI logs found. Update height & weight in your profile editing screen to visualize trends here!',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    // Mini graph trend container
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: BmiTrendPainter(_bmiLogs),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // List of logs
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bmiLogs.length > 3 ? 3 : _bmiLogs.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final log = _bmiLogs[index];
                        final score = double.tryParse(log['bmi_score'].toString()) ?? 0.0;
                        final status = log['weight_status'] ?? 'Unknown';
                        final dateStr = log['recorded_at'] != null
                            ? DateFormat('MMM d, yyyy').format(DateTime.parse(log['recorded_at']))
                            : 'Recent';

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BMI: ${score.toStringAsFixed(1)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(status)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ).animate().fade(duration: 550.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MenstrualMedicalTheme.electricOrchid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MenstrualMedicalTheme.electricOrchid,
                      side: const BorderSide(color: MenstrualMedicalTheme.electricOrchid),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'underweight':
        return Colors.blueAccent;
      case 'normal':
        return Colors.greenAccent;
      case 'overweight':
        return Colors.orangeAccent;
      case 'obese':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

class BmiTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> logs;

  BmiTrendPainter(this.logs);

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.length < 2) {
      final paint = Paint()
        ..color = MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.3)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      return;
    }

    final paint = Paint()
      ..color = MenstrualMedicalTheme.electricOrchid
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    
    final reversedLogs = logs.reversed.toList();
    final double stepX = size.width / (reversedLogs.length - 1);
    
    double minBmi = 999.0;
    double maxBmi = -999.0;
    for (var log in reversedLogs) {
      final val = double.tryParse(log['bmi_score'].toString()) ?? 22.0;
      if (val < minBmi) minBmi = val;
      if (val > maxBmi) maxBmi = val;
    }

    minBmi -= 1.0;
    maxBmi += 1.0;
    if (maxBmi == minBmi) {
      maxBmi += 2.0;
      minBmi -= 2.0;
    }

    final double range = maxBmi - minBmi;

    List<Offset> points = [];
    for (int i = 0; i < reversedLogs.length; i++) {
      final val = double.tryParse(reversedLogs[i]['bmi_score'].toString()) ?? 22.0;
      final x = i * stepX;
      final y = size.height - ((val - minBmi) / range * size.height);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control1 = Offset(prev.dx + (current.dx - prev.dx) / 2, prev.dy);
      final control2 = Offset(prev.dx + (current.dx - prev.dx) / 2, current.dy);
      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, current.dx, current.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    for (var point in points) {
      canvas.drawCircle(point, 5, Paint()..color = MenstrualMedicalTheme.electricOrchid);
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
